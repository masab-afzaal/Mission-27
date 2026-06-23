import enum
from sqlalchemy import String, Text, Integer, Float, Boolean, Date, ForeignKey, Enum as SAEnum, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class MasteryDomain(str, enum.Enum):
    AI_ENGINEERING = "ai_engineering"
    CS_FOUNDATIONS = "cs_foundations"


class ProficiencyLevel(str, enum.Enum):
    BEGINNER = "beginner"
    ELEMENTARY = "elementary"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    EXPERT = "expert"


class SkillArea(UUIDPrimaryKey, TimestampMixin, Base):
    """Top-level skill (e.g. 'Machine Learning', 'Data Structures')."""
    __tablename__ = "skill_areas"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    domain: Mapped[MasteryDomain] = mapped_column(SAEnum(MasteryDomain, native_enum=False), nullable=False)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    proficiency: Mapped[ProficiencyLevel] = mapped_column(SAEnum(ProficiencyLevel, native_enum=False), default=ProficiencyLevel.BEGINNER, nullable=False)
    mastery_percent: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    total_study_hours: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    target_hours: Mapped[float] = mapped_column(Float, default=100.0, nullable=False)
    icon: Mapped[str | None] = mapped_column(String(50), nullable=True)
    order_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    topics: Mapped[list["SkillTopic"]] = relationship("SkillTopic", back_populates="skill_area", cascade="all, delete-orphan")
    study_sessions: Mapped[list["MasteryStudySession"]] = relationship("MasteryStudySession", back_populates="skill_area", cascade="all, delete-orphan")


class SkillTopic(UUIDPrimaryKey, TimestampMixin, Base):
    """Sub-topic within a skill (e.g. 'Backpropagation' within 'Deep Learning')."""
    __tablename__ = "skill_topics"

    skill_area_id: Mapped[str] = mapped_column(String(36), ForeignKey("skill_areas.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    confidence_level: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    retention_level: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    last_studied: Mapped[str | None] = mapped_column(Date, nullable=True)
    next_review: Mapped[str | None] = mapped_column(Date, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    resources: Mapped[list | None] = mapped_column(JSON, nullable=True)

    skill_area: Mapped["SkillArea"] = relationship("SkillArea", back_populates="topics")


class MasteryStudySession(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "mastery_study_sessions"

    skill_area_id: Mapped[str] = mapped_column(String(36), ForeignKey("skill_areas.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    session_date: Mapped[str] = mapped_column(Date, nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    topics_covered: Mapped[list | None] = mapped_column(JSON, nullable=True)
    session_type: Mapped[str] = mapped_column(String(50), default="study", nullable=False)
    quality_rating: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    skill_area: Mapped["SkillArea"] = relationship("SkillArea", back_populates="study_sessions")
