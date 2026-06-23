import enum
from sqlalchemy import String, Text, Integer, Float, Boolean, Date, DateTime, ForeignKey, Enum as SAEnum, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class IELTSSkill(str, enum.Enum):
    READING = "reading"
    LISTENING = "listening"
    WRITING = "writing"
    SPEAKING = "speaking"
    VOCABULARY = "vocabulary"
    GRAMMAR = "grammar"


class IELTSProfile(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "ielts_profiles"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    target_band: Mapped[float] = mapped_column(Float, default=8.0, nullable=False)
    exam_date: Mapped[str | None] = mapped_column(Date, nullable=True)
    current_band_estimate: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    readiness_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    reading_band: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    listening_band: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    writing_band: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    speaking_band: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    study_sessions: Mapped[list["IELTSStudySession"]] = relationship("IELTSStudySession", cascade="all, delete-orphan")
    mock_tests: Mapped[list["IELTSMockTest"]] = relationship("IELTSMockTest", cascade="all, delete-orphan")
    vocabulary_entries: Mapped[list["VocabularyEntry"]] = relationship("VocabularyEntry", cascade="all, delete-orphan")


class IELTSStudySession(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "ielts_study_sessions"

    profile_id: Mapped[str] = mapped_column(String(36), ForeignKey("ielts_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    skill: Mapped[IELTSSkill] = mapped_column(SAEnum(IELTSSkill, native_enum=False), nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    session_date: Mapped[str] = mapped_column(Date, nullable=False)
    topics_covered: Mapped[list | None] = mapped_column(JSON, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    quality_rating: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class IELTSMockTest(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "ielts_mock_tests"

    profile_id: Mapped[str] = mapped_column(String(36), ForeignKey("ielts_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    test_date: Mapped[str] = mapped_column(Date, nullable=False)
    reading_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    listening_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    writing_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    speaking_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    overall_band: Mapped[float | None] = mapped_column(Float, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    weak_areas: Mapped[list | None] = mapped_column(JSON, nullable=True)


class VocabularyEntry(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "vocabulary_entries"

    profile_id: Mapped[str] = mapped_column(String(36), ForeignKey("ielts_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    word: Mapped[str] = mapped_column(String(100), nullable=False)
    definition: Mapped[str] = mapped_column(Text, nullable=False)
    example_sentence: Mapped[str | None] = mapped_column(Text, nullable=True)
    tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    mastery_level: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    next_review_date: Mapped[str | None] = mapped_column(Date, nullable=True)
    review_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    # SM-2 spaced repetition fields
    ease_factor: Mapped[float] = mapped_column(Float, default=2.5, nullable=False)
    interval_days: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    last_review_date: Mapped[str | None] = mapped_column(Date, nullable=True)
