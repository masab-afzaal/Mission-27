from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.health import WorkoutSession, WorkoutType, HealthMetric
from app.models.user import User
from app.repositories.user_repository import UserRepository

router = APIRouter(prefix="/health", tags=["health"])


class WorkoutCreate(BaseModel):
    workout_date: date
    workout_type: WorkoutType
    duration_minutes: int = Field(ge=5, le=480)
    intensity_level: int = Field(default=3, ge=1, le=5)
    notes: Optional[str] = None


class WorkoutResponse(BaseModel):
    id: str
    workout_date: date
    workout_type: WorkoutType
    duration_minutes: int
    intensity_level: int
    xp_earned: int
    model_config = {"from_attributes": True}


class HealthMetricCreate(BaseModel):
    metric_date: date
    weight_kg: Optional[float] = None
    sleep_hours: Optional[float] = None
    sleep_quality: Optional[int] = Field(None, ge=1, le=5)
    energy_level: Optional[int] = Field(None, ge=1, le=10)
    water_ml: Optional[int] = None
    mood_score: Optional[int] = Field(None, ge=1, le=10)
    stress_level: Optional[int] = Field(None, ge=1, le=10)


@router.post("/workouts", response_model=WorkoutResponse, status_code=status.HTTP_201_CREATED)
async def log_workout(
    payload: WorkoutCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    xp = max(10, (payload.duration_minutes // 30) * 20)
    workout = WorkoutSession(
        user_id=current_user.id,
        workout_date=payload.workout_date,
        workout_type=payload.workout_type,
        duration_minutes=payload.duration_minutes,
        intensity_level=payload.intensity_level,
        notes=payload.notes,
        xp_earned=xp,
    )
    db.add(workout)
    await db.flush()

    repo = UserRepository(db)
    user = await repo.get_by_id(current_user.id)
    if user:
        await repo.add_xp(user, xp)

    return WorkoutResponse.model_validate(workout)


@router.get("/workouts", response_model=list[WorkoutResponse])
async def list_workouts(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = (
        select(WorkoutSession)
        .where(WorkoutSession.user_id == current_user.id)
        .order_by(WorkoutSession.workout_date.desc())
        .limit(30)
    )
    workouts = (await db.execute(stmt)).scalars().all()
    return [WorkoutResponse.model_validate(w) for w in workouts]


@router.post("/metrics", status_code=status.HTTP_201_CREATED)
async def log_health_metric(
    payload: HealthMetricCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    metric = HealthMetric(user_id=current_user.id, **payload.model_dump())
    db.add(metric)
    await db.flush()
    return {"id": metric.id, "message": "Metric logged"}
