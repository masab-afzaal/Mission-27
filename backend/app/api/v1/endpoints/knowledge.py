from typing import Optional
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.knowledge import KnowledgeNote, NoteType, ResearchPaper, ResearchProject
from app.models.user import User

router = APIRouter(prefix="/knowledge", tags=["knowledge"])


class NoteCreate(BaseModel):
    title: str = Field(min_length=1, max_length=300)
    content: str = Field(min_length=1)
    note_type: NoteType = NoteType.LEARNING
    domain: Optional[str] = None
    tags: Optional[list[str]] = None
    source_url: Optional[str] = None


class NoteResponse(BaseModel):
    id: str
    title: str
    content: str
    note_type: NoteType
    domain: Optional[str] = None
    tags: Optional[list[str]] = None
    is_pinned: bool
    is_archived: bool
    created_at: str
    model_config = {"from_attributes": True}

    @classmethod
    def from_orm_with_str(cls, obj: KnowledgeNote) -> "NoteResponse":
        return cls(
            id=obj.id,
            title=obj.title,
            content=obj.content,
            note_type=obj.note_type,
            domain=obj.domain,
            tags=obj.tags,
            is_pinned=obj.is_pinned,
            is_archived=obj.is_archived,
            created_at=obj.created_at.isoformat(),
        )


@router.post("/notes", status_code=status.HTTP_201_CREATED)
async def create_note(
    payload: NoteCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    note = KnowledgeNote(
        user_id=current_user.id,
        title=payload.title,
        content=payload.content,
        note_type=payload.note_type,
        domain=payload.domain,
        tags=payload.tags,
        source_url=payload.source_url,
    )
    db.add(note)
    await db.flush()
    return NoteResponse.from_orm_with_str(note)


@router.get("/notes", response_model=list[NoteResponse])
async def list_notes(
    search: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = (
        select(KnowledgeNote)
        .where(KnowledgeNote.user_id == current_user.id, KnowledgeNote.is_archived.is_(False))
        .order_by(KnowledgeNote.is_pinned.desc(), KnowledgeNote.created_at.desc())
    )
    if search:
        stmt = stmt.where(
            or_(KnowledgeNote.title.ilike(f"%{search}%"), KnowledgeNote.content.ilike(f"%{search}%"))
        )
    notes = (await db.execute(stmt)).scalars().all()
    return [NoteResponse.from_orm_with_str(n) for n in notes]


class PaperCreate(BaseModel):
    title: str = Field(min_length=1, max_length=500)
    authors: Optional[list[str]] = None
    abstract: Optional[str] = None
    url: Optional[str] = None
    tags: Optional[list[str]] = None


@router.post("/papers", status_code=status.HTTP_201_CREATED)
async def add_paper(
    payload: PaperCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    paper = ResearchPaper(user_id=current_user.id, **payload.model_dump())
    db.add(paper)
    await db.flush()
    return {"id": paper.id, "title": paper.title}


@router.get("/papers")
async def list_papers(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(ResearchPaper).where(ResearchPaper.user_id == current_user.id).order_by(ResearchPaper.created_at.desc())
    papers = (await db.execute(stmt)).scalars().all()
    return [{"id": p.id, "title": p.title, "is_read": p.is_read, "is_summarised": p.is_summarised, "relevance_score": p.relevance_score} for p in papers]
