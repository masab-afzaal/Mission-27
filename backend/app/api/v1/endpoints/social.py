from datetime import datetime, timezone, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.social import SocialInteraction, InteractionType
from app.models.user import User

router = APIRouter(prefix="/social", tags=["social"])

# Maps Flutter UI types to model enum values
_TYPE_MAP: dict[str, InteractionType] = {
    "conversation": InteractionType.CASUAL_CHAT,
    "call": InteractionType.CASUAL_CHAT,
    "meetup": InteractionType.FRIEND_MEETUP,
    "message": InteractionType.ONLINE_COMMUNITY,
    "collaboration": InteractionType.COLLABORATION,
    "event": InteractionType.EVENT,
    "mentoring": InteractionType.MENTORING,
    "networking": InteractionType.PROFESSIONAL_NETWORKING,
    "family": InteractionType.FAMILY,
}


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class SocialInteractionCreate(BaseModel):
    interaction_type: str = "conversation"
    person_name: str | None = None
    notes: str | None = None
    quality_score: int = Field(default=7, ge=1, le=10)


class SocialInteractionResponse(BaseModel):
    id: str
    interaction_type: str
    person_name: str | None
    notes: str | None
    quality_score: int
    created_at: datetime


class SocialHealthResponse(BaseModel):
    social_score: float
    weekly_interactions: int
    average_quality: float
    isolation_risk: int
    meaningful_connections: int


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post("/interactions", status_code=201)
async def log_interaction(
    body: SocialInteractionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
) -> SocialInteractionResponse:
    mapped_type = _TYPE_MAP.get(body.interaction_type, InteractionType.CASUAL_CHAT)
    today = datetime.now(timezone.utc).date()

    interaction = SocialInteraction(
        user_id=str(current_user.id),
        interaction_date=today,
        interaction_type=mapped_type,
        person_name=body.person_name,
        notes=body.notes,
        quality_rating=body.quality_score,
        xp_earned=body.quality_score * 2,
    )
    db.add(interaction)
    await db.commit()
    await db.refresh(interaction)

    return SocialInteractionResponse(
        id=interaction.id,
        interaction_type=body.interaction_type,
        person_name=interaction.person_name,
        notes=interaction.notes,
        quality_score=interaction.quality_rating,
        created_at=interaction.created_at,
    )


@router.get("/interactions")
async def get_interactions(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
    limit: int = Query(default=30, le=100),
) -> list[SocialInteractionResponse]:
    result = await db.execute(
        select(SocialInteraction)
        .where(SocialInteraction.user_id == str(current_user.id))
        .order_by(SocialInteraction.created_at.desc())
        .limit(limit)
    )
    rows = result.scalars().all()
    return [
        SocialInteractionResponse(
            id=row.id,
            interaction_type=row.interaction_type.value,
            person_name=row.person_name,
            notes=row.notes,
            quality_score=row.quality_rating,
            created_at=row.created_at,
        )
        for row in rows
    ]


@router.get("/health")
async def get_social_health(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
) -> SocialHealthResponse:
    uid = str(current_user.id)
    now = datetime.now(timezone.utc)
    week_ago = now - timedelta(days=7)
    month_ago = now - timedelta(days=30)

    # Weekly interactions
    weekly_result = await db.execute(
        select(func.count(SocialInteraction.id)).where(
            SocialInteraction.user_id == uid,
            SocialInteraction.created_at >= week_ago,
        )
    )
    weekly_interactions = weekly_result.scalar_one() or 0

    # Average quality (quality_rating) over last 30 days
    avg_result = await db.execute(
        select(func.avg(SocialInteraction.quality_rating)).where(
            SocialInteraction.user_id == uid,
            SocialInteraction.created_at >= month_ago,
        )
    )
    average_quality = float(avg_result.scalar_one() or 0)

    # Meaningful = quality_rating >= 7 in last 30 days
    meaningful_result = await db.execute(
        select(func.count(SocialInteraction.id)).where(
            SocialInteraction.user_id == uid,
            SocialInteraction.quality_rating >= 7,
            SocialInteraction.created_at >= month_ago,
        )
    )
    meaningful_connections = meaningful_result.scalar_one() or 0

    # Social score: frequency (50%) + quality (50%)
    target_weekly = 7
    frequency_score = min(weekly_interactions / target_weekly, 1.0) * 50
    quality_pts = (average_quality / 10) * 50
    social_score = frequency_score + quality_pts

    isolation_risk = max(0, min(100, 100 - int(social_score * 1.2)))

    return SocialHealthResponse(
        social_score=round(social_score, 1),
        weekly_interactions=weekly_interactions,
        average_quality=round(average_quality, 1),
        isolation_risk=isolation_risk,
        meaningful_connections=meaningful_connections,
    )
