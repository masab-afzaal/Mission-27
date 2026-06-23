from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.analytics import DailySnapshot
from app.models.user import User
from app.repositories.user_repository import UserRepository

router = APIRouter(prefix="/domino", tags=["domino"])


class DominoSetRequest(BaseModel):
    task: str = Field(max_length=300)


class DominoResponse(BaseModel):
    task: str | None
    done: bool
    xp_earned: int


async def _get_or_create_snapshot(db: AsyncSession, user_id: str) -> DailySnapshot:
    today = date.today()
    snap = (await db.execute(
        select(DailySnapshot).where(
            DailySnapshot.user_id == user_id,
            DailySnapshot.snapshot_date == today,
        )
    )).scalar_one_or_none()
    if not snap:
        snap = DailySnapshot(user_id=user_id, snapshot_date=today)
        db.add(snap)
        await db.commit()
        await db.refresh(snap)
    return snap


@router.get("", response_model=DominoResponse)
async def get_domino(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    snap = await _get_or_create_snapshot(db, str(current_user.id))
    return DominoResponse(task=snap.domino_task, done=snap.domino_done or False, xp_earned=0)


@router.post("/set", response_model=DominoResponse)
async def set_domino(
    body: DominoSetRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    snap = await _get_or_create_snapshot(db, str(current_user.id))
    snap.domino_task = body.task
    snap.domino_done = False
    await db.commit()
    return DominoResponse(task=snap.domino_task, done=False, xp_earned=0)


@router.post("/complete", response_model=DominoResponse)
async def complete_domino(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    snap = await _get_or_create_snapshot(db, str(current_user.id))
    xp = 0
    if snap.domino_task and not snap.domino_done:
        snap.domino_done = True
        xp = 25
        await UserRepository(db).add_xp(current_user, xp)
    await db.commit()
    return DominoResponse(task=snap.domino_task, done=True, xp_earned=xp)
