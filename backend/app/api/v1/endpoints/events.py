from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.events import DayEvent
from app.models.user import User
from app.repositories.user_repository import UserRepository

router = APIRouter(prefix="/events", tags=["events"])


class DayEventCreate(BaseModel):
    event_type: str  # 'positive' | 'negative'
    category: str = Field(max_length=50)
    description: str = Field(max_length=300)
    points: int = Field(ge=1, le=50)


class DayEventResponse(BaseModel):
    id: str
    event_date: date
    event_type: str
    category: str
    description: str
    points: int

    model_config = {"from_attributes": True}


class TodayEventsResponse(BaseModel):
    events: list[DayEventResponse]
    positive_total: int
    negative_total: int
    net_balance: int


class TrendPoint(BaseModel):
    date: date
    net: int


class EventsTrendResponse(BaseModel):
    days: list[TrendPoint]


@router.post("", response_model=DayEventResponse, status_code=201)
async def log_event(
    body: DayEventCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    signed_points = body.points if body.event_type == "positive" else -body.points

    event = DayEvent(
        user_id=uid,
        event_date=date.today(),
        event_type=body.event_type,
        category=body.category,
        description=body.description,
        points=signed_points,
    )
    db.add(event)

    if body.event_type == "positive":
        await UserRepository(db).add_xp(current_user, 5)

    await db.commit()
    await db.refresh(event)
    return DayEventResponse.model_validate(event)


@router.get("/today", response_model=TodayEventsResponse)
async def get_today_events(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    events = (await db.execute(
        select(DayEvent).where(
            DayEvent.user_id == str(current_user.id),
            DayEvent.event_date == date.today(),
        ).order_by(DayEvent.created_at.desc())
    )).scalars().all()

    pos = sum(e.points for e in events if e.points > 0)
    neg = sum(e.points for e in events if e.points < 0)
    return TodayEventsResponse(
        events=[DayEventResponse.model_validate(e) for e in events],
        positive_total=pos,
        negative_total=abs(neg),
        net_balance=pos + neg,
    )


@router.get("/trends", response_model=EventsTrendResponse)
async def get_events_trends(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
    period: int = 30,
):
    today = date.today()
    since = today - timedelta(days=period - 1)

    events = (await db.execute(
        select(DayEvent).where(
            DayEvent.user_id == str(current_user.id),
            DayEvent.event_date >= since,
        )
    )).scalars().all()

    by_date: dict = {}
    for e in events:
        by_date[e.event_date] = by_date.get(e.event_date, 0) + e.points

    days = [
        TrendPoint(date=since + timedelta(days=i), net=by_date.get(since + timedelta(days=i), 0))
        for i in range(period)
    ]
    return EventsTrendResponse(days=days)
