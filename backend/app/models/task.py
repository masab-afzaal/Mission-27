from datetime import date
from sqlalchemy import String, Text, Integer, Boolean, ForeignKey, Date
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey

class Task(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "tasks"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    goal_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("goals.id", ondelete="SET NULL"), nullable=True, index=True)

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    deadline: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_domino: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    completed_at: Mapped[date | None] = mapped_column(Date, nullable=True)
    estimated_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    actual_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    domain: Mapped[str | None] = mapped_column(String(100), nullable=True)
    xp_reward: Mapped[int] = mapped_column(Integer, default=10, nullable=False)

    # Relationships
    goal: Mapped["Goal"] = relationship("Goal", back_populates="tasks", foreign_keys=[goal_id])
