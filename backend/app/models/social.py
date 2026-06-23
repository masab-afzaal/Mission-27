import enum
from sqlalchemy import String, Text, Integer, Float, Boolean, Date, ForeignKey, Enum as SAEnum, JSON
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class InteractionType(str, enum.Enum):
    FRIEND_MEETUP = "friend_meetup"
    FAMILY = "family"
    PROFESSIONAL_NETWORKING = "professional_networking"
    ONLINE_COMMUNITY = "online_community"
    EVENT = "event"
    MENTORING = "mentoring"
    COLLABORATION = "collaboration"
    CASUAL_CHAT = "casual_chat"


class SocialInteraction(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "social_interactions"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    interaction_date: Mapped[str] = mapped_column(Date, nullable=False)
    interaction_type: Mapped[InteractionType] = mapped_column(SAEnum(InteractionType, native_enum=False), nullable=False)
    person_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    duration_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    quality_rating: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    is_professional: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class SocialHealthProfile(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "social_health_profiles"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    social_health_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    isolation_risk_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    weekly_interaction_target: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    professional_network_size: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    last_calculated_at: Mapped[str | None] = mapped_column(Date, nullable=True)
