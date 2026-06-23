import enum
from sqlalchemy import String, Text, Integer, Float, Boolean, Date, ForeignKey, Enum as SAEnum, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class HabitFrequency(str, enum.Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    CUSTOM = "custom"


class HabitCategory(str, enum.Enum):
    STUDY = "study"
    HEALTH = "health"
    SOCIAL = "social"
    CAREER = "career"
    PERSONAL = "personal"
    IELTS = "ielts"
    AI_ENGINEERING = "ai_engineering"
    CS_FOUNDATIONS = "cs_foundations"
    RESEARCH = "research"
    SPORTS = "sports"


class Habit(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "habits"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    category: Mapped[HabitCategory] = mapped_column(SAEnum(HabitCategory, native_enum=False), nullable=False)
    domain: Mapped[str] = mapped_column(String(100), nullable=False)
    frequency: Mapped[HabitFrequency] = mapped_column(SAEnum(HabitFrequency, native_enum=False), default=HabitFrequency.DAILY, nullable=False)
    target_count_per_period: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    current_streak: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    longest_streak: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_completions: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    consistency_percent: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    xp_per_completion: Mapped[int] = mapped_column(Integer, default=10, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    custom_days: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    linked_goal_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("goals.id", ondelete="SET NULL"), nullable=True)

    logs: Mapped[list["HabitLog"]] = relationship("HabitLog", back_populates="habit", cascade="all, delete-orphan")


class HabitLog(UUIDPrimaryKey, Base):
    __tablename__ = "habit_logs"

    habit_id: Mapped[str] = mapped_column(String(36), ForeignKey("habits.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    logged_date: Mapped[str] = mapped_column(Date, nullable=False)
    completed: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    habit: Mapped["Habit"] = relationship("Habit", back_populates="logs")
