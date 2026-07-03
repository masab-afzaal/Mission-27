from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.task import Task
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.api.v1.endpoints.tasks import (
    DOMINO_XP,
    clear_other_dominoes,
    sync_domino_snapshot,
    update_goal_progress,
)

# The domino is no longer its own entity — it is today's Task flagged is_domino.
# These endpoints are a thin facade kept for the dashboard widget's API shape.
router = APIRouter(prefix="/domino", tags=["domino"])


class DominoSetRequest(BaseModel):
    task: str = Field(max_length=300)


class DominoResponse(BaseModel):
    task: str | None
    task_id: str | None = None
    done: bool
    xp_earned: int


async def _get_today_domino(db: AsyncSession, user_id: str) -> Task | None:
    return (await db.execute(
        select(Task).where(
            Task.user_id == user_id,
            Task.is_domino == True,
            Task.deadline == date.today(),
        )
    )).scalars().first()


@router.get("", response_model=DominoResponse)
async def get_domino(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    task = await _get_today_domino(db, str(current_user.id))
    if not task:
        return DominoResponse(task=None, task_id=None, done=False, xp_earned=0)
    return DominoResponse(task=task.title, task_id=task.id, done=task.is_completed, xp_earned=0)


@router.post("/set", response_model=DominoResponse)
async def set_domino(
    body: DominoSetRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    task = await _get_today_domino(db, uid)

    if task and not task.is_completed:
        task.title = body.task
    else:
        task = Task(
            user_id=uid,
            title=body.task,
            deadline=date.today(),
            is_completed=False,
            is_domino=True,
            estimated_minutes=0,
            actual_minutes=0,
            xp_reward=DOMINO_XP,
        )
        db.add(task)

    await db.commit()
    await db.refresh(task)
    await clear_other_dominoes(db, uid, keep_task_id=task.id)
    await sync_domino_snapshot(db, uid)

    return DominoResponse(task=task.title, task_id=task.id, done=task.is_completed, xp_earned=0)


@router.post("/complete", response_model=DominoResponse)
async def complete_domino(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    task = await _get_today_domino(db, uid)
    if not task:
        return DominoResponse(task=None, task_id=None, done=False, xp_earned=0)

    xp = 0
    if not task.is_completed:
        task.is_completed = True
        task.completed_at = date.today()
        xp = task.xp_reward
        await UserRepository(db).add_xp(current_user, xp)
        await db.commit()
        await sync_domino_snapshot(db, uid)
        if task.goal_id:
            await update_goal_progress(db, task.goal_id, uid)

    return DominoResponse(task=task.title, task_id=task.id, done=True, xp_earned=xp)
