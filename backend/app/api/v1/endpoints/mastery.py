from datetime import datetime, timezone, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.mastery import SkillArea, MasteryStudySession, MasteryDomain
from app.models.user import User
from app.repositories.user_repository import UserRepository

router = APIRouter(prefix="/mastery", tags=["mastery"])


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class MasterySessionCreate(BaseModel):
    topic_name: str = Field(min_length=2, max_length=100)
    domain: str = "ai_engineering"
    duration_minutes: int = Field(default=60, ge=5, le=480)
    target_hours: float | None = None
    notes: str | None = None


class SkillAreaResponse(BaseModel):
    id: str
    name: str
    domain: str
    mastery_percent: float
    total_sessions: int
    target_hours: float

    model_config = {"from_attributes": True}


class MasterySessionResponse(BaseModel):
    id: str
    skill_area_name: str
    domain: str
    duration_minutes: int
    created_at: datetime


class MasteryStatsResponse(BaseModel):
    total_study_minutes: int
    current_streak: int
    average_mastery: float
    completed_topics: int
    total_topics: int


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _parse_domain(domain_str: str) -> MasteryDomain:
    if domain_str == "cs_foundations":
        return MasteryDomain.CS_FOUNDATIONS
    return MasteryDomain.AI_ENGINEERING


async def _get_or_create_skill_area(
    db: AsyncSession,
    user_id: str,
    domain: MasteryDomain,
    name: str,
    target_hours: float | None = None,
) -> SkillArea:
    result = await db.execute(
        select(SkillArea).where(
            and_(
                SkillArea.user_id == user_id,
                SkillArea.name == name,
                SkillArea.domain == domain,
            )
        )
    )
    area = result.scalar_one_or_none()
    if area:
        return area

    area = SkillArea(
        user_id=user_id,
        name=name,
        domain=domain,
        target_hours=target_hours if target_hours and target_hours > 0 else 100.0,
    )
    db.add(area)
    await db.flush()
    return area


async def _calculate_streak(db: AsyncSession, user_id: str) -> int:
    streak = 0
    current_day = datetime.now(timezone.utc).date()

    for _ in range(365):
        result = await db.execute(
            select(func.count(MasteryStudySession.id)).where(
                MasteryStudySession.user_id == user_id,
                MasteryStudySession.session_date == current_day,
            )
        )
        count = result.scalar_one() or 0
        if count == 0:
            break
        streak += 1
        current_day -= timedelta(days=1)

    return streak


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.get("/skills", response_model=list[SkillAreaResponse])
async def get_skill_areas(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
    domain: str = Query(default="ai_engineering"),
):
    domain_enum = _parse_domain(domain)

    result = await db.execute(
        select(SkillArea).where(
            and_(
                SkillArea.user_id == str(current_user.id),
                SkillArea.domain == domain_enum,
            )
        ).order_by(SkillArea.mastery_percent.desc())
    )
    areas = result.scalars().all()

    output = []
    for area in areas:
        count_result = await db.execute(
            select(func.count(MasteryStudySession.id)).where(
                MasteryStudySession.skill_area_id == str(area.id)
            )
        )
        total_sessions = count_result.scalar_one() or 0
        output.append(
            SkillAreaResponse(
                id=area.id,
                name=area.name,
                domain=area.domain.value,
                mastery_percent=area.mastery_percent,
                total_sessions=total_sessions,
                target_hours=area.target_hours,
            )
        )
    return output


@router.post("/sessions", response_model=MasterySessionResponse, status_code=201)
async def log_study_session(
    body: MasterySessionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    domain_enum = _parse_domain(body.domain)
    skill_area = await _get_or_create_skill_area(
        db, str(current_user.id), domain_enum, body.topic_name, body.target_hours
    )

    today = datetime.now(timezone.utc).date()
    session = MasteryStudySession(
        user_id=str(current_user.id),
        skill_area_id=str(skill_area.id),
        session_date=today,
        duration_minutes=body.duration_minutes,
        notes=body.notes,
        topics_covered=[body.topic_name],
        xp_earned=body.duration_minutes // 5,
    )
    db.add(session)

    skill_area.total_study_hours += body.duration_minutes / 60
    skill_area.mastery_percent = min(
        100.0,
        skill_area.total_study_hours / skill_area.target_hours * 100,
    )

    await db.flush()

    # XP reward
    user_repo = UserRepository(db)
    await user_repo.add_xp(current_user, body.duration_minutes // 5)

    await db.commit()
    await db.refresh(session)

    return MasterySessionResponse(
        id=session.id,
        skill_area_name=skill_area.name,
        domain=skill_area.domain.value,
        duration_minutes=session.duration_minutes,
        created_at=session.created_at,
    )


@router.get("/sessions", response_model=list[MasterySessionResponse])
async def get_sessions(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
    limit: int = Query(default=20, le=100),
):
    result = await db.execute(
        select(MasteryStudySession, SkillArea)
        .join(SkillArea, MasteryStudySession.skill_area_id == SkillArea.id)
        .where(MasteryStudySession.user_id == str(current_user.id))
        .order_by(MasteryStudySession.created_at.desc())
        .limit(limit)
    )
    rows = result.all()
    return [
        MasterySessionResponse(
            id=session.id,
            skill_area_name=area.name,
            domain=area.domain.value,
            duration_minutes=session.duration_minutes,
            created_at=session.created_at,
        )
        for session, area in rows
    ]


@router.get("/stats", response_model=MasteryStatsResponse)
async def get_mastery_stats(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)

    # Total minutes studied
    total_result = await db.execute(
        select(func.sum(MasteryStudySession.duration_minutes)).where(
            MasteryStudySession.user_id == uid
        )
    )
    total_minutes = total_result.scalar_one() or 0

    # Average mastery across all skill areas
    avg_result = await db.execute(
        select(func.avg(SkillArea.mastery_percent)).where(SkillArea.user_id == uid)
    )
    average_mastery = float(avg_result.scalar_one() or 0)

    # Completed topics = skill areas at >= 80% mastery
    completed_result = await db.execute(
        select(func.count(SkillArea.id)).where(
            SkillArea.user_id == uid,
            SkillArea.mastery_percent >= 80,
        )
    )
    completed_topics = completed_result.scalar_one() or 0

    # Total tracked skill areas
    total_topics_result = await db.execute(
        select(func.count(SkillArea.id)).where(SkillArea.user_id == uid)
    )
    total_topics = total_topics_result.scalar_one() or 0

    streak = await _calculate_streak(db, str(current_user.id))

    return MasteryStatsResponse(
        total_study_minutes=int(total_minutes),
        current_streak=streak,
        average_mastery=round(average_mastery, 1),
        completed_topics=completed_topics,
        total_topics=total_topics,
    )
