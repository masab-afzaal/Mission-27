from datetime import date, datetime
from pydantic import BaseModel, Field


class ObstacleCreate(BaseModel):
    blocker_type: str = Field(..., min_length=1, max_length=100)
    affected_domain: str | None = Field(None, max_length=100)
    description: str | None = None
    severity: int = Field(3, ge=1, le=5)


class ObstacleResolve(BaseModel):
    resolution: str = Field(..., min_length=1)


class ObstacleResponse(BaseModel):
    id: str
    user_id: str
    log_date: date
    blocker_type: str
    affected_domain: str | None
    description: str | None
    resolution: str | None
    severity: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
