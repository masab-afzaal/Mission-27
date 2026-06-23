import enum
from sqlalchemy import String, Text, Integer, Boolean, Date, ForeignKey, Enum as SAEnum, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class NoteType(str, enum.Enum):
    LEARNING = "learning"
    RESEARCH_FINDING = "research_finding"
    IDEA = "idea"
    BOOK_SUMMARY = "book_summary"
    ARTICLE_DRAFT = "article_draft"
    REFERENCE = "reference"
    LESSON_LEARNED = "lesson_learned"
    PROJECT_NOTE = "project_note"
    REFLECTION = "reflection"
    OTHER = "other"


class KnowledgeNote(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "knowledge_notes"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(300), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    note_type: Mapped[NoteType] = mapped_column(SAEnum(NoteType, native_enum=False), nullable=False)
    domain: Mapped[str | None] = mapped_column(String(100), nullable=True)
    tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    linked_note_ids: Mapped[list | None] = mapped_column(JSON, nullable=True)
    source_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_pinned: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_archived: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    view_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class ResearchPaper(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "research_papers"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    authors: Mapped[list | None] = mapped_column(JSON, nullable=True)
    abstract: Mapped[str | None] = mapped_column(Text, nullable=True)
    url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_summarised: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    personal_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    key_insights: Mapped[list | None] = mapped_column(JSON, nullable=True)
    date_read: Mapped[str | None] = mapped_column(Date, nullable=True)
    relevance_score: Mapped[int] = mapped_column(Integer, default=3, nullable=False)


class ResearchProject(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "research_projects"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(300), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="planning", nullable=False)
    target_venue: Mapped[str | None] = mapped_column(String(200), nullable=True)
    submission_deadline: Mapped[str | None] = mapped_column(Date, nullable=True)
    writing_progress_percent: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    milestones: Mapped[list | None] = mapped_column(JSON, nullable=True)
