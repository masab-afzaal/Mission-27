from datetime import date
from typing import Annotated, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.analytics import DailySnapshot
from app.models.task import Task
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.services.achievement_service import AchievementService

router = APIRouter(prefix="/checkin", tags=["checkin"])


class MorningCheckInCreate(BaseModel):
    mood: int = Field(ge=1, le=5)
    energy: int = Field(ge=1, le=5)
    intentions: list[str] = Field(min_length=1, max_length=3)


class MorningCheckInResponse(BaseModel):
    snapshot_date: date
    morning_mood: int
    morning_energy: int
    morning_intentions: list[str]
    morning_checkin_done: bool
    xp_earned: int


@router.post("", response_model=MorningCheckInResponse)
async def morning_checkin(
    body: MorningCheckInCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    today = date.today()

    snapshot = (await db.execute(
        select(DailySnapshot).where(
            DailySnapshot.user_id == uid,
            DailySnapshot.snapshot_date == today,
        )
    )).scalar_one_or_none()

    if snapshot and snapshot.morning_checkin_done:
        return MorningCheckInResponse(
            snapshot_date=today,
            morning_mood=snapshot.morning_mood,
            morning_energy=snapshot.morning_energy,
            morning_intentions=snapshot.morning_intentions or [],
            morning_checkin_done=True,
            xp_earned=0,
        )

    xp = 15
    if not snapshot:
        snapshot = DailySnapshot(
            user_id=uid,
            snapshot_date=today,
            morning_checkin_done=True,
            morning_mood=body.mood,
            morning_energy=body.energy,
            morning_intentions=body.intentions,
        )
        db.add(snapshot)
    else:
        snapshot.morning_checkin_done = True
        snapshot.morning_mood = body.mood
        snapshot.morning_energy = body.energy
        snapshot.morning_intentions = body.intentions

    # Intentions become real tasks on today's list — one task system, no parallel lists.
    existing_titles = {
        t.title.strip().lower()
        for t in (await db.execute(
            select(Task).where(Task.user_id == uid, Task.deadline == today)
        )).scalars().all()
    }
    for intention in body.intentions:
        if intention.strip().lower() not in existing_titles:
            db.add(Task(
                user_id=uid,
                title=intention,
                deadline=today,
                is_completed=False,
                is_domino=False,
                estimated_minutes=0,
                actual_minutes=0,
                xp_reward=10,
            ))

    user_repo = UserRepository(db)
    await user_repo.add_xp(current_user, xp)
    await db.commit()

    await AchievementService(db).check_and_grant(uid, "morning_checkin")

    return MorningCheckInResponse(
        snapshot_date=today,
        morning_mood=body.mood,
        morning_energy=body.energy,
        morning_intentions=body.intentions,
        morning_checkin_done=True,
        xp_earned=xp,
    )


@router.get("", response_model=MorningCheckInResponse | None)
async def get_today_checkin(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    snapshot = (await db.execute(
        select(DailySnapshot).where(
            DailySnapshot.user_id == str(current_user.id),
            DailySnapshot.snapshot_date == today,
        )
    )).scalar_one_or_none()
    if not snapshot or not snapshot.morning_checkin_done:
        return None
    return MorningCheckInResponse(
        snapshot_date=today,
        morning_mood=snapshot.morning_mood,
        morning_energy=snapshot.morning_energy,
        morning_intentions=snapshot.morning_intentions or [],
        morning_checkin_done=True,
        xp_earned=0,
    )


class RetroLogCreate(BaseModel):
    day_target: Optional[str] = None
    achieved_summary: Optional[str] = None
    positives: Optional[str] = None
    negatives: Optional[str] = None
    tomorrow_plan: Optional[str] = None


class RetroLogResponse(BaseModel):
    snapshot_date: date
    day_target: Optional[str] = None
    achieved_summary: Optional[str] = None
    positives: Optional[str] = None
    negatives: Optional[str] = None
    tomorrow_plan: Optional[str] = None
    xp_earned: int


@router.post("/retro", response_model=RetroLogResponse)
async def submit_retro_log(
    body: RetroLogCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    today = date.today()

    snapshot = (await db.execute(
        select(DailySnapshot).where(
            DailySnapshot.user_id == uid,
            DailySnapshot.snapshot_date == today,
        )
    )).scalar_one_or_none()

    is_new = False
    if not snapshot:
        snapshot = DailySnapshot(
            user_id=uid,
            snapshot_date=today,
            day_target=body.day_target,
            achieved_summary=body.achieved_summary,
            positives=body.positives,
            negatives=body.negatives,
            tomorrow_plan=body.tomorrow_plan,
        )
        db.add(snapshot)
        is_new = True
    else:
        if not snapshot.achieved_summary and body.achieved_summary:
            is_new = True
        snapshot.day_target = body.day_target or snapshot.day_target
        snapshot.achieved_summary = body.achieved_summary or snapshot.achieved_summary
        snapshot.positives = body.positives or snapshot.positives
        snapshot.negatives = body.negatives or snapshot.negatives
        snapshot.tomorrow_plan = body.tomorrow_plan or snapshot.tomorrow_plan

    xp = 15 if is_new else 0
    if xp > 0:
        await UserRepository(db).add_xp(current_user, xp)

    await db.commit()
    await db.refresh(snapshot)

    return RetroLogResponse(
        snapshot_date=today,
        day_target=snapshot.day_target,
        achieved_summary=snapshot.achieved_summary,
        positives=snapshot.positives,
        negatives=snapshot.negatives,
        tomorrow_plan=snapshot.tomorrow_plan,
        xp_earned=xp,
    )


@router.get("/retro", response_model=RetroLogResponse | None)
async def get_today_retro(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    snapshot = (await db.execute(
        select(DailySnapshot).where(
            DailySnapshot.user_id == str(current_user.id),
            DailySnapshot.snapshot_date == today,
        )
    )).scalar_one_or_none()
    if not snapshot:
        return None
    return RetroLogResponse(
        snapshot_date=today,
        day_target=snapshot.day_target,
        achieved_summary=snapshot.achieved_summary,
        positives=snapshot.positives,
        negatives=snapshot.negatives,
        tomorrow_plan=snapshot.tomorrow_plan,
        xp_earned=0,
    )
