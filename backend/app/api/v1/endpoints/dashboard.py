from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.analytics import DailySnapshot
from app.models.habit import Habit, HabitLog
from app.models.user import User
from app.schemas.dashboard import DashboardSummaryResponse, DailySnapshotResponse, ScoreBundleResponse
from app.services.score_engine import ScoreEngine

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/summary", response_model=DashboardSummaryResponse)
async def get_dashboard_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    engine = ScoreEngine(db, current_user.id)
    today_scores = await engine.compute()

    today = date.today()
    last_7_days_stmt = (
        select(DailySnapshot)
        .where(
            DailySnapshot.user_id == current_user.id,
            DailySnapshot.snapshot_date >= today - timedelta(days=6),
            DailySnapshot.snapshot_date <= today,
        )
        .order_by(DailySnapshot.snapshot_date)
    )
    snapshots_result = await db.execute(last_7_days_stmt)
    snapshots = snapshots_result.scalars().all()

    active_streaks = await _get_active_streaks(db, current_user.id)
    neglected = _identify_neglected_domains(today_scores)

    return DashboardSummaryResponse(
        today=ScoreBundleResponse(**today_scores.__dict__),
        last_7_days=[DailySnapshotResponse.model_validate(s) for s in snapshots],
        active_streaks=active_streaks,
        neglected_domains=neglected,
        user_level=current_user.level,
        user_xp=current_user.xp_total,
    )


@router.get("/scores", response_model=ScoreBundleResponse)
async def get_current_scores(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    engine = ScoreEngine(db, current_user.id)
    scores = await engine.compute()
    return ScoreBundleResponse(**scores.__dict__)


async def _get_active_streaks(db: AsyncSession, user_id: str) -> list[dict]:
    stmt = select(Habit).where(
        Habit.user_id == user_id,
        Habit.is_active.is_(True),
        Habit.current_streak > 0,
    ).order_by(Habit.current_streak.desc()).limit(5)
    habits = (await db.execute(stmt)).scalars().all()
    return [{"name": h.name, "streak": h.current_streak, "domain": h.domain} for h in habits]


class TrendPoint(BaseModel):
    date: date
    xp: int
    habits_done: int
    habits_total: int


class TrendsResponse(BaseModel):
    days: list[TrendPoint]


@router.get("/trends", response_model=TrendsResponse)
async def get_trends(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
    period: int = 30,
):
    today = date.today()
    since = today - timedelta(days=period - 1)

    snapshots = (await db.execute(
        select(DailySnapshot).where(
            DailySnapshot.user_id == str(current_user.id),
            DailySnapshot.snapshot_date >= since,
        )
    )).scalars().all()

    active_habits_count = (await db.execute(
        select(Habit).where(Habit.user_id == str(current_user.id), Habit.is_active.is_(True))
    )).scalars().all()
    total_habits = len(active_habits_count)

    habit_logs = (await db.execute(
        select(HabitLog).where(
            HabitLog.user_id == str(current_user.id),
            HabitLog.logged_date >= since,
            HabitLog.completed.is_(True),
        )
    )).scalars().all()

    xp_by_date = {s.snapshot_date: s.xp_earned_today for s in snapshots}
    habits_by_date: dict = {}
    for log in habit_logs:
        d = log.logged_date
        habits_by_date[d] = habits_by_date.get(d, 0) + 1

    days = []
    for i in range(period):
        d = since + timedelta(days=i)
        days.append(TrendPoint(
            date=d,
            xp=xp_by_date.get(d, 0),
            habits_done=habits_by_date.get(d, 0),
            habits_total=total_habits,
        ))

    return TrendsResponse(days=days)


def _identify_neglected_domains(scores) -> list[str]:
    neglected = []
    threshold = 30.0
    if scores.health_score < threshold:
        neglected.append("Health & Fitness")
    if scores.social_score < threshold:
        neglected.append("Social Life")
    if scores.learning_score < threshold:
        neglected.append("Learning")
    if scores.ielts_readiness < threshold:
        neglected.append("IELTS")
    if scores.ai_readiness < threshold:
        neglected.append("AI Engineering")
    return neglected
