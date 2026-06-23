import enum
from sqlalchemy import String, Text, Integer, Float, Boolean, Date, ForeignKey, Enum as SAEnum, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class GoalTimeframe(str, enum.Enum):
    ANNUAL = "annual"
    QUARTERLY = "quarterly"
    MONTHLY = "monthly"
    WEEKLY = "weekly"
    DAILY = "daily"


class GoalStatus(str, enum.Enum):
    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    PAUSED = "paused"
    CANCELLED = "cancelled"


class GoalPriority(str, enum.Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class Goal(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "goals"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    parent_goal_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("goals.id", ondelete="SET NULL"), nullable=True)

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    domain: Mapped[str] = mapped_column(String(100), nullable=False)

    timeframe: Mapped[GoalTimeframe] = mapped_column(SAEnum(GoalTimeframe, native_enum=False), nullable=False)
    status: Mapped[GoalStatus] = mapped_column(SAEnum(GoalStatus, native_enum=False), default=GoalStatus.NOT_STARTED, nullable=False)
    priority: Mapped[GoalPriority] = mapped_column(SAEnum(GoalPriority, native_enum=False), default=GoalPriority.MEDIUM, nullable=False)

    target_date: Mapped[str | None] = mapped_column(Date, nullable=True)
    progress_percent: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    xp_reward: Mapped[int] = mapped_column(Integer, default=50, nullable=False)

    success_criteria: Mapped[str | None] = mapped_column(Text, nullable=True)
    completed_at: Mapped[str | None] = mapped_column(Date, nullable=True)

    milestones: Mapped[list["Milestone"]] = relationship("Milestone", back_populates="goal", cascade="all, delete-orphan")
    sub_goals: Mapped[list["Goal"]] = relationship("Goal", foreign_keys=[parent_goal_id])
    sessions: Mapped[list["GoalSession"]] = relationship("GoalSession", back_populates="goal", cascade="all, delete-orphan")
    tasks: Mapped[list["Task"]] = relationship("Task", back_populates="goal", cascade="all, delete-orphan")


class Milestone(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "milestones"

    goal_id: Mapped[str] = mapped_column(String(36), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    order_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    completed_at: Mapped[str | None] = mapped_column(Date, nullable=True)

    goal: Mapped["Goal"] = relationship("Goal", back_populates="milestones")


class GoalSession(UUIDPrimaryKey, TimestampMixin, Base):
    """Work session logged against a specific goal — tracks effort and progress."""
    __tablename__ = "goal_sessions"

    goal_id: Mapped[str] = mapped_column(String(36), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    session_date: Mapped[str] = mapped_column(Date, nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    what_i_did: Mapped[str] = mapped_column(Text, nullable=False)
    progress_made: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    goal: Mapped["Goal"] = relationship("Goal", back_populates="sessions")
