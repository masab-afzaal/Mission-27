import enum
from sqlalchemy import String, Text, Integer, Boolean, DateTime, ForeignKey, Enum as SAEnum, JSON
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class AchievementCategory(str, enum.Enum):
    STREAK = "streak"
    MILESTONE = "milestone"
    CONSISTENCY = "consistency"
    MASTERY = "mastery"
    SOCIAL = "social"
    HEALTH = "health"
    RESEARCH = "research"
    IELTS = "ielts"


class XPTransaction(UUIDPrimaryKey, Base):
    __tablename__ = "xp_transactions"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    amount: Mapped[int] = mapped_column(Integer, nullable=False)
    source: Mapped[str] = mapped_column(String(100), nullable=False)
    source_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    earned_at: Mapped[str] = mapped_column(DateTime(timezone=True), nullable=False)


class Achievement(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "achievements"

    key: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[AchievementCategory] = mapped_column(SAEnum(AchievementCategory, native_enum=False), nullable=False)
    xp_reward: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    icon: Mapped[str | None] = mapped_column(String(50), nullable=True)
    requirement: Mapped[dict | None] = mapped_column(JSON, nullable=True)


class UserAchievement(UUIDPrimaryKey, Base):
    __tablename__ = "user_achievements"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    achievement_id: Mapped[str] = mapped_column(String(36), ForeignKey("achievements.id", ondelete="CASCADE"), nullable=False)
    earned_at: Mapped[str] = mapped_column(DateTime(timezone=True), nullable=False)


class IdentityProfile(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "identity_profiles"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    identity_name: Mapped[str] = mapped_column(String(100), nullable=False)
    strength_score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_actions: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    icon: Mapped[str | None] = mapped_column(String(50), nullable=True)
    color_hex: Mapped[str | None] = mapped_column(String(7), nullable=True)
