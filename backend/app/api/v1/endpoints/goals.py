from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.goal import Goal, GoalSession, GoalStatus, GoalTimeframe
from app.models.habit import Habit
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.goals import GoalCreate, GoalResponse, GoalUpdate
from app.services.achievement_service import AchievementService
from app.services.goal_service import GoalService

router = APIRouter(prefix="/goals", tags=["goals"])


class GoalSessionCreate(BaseModel):
    duration_minutes: int = Field(ge=5, le=480)
    what_i_did: str = Field(min_length=3, max_length=1000)
    progress_made: float = Field(default=0.0, ge=0.0, le=100.0,
                                 description="Progress % to ADD to goal (0 = just logging effort, >0 = moved the needle)")
    notes: str | None = None


class GoalSessionResponse(BaseModel):
    id: str
    goal_id: str
    session_date: date
    duration_minutes: int
    what_i_did: str
    progress_made: float
    notes: str | None
    xp_earned: int

    model_config = {"from_attributes": True}


class GoalEvaluationResponse(BaseModel):
    goal_id: str
    title: str
    current_progress: float
    days_elapsed: int
    total_days: int | None
    expected_progress: float | None
    on_track: bool | None
    velocity_percent_per_day: float
    projected_completion_days: int | None
    total_sessions: int
    total_session_minutes: int
    contributing_habits: list[dict]


@router.post("", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
async def create_goal(
    payload: GoalCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    result = await GoalService(db).create_goal(str(current_user.id), payload)
    await AchievementService(db).check_and_grant(str(current_user.id), "goal_created")
    return result


@router.get("", response_model=list[GoalResponse])
async def list_goals(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
    timeframe: GoalTimeframe | None = None,
    goal_status: GoalStatus | None = None,
):
    return await GoalService(db).list_goals(str(current_user.id), timeframe=timeframe, status=goal_status)


@router.patch("/{goal_id}", response_model=GoalResponse)
async def update_goal(
    goal_id: str,
    payload: GoalUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    result = await GoalService(db).update_goal(str(current_user.id), goal_id, payload)
    if payload.status == GoalStatus.COMPLETED:
        await AchievementService(db).check_and_grant(str(current_user.id), "goal_completed")
    return result


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_goal(
    goal_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    await GoalService(db).delete_goal(str(current_user.id), goal_id)


@router.post("/{goal_id}/milestones/{milestone_id}/complete", response_model=GoalResponse)
async def complete_milestone(
    goal_id: str,
    milestone_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    return await GoalService(db).complete_milestone(str(current_user.id), goal_id, milestone_id)


# ── Goal Sessions (logging daily work) ────────────────────────────────────


@router.post("/{goal_id}/sessions", response_model=GoalSessionResponse, status_code=201)
async def log_goal_session(
    goal_id: str,
    body: GoalSessionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    """Log a work session on a specific goal. Use progress_made to advance the goal's progress %.
    Even if progress_made=0, logging effort still builds accountability and XP."""
    uid = str(current_user.id)
    goal = (await db.execute(select(Goal).where(Goal.id == goal_id, Goal.user_id == uid))).scalar_one_or_none()
    if not goal:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Goal not found")

    xp = max(10, body.duration_minutes // 5)
    session = GoalSession(
        goal_id=goal_id,
        user_id=uid,
        session_date=date.today(),
        duration_minutes=body.duration_minutes,
        what_i_did=body.what_i_did,
        progress_made=body.progress_made,
        notes=body.notes,
        xp_earned=xp,
    )
    db.add(session)

    # Update goal progress
    if body.progress_made > 0:
        new_progress = min(100.0, goal.progress_percent + body.progress_made)
        goal.progress_percent = round(new_progress, 1)
        if goal.status == GoalStatus.NOT_STARTED:
            goal.status = GoalStatus.IN_PROGRESS

    await db.flush()
    user_repo = UserRepository(db)
    await user_repo.add_xp(current_user, xp)
    await db.commit()
    await db.refresh(session)

    await AchievementService(db).check_and_grant(uid, "goal_session_logged")
    return GoalSessionResponse.model_validate(session)


@router.get("/{goal_id}/sessions", response_model=list[GoalSessionResponse])
async def list_goal_sessions(
    goal_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    rows = (await db.execute(
        select(GoalSession)
        .where(GoalSession.goal_id == goal_id, GoalSession.user_id == uid)
        .order_by(GoalSession.session_date.desc())
    )).scalars().all()
    return [GoalSessionResponse.model_validate(r) for r in rows]


@router.get("/{goal_id}/evaluate", response_model=GoalEvaluationResponse)
async def evaluate_goal(
    goal_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    """Evaluate whether this goal is on track. Shows velocity, projection, contributing habits."""
    uid = str(current_user.id)
    goal = (await db.execute(select(Goal).where(Goal.id == goal_id, Goal.user_id == uid))).scalar_one_or_none()
    if not goal:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Goal not found")

    today = date.today()
    created_date = goal.created_at.date() if hasattr(goal.created_at, 'date') else today

    days_elapsed = max(1, (today - created_date).days)
    total_days = None
    expected_progress = None
    on_track = None
    if goal.target_date:
        target = goal.target_date if isinstance(goal.target_date, date) else date.fromisoformat(str(goal.target_date))
        total_days = max(1, (target - created_date).days)
        expected_progress = round(min(100.0, (days_elapsed / total_days) * 100), 1)
        on_track = goal.progress_percent >= expected_progress

    # Velocity
    velocity = round(goal.progress_percent / days_elapsed, 3) if days_elapsed > 0 else 0.0
    projected_days = None
    if velocity > 0 and goal.progress_percent < 100:
        remaining = 100.0 - goal.progress_percent
        projected_days = int(remaining / velocity)

    # Sessions
    sessions_result = await db.execute(
        select(func.count(GoalSession.id), func.sum(GoalSession.duration_minutes))
        .where(GoalSession.goal_id == goal_id, GoalSession.user_id == uid)
    )
    session_count, session_mins = sessions_result.one()
    session_count = session_count or 0
    session_mins = int(session_mins or 0)

    # Contributing habits
    contributing = (await db.execute(
        select(Habit).where(Habit.user_id == uid, Habit.linked_goal_id == goal_id)
    )).scalars().all()
    habits_info = [{"id": h.id, "name": h.name, "current_streak": h.current_streak, "consistency_percent": h.consistency_percent} for h in contributing]

    return GoalEvaluationResponse(
        goal_id=goal_id,
        title=goal.title,
        current_progress=goal.progress_percent,
        days_elapsed=days_elapsed,
        total_days=total_days,
        expected_progress=expected_progress,
        on_track=on_track,
        velocity_percent_per_day=velocity,
        projected_completion_days=projected_days,
        total_sessions=session_count,
        total_session_minutes=session_mins,
        contributing_habits=habits_info,
    )
