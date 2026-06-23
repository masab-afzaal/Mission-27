from datetime import date
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.task import Task
from app.models.goal import Goal, GoalStatus
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.tasks import TaskCreate, TaskUpdate, TaskResponse

router = APIRouter(prefix="/tasks", tags=["tasks"])


async def update_goal_progress(db: AsyncSession, goal_id: str, user_id: str) -> None:
    result = await db.execute(
        select(Task).where(Task.goal_id == goal_id)
    )
    tasks = result.scalars().all()
    if not tasks:
        progress = 0.0
    else:
        completed = sum(1 for t in tasks if t.is_completed)
        progress = (completed / len(tasks)) * 100.0

    goal_res = await db.execute(
        select(Goal).where(Goal.id == goal_id)
    )
    goal = goal_res.scalar_one_or_none()
    if goal:
        was_completed = (goal.status == GoalStatus.COMPLETED)
        goal.progress_percent = round(progress, 1)
        
        if progress >= 100.0:
            goal.status = GoalStatus.COMPLETED
            goal.completed_at = date.today()
            if not was_completed:
                user_res = await db.execute(
                    select(User).where(User.id == user_id)
                )
                user = user_res.scalar_one_or_none()
                if user:
                    await UserRepository(db).add_xp(user, goal.xp_reward)
        else:
            goal.status = GoalStatus.IN_PROGRESS
            goal.completed_at = None

        await db.commit()


@router.get("", response_model=list[TaskResponse])
async def list_tasks(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
    is_completed: Optional[bool] = None,
    goal_id: Optional[str] = None,
    today: Optional[bool] = None,
):
    query = select(Task).where(Task.user_id == str(current_user.id))
    
    if is_completed is not None:
        query = query.where(Task.is_completed == is_completed)
        
    if goal_id is not None:
        query = query.where(Task.goal_id == goal_id)
        
    if today:
        current_date = date.today()
        # Today's tasks are either due today or incomplete tasks from the past
        query = query.where(
            and_(
                Task.deadline <= current_date,
                Task.is_completed == False
            ) | (Task.deadline == current_date)
        )

    result = await db.execute(query.order_by(Task.deadline.asc(), Task.created_at.desc()))
    return result.scalars().all()


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    payload: TaskCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    
    # If goal_id is provided, verify it exists and belongs to the user
    if payload.goal_id:
        goal_res = await db.execute(
            select(Goal).where(Goal.id == payload.goal_id, Goal.user_id == uid)
        )
        if not goal_res.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")

    new_task = Task(
        user_id=uid,
        goal_id=payload.goal_id,
        title=payload.title,
        description=payload.description,
        deadline=payload.deadline or date.today(),
        is_completed=False,
        estimated_minutes=payload.estimated_minutes,
        actual_minutes=0,
        domain=payload.domain,
        xp_reward=10,
    )
    
    db.add(new_task)
    await db.commit()
    await db.refresh(new_task)
    
    if new_task.goal_id:
        await update_goal_progress(db, new_task.goal_id, uid)
        await db.refresh(new_task)

    return new_task


@router.patch("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: str,
    payload: TaskUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    
    task_res = await db.execute(
        select(Task).where(Task.id == task_id, Task.user_id == uid)
    )
    task = task_res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    old_goal_id = task.goal_id
    was_completed = task.is_completed

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, field, value)

    # Handlers for completions
    if payload.is_completed is not None:
        if payload.is_completed and not was_completed:
            task.completed_at = date.today()
            # Award XP for task completion
            await UserRepository(db).add_xp(current_user, task.xp_reward)
        elif not payload.is_completed and was_completed:
            task.completed_at = None
            # Deduct XP (or leave as is - let's just keep it simple and not deduct, or deduct)
            await UserRepository(db).add_xp(current_user, -task.xp_reward)

    await db.commit()
    await db.refresh(task)

    # Update goal progress if goal association changed or completion toggled
    if task.goal_id:
        await update_goal_progress(db, task.goal_id, uid)
    if old_goal_id and old_goal_id != task.goal_id:
        await update_goal_progress(db, old_goal_id, uid)
        
    await db.refresh(task)
    return task


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    
    task_res = await db.execute(
        select(Task).where(Task.id == task_id, Task.user_id == uid)
    )
    task = task_res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    goal_id = task.goal_id
    await db.delete(task)
    await db.commit()

    if goal_id:
        await update_goal_progress(db, goal_id, uid)
