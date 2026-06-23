from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.habits import HabitCreate, HabitLogCreate, HabitLogResponse, HabitResponse, TodayHabitStatus
from app.services.habit_service import HabitService

router = APIRouter(prefix="/habits", tags=["habits"])


@router.post("", response_model=HabitResponse, status_code=status.HTTP_201_CREATED)
async def create_habit(
    payload: HabitCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await HabitService(db).create_habit(current_user.id, payload)


@router.get("", response_model=list[HabitResponse])
async def list_habits(
    active_only: bool = True,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await HabitService(db).get_habits(current_user.id, active_only=active_only)


@router.get("/today", response_model=list[TodayHabitStatus])
async def today_habits(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await HabitService(db).get_today_habits(current_user.id)


@router.post("/{habit_id}/logs", response_model=HabitLogResponse, status_code=status.HTTP_201_CREATED)
async def log_habit(
    habit_id: str,
    payload: HabitLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await HabitService(db).log_habit(current_user.id, habit_id, payload)
