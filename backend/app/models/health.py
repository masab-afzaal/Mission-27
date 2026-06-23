import enum
from sqlalchemy import String, Text, Integer, Float, Boolean, Date, ForeignKey, Enum as SAEnum, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class WorkoutType(str, enum.Enum):
    GYM = "gym"
    RUNNING = "running"
    WALKING = "walking"
    SPORTS = "sports"
    MOBILITY = "mobility"
    CYCLING = "cycling"
    SWIMMING = "swimming"
    OTHER = "other"


class WorkoutSession(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "workout_sessions"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    workout_date: Mapped[str] = mapped_column(Date, nullable=False)
    workout_type: Mapped[WorkoutType] = mapped_column(SAEnum(WorkoutType, native_enum=False), nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    intensity_level: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    exercises: Mapped[list | None] = mapped_column(JSON, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    energy_before: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    energy_after: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class HealthMetric(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "health_metrics"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    metric_date: Mapped[str] = mapped_column(Date, nullable=False)
    weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    body_fat_percent: Mapped[float | None] = mapped_column(Float, nullable=True)
    sleep_hours: Mapped[float | None] = mapped_column(Float, nullable=True)
    sleep_quality: Mapped[int | None] = mapped_column(Integer, nullable=True)
    energy_level: Mapped[int | None] = mapped_column(Integer, nullable=True)
    water_ml: Mapped[int | None] = mapped_column(Integer, nullable=True)
    mood_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    stress_level: Mapped[int | None] = mapped_column(Integer, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class SportsActivity(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "sports_activities"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    sport_name: Mapped[str] = mapped_column(String(100), nullable=False)
    activity_date: Mapped[str] = mapped_column(Date, nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    location: Mapped[str | None] = mapped_column(String(200), nullable=True)
    with_others: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
