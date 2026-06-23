from datetime import datetime
from sqlalchemy import String, Text, Integer, Boolean, DateTime, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class PomodoroSession(UUIDPrimaryKey, TimestampMixin, Base):
    """A completed (or interrupted) Pomodoro work session."""
    __tablename__ = "pomodoro_sessions"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    session_date: Mapped[str] = mapped_column(Date, nullable=False)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    work_minutes: Mapped[int] = mapped_column(Integer, default=25, nullable=False)
    break_minutes: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    cycles_completed: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    task_description: Mapped[str | None] = mapped_column(Text, nullable=True)
    domain: Mapped[str | None] = mapped_column(String(100), nullable=True)
    linked_goal_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("goals.id", ondelete="SET NULL"), nullable=True)
    task_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
