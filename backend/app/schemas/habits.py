from datetime import date
from typing import Optional
from pydantic import BaseModel, Field
from app.models.habit import HabitCategory, HabitFrequency


class HabitCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    description: Optional[str] = None
    category: HabitCategory
    domain: str = Field(min_length=1, max_length=100)
    frequency: HabitFrequency = HabitFrequency.DAILY
    target_count_per_period: int = Field(default=1, ge=1, le=10)
    xp_per_completion: int = Field(default=10, ge=1, le=100)


class HabitResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    category: HabitCategory
    domain: str
    frequency: HabitFrequency
    target_count_per_period: int
    current_streak: int
    longest_streak: int
    total_completions: int
    consistency_percent: float
    xp_per_completion: int
    is_active: bool
    model_config = {"from_attributes": True}


class HabitLogCreate(BaseModel):
    logged_date: date
    completed: bool = True
    note: Optional[str] = None


class HabitLogResponse(BaseModel):
    id: str
    habit_id: str
    logged_date: date
    completed: bool
    note: Optional[str] = None
    xp_earned: int
    model_config = {"from_attributes": True}


class TodayHabitStatus(BaseModel):
    habit: HabitResponse
    completed_today: bool
    log_id: Optional[str] = None
