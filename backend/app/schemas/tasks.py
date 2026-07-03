from datetime import date
from typing import Optional
from pydantic import BaseModel, Field

class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    description: Optional[str] = None
    deadline: Optional[date] = None
    estimated_minutes: int = Field(default=0, ge=0)
    goal_id: Optional[str] = None
    domain: Optional[str] = None
    is_domino: bool = False

class TaskUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    deadline: Optional[date] = None
    is_completed: Optional[bool] = None
    estimated_minutes: Optional[int] = Field(None, ge=0)
    actual_minutes: Optional[int] = Field(None, ge=0)
    goal_id: Optional[str] = None
    domain: Optional[str] = None
    is_domino: Optional[bool] = None

class TaskResponse(BaseModel):
    id: str
    user_id: str
    goal_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    deadline: Optional[date] = None
    is_completed: bool
    is_domino: bool
    completed_at: Optional[date] = None
    estimated_minutes: int
    actual_minutes: int
    domain: Optional[str] = None
    xp_reward: int

    model_config = {"from_attributes": True}
