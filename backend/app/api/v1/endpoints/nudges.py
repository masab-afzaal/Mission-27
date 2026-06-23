from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.habit import Habit, HabitLog
from app.models.social import SocialInteraction
from app.models.ielts import IELTSProfile
from app.models.analytics import DailySnapshot
from app.models.user import User

router = APIRouter(prefix="/nudges", tags=["nudges"])


class NudgeResponse(BaseModel):
    id: str
    type: str          # warning | info | tip | celebration
    domain: str
    message: str
    action: str | None


@router.get("", response_model=list[NudgeResponse])
async def get_nudges(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    today = date.today()
    nudges: list[NudgeResponse] = []

    async def q(stmt):
        return (await db.execute(stmt)).scalar_one_or_none() or 0

    # ── Habit: uncompleted habits with high streak ──────────────────────
    active_habits = (await db.execute(
        select(Habit).where(Habit.user_id == uid, Habit.is_active.is_(True))
    )).scalars().all()

    for habit in active_habits:
        logged = await q(select(func.count(HabitLog.id)).where(
            HabitLog.habit_id == str(habit.id),
            HabitLog.logged_date == today,
            HabitLog.completed.is_(True),
        ))
        if not logged and habit.current_streak >= 7:
            nudges.append(NudgeResponse(
                id=f"streak_risk_{habit.id}",
                type="warning",
                domain="habits",
                message=f"Your \"{habit.name}\" streak ({habit.current_streak} days) is at risk — log it today.",
                action="log_habit",
            ))

    # ── Social: no interaction in 5+ days ──────────────────────────────
    last_social = await q(select(func.max(SocialInteraction.interaction_date)).where(
        SocialInteraction.user_id == uid))
    if last_social:
        days_silent = (today - last_social).days if hasattr(last_social, 'days') else 0
        if isinstance(last_social, date):
            days_silent = (today - last_social).days
            if days_silent >= 5:
                nudges.append(NudgeResponse(
                    id="social_gap",
                    type="warning",
                    domain="social",
                    message=f"No social interaction logged in {days_silent} days — isolation risk is climbing.",
                    action="log_social",
                ))

    # ── IELTS: exam is near but no recent study ─────────────────────────
    profile_row = (await db.execute(select(IELTSProfile).where(IELTSProfile.user_id == uid))).scalar_one_or_none()
    if profile_row and profile_row.exam_date:
        days_to_exam = (profile_row.exam_date - today).days
        if 0 < days_to_exam <= 30:
            from app.models.ielts import IELTSStudySession
            recent_sessions = await q(select(func.count(IELTSStudySession.id)).where(
                IELTSStudySession.user_id == uid,
                IELTSStudySession.session_date >= today - timedelta(days=7),
            ))
            if recent_sessions < 3:
                nudges.append(NudgeResponse(
                    id="ielts_exam_near",
                    type="warning",
                    domain="ielts",
                    message=f"IELTS exam in {days_to_exam} days — you've studied only {recent_sessions} sessions this week.",
                    action="log_ielts_session",
                ))

    # ── Morning check-in not done today ────────────────────────────────
    snapshot_today = (await db.execute(
        select(DailySnapshot).where(
            DailySnapshot.user_id == uid,
            DailySnapshot.snapshot_date == today,
        )
    )).scalar_one_or_none()
    if not snapshot_today or not snapshot_today.morning_checkin_done:
        nudges.append(NudgeResponse(
            id="morning_checkin",
            type="info",
            domain="ritual",
            message="Set your intentions for today — 60-second morning check-in.",
            action="open_checkin",
        ))

    return nudges[:5]  # cap at 5 nudges per session
