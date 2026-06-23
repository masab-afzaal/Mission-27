from sqlalchemy import String, Text, Integer, Float, Date, ForeignKey, JSON, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class DailySnapshot(UUIDPrimaryKey, TimestampMixin, Base):
    """Daily roll-up of all growth scores — used for dashboard trend charts."""
    __tablename__ = "daily_snapshots"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    snapshot_date: Mapped[str] = mapped_column(Date, nullable=False)

    growth_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    consistency_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    goal_progress_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    learning_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    health_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    social_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    career_progress_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    ielts_readiness: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    ai_readiness: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    burnout_risk: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    isolation_risk: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    future_self_alignment: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    study_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    exercise_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    social_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    xp_earned_today: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    habits_completed: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    habits_total: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    domain_breakdown: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    # Morning check-in
    morning_checkin_done: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    morning_mood: Mapped[int | None] = mapped_column(Integer, nullable=True)
    morning_energy: Mapped[int | None] = mapped_column(Integer, nullable=True)
    morning_intentions: Mapped[list | None] = mapped_column(JSON, nullable=True)

    # Domino task
    domino_task: Mapped[str | None] = mapped_column(String(300), nullable=True)
    domino_done: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Daily reflection (retro and planning)
    day_target: Mapped[str | None] = mapped_column(Text, nullable=True)
    achieved_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    positives: Mapped[str | None] = mapped_column(Text, nullable=True)
    negatives: Mapped[str | None] = mapped_column(Text, nullable=True)
    tomorrow_plan: Mapped[str | None] = mapped_column(Text, nullable=True)


class WeeklyReview(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "weekly_reviews"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    week_start_date: Mapped[str] = mapped_column(Date, nullable=False)
    week_end_date: Mapped[str] = mapped_column(Date, nullable=False)
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    achievements: Mapped[list | None] = mapped_column(JSON, nullable=True)
    failures: Mapped[list | None] = mapped_column(JSON, nullable=True)
    lessons_learned: Mapped[list | None] = mapped_column(JSON, nullable=True)
    next_week_priorities: Mapped[list | None] = mapped_column(JSON, nullable=True)
    avg_growth_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    ai_generated: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)


class ObstacleLog(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "obstacle_logs"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    log_date: Mapped[str] = mapped_column(Date, nullable=False)
    blocker_type: Mapped[str] = mapped_column(String(100), nullable=False)
    affected_domain: Mapped[str | None] = mapped_column(String(100), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    resolution: Mapped[str | None] = mapped_column(Text, nullable=True)
    severity: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
