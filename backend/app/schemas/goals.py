from datetime import date
from typing import Optional
from pydantic import BaseModel, Field
from app.models.goal import GoalTimeframe, GoalStatus, GoalPriority


class MilestoneCreate(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    order_index: int = 0


class MilestoneResponse(BaseModel):
    id: str
    title: str
    is_completed: bool
    order_index: int
    completed_at: Optional[date] = None
    model_config = {"from_attributes": True}


class GoalCreate(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    description: Optional[str] = None
    domain: str = Field(min_length=1, max_length=100)
    timeframe: GoalTimeframe
    priority: GoalPriority = GoalPriority.MEDIUM
    target_date: Optional[date] = None
    success_criteria: Optional[str] = None
    xp_reward: int = Field(default=50, ge=0, le=5000)
    parent_goal_id: Optional[str] = None
    milestones: list[MilestoneCreate] = []


class GoalUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    status: Optional[GoalStatus] = None
    priority: Optional[GoalPriority] = None
    progress_percent: Optional[float] = Field(None, ge=0.0, le=100.0)
    target_date: Optional[date] = None
    success_criteria: Optional[str] = None


class GoalResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    domain: str
    timeframe: GoalTimeframe
    status: GoalStatus
    priority: GoalPriority
    progress_percent: float
    target_date: Optional[date] = None
    xp_reward: int
    success_criteria: Optional[str] = None
    completed_at: Optional[date] = None
    parent_goal_id: Optional[str] = None
    milestones: list[MilestoneResponse] = []
    model_config = {"from_attributes": True}
