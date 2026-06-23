from datetime import datetime
from pydantic import BaseModel, Field


class IdentityCreate(BaseModel):
    identity_name: str = Field(..., min_length=1, max_length=100)
    icon: str | None = Field(None, max_length=50)
    color_hex: str | None = Field(None, max_length=7)


class ActionLogRequest(BaseModel):
    count: int = Field(1, ge=1)


class IdentityResponse(BaseModel):
    id: str
    user_id: str
    identity_name: str
    strength_score: int
    total_actions: int
    icon: str | None
    color_hex: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
