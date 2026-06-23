from datetime import date, datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, Query, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.pomodoro import PomodoroSession
from app.models.user import User
from app.models.task import Task
from app.repositories.user_repository import UserRepository
from app.services.achievement_service import AchievementService

router = APIRouter(prefix="/pomodoro", tags=["pomodoro"])


class PomodoroCreate(BaseModel):
    work_minutes: int = Field(default=25, ge=5, le=120)
    break_minutes: int = Field(default=5, ge=1, le=30)
    cycles_completed: int = Field(default=1, ge=1)
    task_description: str | None = Field(default=None, max_length=500)
    domain: str | None = Field(default=None, max_length=100)
    linked_goal_id: str | None = None
    task_id: str | None = None
    is_completed: bool = True


class PomodoroResponse(BaseModel):
    id: str
    session_date: date
    work_minutes: int
    break_minutes: int
    cycles_completed: int
    task_description: str | None
    domain: str | None
    linked_goal_id: str | None
    task_id: str | None
    is_completed: bool
    xp_earned: int

    model_config = {"from_attributes": True}


class PomodoroStatsResponse(BaseModel):
    today_sessions: int
    today_focus_minutes: int
    week_sessions: int
    week_focus_minutes: int
    total_sessions: int
    total_focus_minutes: int
    daily_streak: int


@router.post("", response_model=PomodoroResponse, status_code=201)
async def log_pomodoro(
    body: PomodoroCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    uid = str(current_user.id)
    
    # If task_id is provided, verify it exists and belongs to the user
    task = None
    if body.task_id:
        task_res = await db.execute(
            select(Task).where(Task.id == body.task_id, Task.user_id == uid)
        )
        task = task_res.scalar_one_or_none()
        if not task:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    # XP: 10 per cycle if completed, 5 if interrupted
    xp = (10 if body.is_completed else 5) * body.cycles_completed
    
    session = PomodoroSession(
        user_id=uid,
        session_date=today,
        started_at=datetime.now(timezone.utc),
        work_minutes=body.work_minutes,
        break_minutes=body.break_minutes,
        cycles_completed=body.cycles_completed,
        task_description=body.task_description,
        domain=body.domain,
        linked_goal_id=body.linked_goal_id,
        task_id=body.task_id,
        is_completed=body.is_completed,
        xp_earned=xp,
    )
    db.add(session)
    
    if task:
        task.actual_minutes += body.work_minutes * body.cycles_completed

    await db.flush()

    user_repo = UserRepository(db)
    await user_repo.add_xp(current_user, xp)
    await db.commit()
    await db.refresh(session)

    # Check achievements
    await AchievementService(db).check_and_grant(uid, "pomodoro_logged")

    return PomodoroResponse.model_validate(session)


@router.get("", response_model=list[PomodoroResponse])
async def list_pomodoros(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
    limit: int = Query(default=50, le=200),
    session_date: date | None = None,
):
    stmt = select(PomodoroSession).where(PomodoroSession.user_id == str(current_user.id))
    if session_date:
        stmt = stmt.where(PomodoroSession.session_date == session_date)
    stmt = stmt.order_by(PomodoroSession.created_at.desc()).limit(limit)
    rows = (await db.execute(stmt)).scalars().all()
    return [PomodoroResponse.model_validate(r) for r in rows]


@router.get("/stats", response_model=PomodoroStatsResponse)
async def pomodoro_stats(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    today = date.today()
    from datetime import timedelta
    week_start = today - timedelta(days=7)

    async def q(stmt):
        return (await db.execute(stmt)).scalar_one_or_none() or 0

    today_count = await q(select(func.count(PomodoroSession.id)).where(
        PomodoroSession.user_id == uid, PomodoroSession.session_date == today))
    today_mins = await q(select(func.sum(PomodoroSession.work_minutes * PomodoroSession.cycles_completed)).where(
        PomodoroSession.user_id == uid, PomodoroSession.session_date == today))
    week_count = await q(select(func.count(PomodoroSession.id)).where(
        PomodoroSession.user_id == uid, PomodoroSession.session_date >= week_start))
    week_mins = await q(select(func.sum(PomodoroSession.work_minutes * PomodoroSession.cycles_completed)).where(
        PomodoroSession.user_id == uid, PomodoroSession.session_date >= week_start))
    total_count = await q(select(func.count(PomodoroSession.id)).where(PomodoroSession.user_id == uid))
    total_mins = await q(select(func.sum(PomodoroSession.work_minutes * PomodoroSession.cycles_completed)).where(
        PomodoroSession.user_id == uid))

    # Simple streak: consecutive days with at least one session
    streak = 0
    check_date = today
    from datetime import timedelta as td
    for _ in range(365):
        cnt = await q(select(func.count(PomodoroSession.id)).where(
            PomodoroSession.user_id == uid, PomodoroSession.session_date == check_date))
        if cnt == 0:
            break
        streak += 1
        check_date -= td(days=1)

    return PomodoroStatsResponse(
        today_sessions=int(today_count),
        today_focus_minutes=int(today_mins),
        week_sessions=int(week_count),
        week_focus_minutes=int(week_mins),
        total_sessions=int(total_count),
        total_focus_minutes=int(total_mins),
        daily_streak=streak,
    )
