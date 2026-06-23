from datetime import date
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.ielts import IELTSProfile, IELTSStudySession, IELTSMockTest, VocabularyEntry
from app.repositories.user_repository import UserRepository
from app.schemas.ielts import (
    IELTSCommandCenterResponse,
    IELTSProfileResponse,
    IELTSProfileUpdate,
    MockTestCreate,
    MockTestResponse,
    StudySessionCreate,
    StudySessionResponse,
    VocabCreate,
    VocabResponse,
)

XP_PER_30_MIN = 15


class IELTSService:
    def __init__(self, session: AsyncSession) -> None:
        self._db = session

    async def get_or_create_profile(self, user_id: str) -> IELTSProfile:
        stmt = select(IELTSProfile).where(IELTSProfile.user_id == user_id)
        profile = (await self._db.execute(stmt)).scalar_one_or_none()
        if not profile:
            profile = IELTSProfile(user_id=user_id)
            self._db.add(profile)
            await self._db.flush()
            await self._db.refresh(profile)
        return profile

    async def get_command_center(self, user_id: str) -> IELTSCommandCenterResponse:
        profile = await self.get_or_create_profile(user_id)

        sessions_stmt = (
            select(IELTSStudySession)
            .where(IELTSStudySession.user_id == user_id)
            .order_by(IELTSStudySession.session_date.desc())
            .limit(10)
        )
        sessions = (await self._db.execute(sessions_stmt)).scalars().all()

        tests_stmt = (
            select(IELTSMockTest)
            .where(IELTSMockTest.user_id == user_id)
            .order_by(IELTSMockTest.test_date.desc())
            .limit(5)
        )
        tests = (await self._db.execute(tests_stmt)).scalars().all()

        vocab_count_stmt = select(func.count(VocabularyEntry.id)).where(VocabularyEntry.user_id == user_id)
        vocab_count = (await self._db.execute(vocab_count_stmt)).scalar_one_or_none() or 0

        days_to_exam: Optional[int] = None
        if profile.exam_date:
            days_to_exam = (profile.exam_date - date.today()).days

        probability = self._calculate_band8_probability(profile)

        return IELTSCommandCenterResponse(
            profile=IELTSProfileResponse.model_validate(profile),
            recent_sessions=[StudySessionResponse.model_validate(s) for s in sessions],
            recent_mock_tests=[MockTestResponse.model_validate(t) for t in tests],
            vocabulary_count=vocab_count,
            days_to_exam=days_to_exam,
            band_8_probability=probability,
        )

    async def log_study_session(self, user_id: str, payload: StudySessionCreate) -> StudySessionResponse:
        profile = await self.get_or_create_profile(user_id)
        xp = max(5, (payload.duration_minutes // 30) * XP_PER_30_MIN)
        session = IELTSStudySession(
            profile_id=profile.id,
            user_id=user_id,
            skill=payload.skill,
            duration_minutes=payload.duration_minutes,
            session_date=payload.session_date,
            topics_covered=payload.topics_covered,
            notes=payload.notes,
            quality_rating=payload.quality_rating,
            xp_earned=xp,
        )
        self._db.add(session)
        await self._db.flush()

        user_repo = UserRepository(self._db)
        user = await user_repo.get_by_id(user_id)
        if user:
            await user_repo.add_xp(user, xp)

        await self._update_profile_readiness(profile, user_id)
        return StudySessionResponse.model_validate(session)

    async def log_mock_test(self, user_id: str, payload: MockTestCreate) -> MockTestResponse:
        profile = await self.get_or_create_profile(user_id)
        scores = [s for s in [payload.reading_score, payload.listening_score, payload.writing_score, payload.speaking_score] if s is not None]
        overall = round(sum(scores) / len(scores) * 2) / 2 if scores else None

        test = IELTSMockTest(
            profile_id=profile.id,
            user_id=user_id,
            test_date=payload.test_date,
            reading_score=payload.reading_score,
            listening_score=payload.listening_score,
            writing_score=payload.writing_score,
            speaking_score=payload.speaking_score,
            overall_band=overall,
            notes=payload.notes,
            weak_areas=payload.weak_areas,
        )
        self._db.add(test)
        await self._db.flush()

        if overall:
            profile.current_band_estimate = overall
            if payload.reading_score: profile.reading_band = payload.reading_score
            if payload.listening_score: profile.listening_band = payload.listening_score
            if payload.writing_score: profile.writing_band = payload.writing_score
            if payload.speaking_score: profile.speaking_band = payload.speaking_score

        return MockTestResponse.model_validate(test)

    async def add_vocabulary(self, user_id: str, payload: VocabCreate) -> VocabResponse:
        profile = await self.get_or_create_profile(user_id)
        entry = VocabularyEntry(
            profile_id=profile.id,
            user_id=user_id,
            word=payload.word,
            definition=payload.definition,
            example_sentence=payload.example_sentence,
            tags=payload.tags,
        )
        self._db.add(entry)
        await self._db.flush()
        return VocabResponse.model_validate(entry)

    async def _update_profile_readiness(self, profile: IELTSProfile, user_id: str) -> None:
        total_stmt = (
            select(func.sum(IELTSStudySession.duration_minutes))
            .where(IELTSStudySession.user_id == user_id)
        )
        total = (await self._db.execute(total_stmt)).scalar_one_or_none() or 0
        target_hours = 200
        readiness = min(100.0, (total / (target_hours * 60)) * 100)
        profile.readiness_score = round(readiness, 1)

    @staticmethod
    def _calculate_band8_probability(profile: IELTSProfile) -> float:
        if profile.current_band_estimate == 0:
            return 0.0
        gap = profile.target_band - profile.current_band_estimate
        base = max(0.0, 1.0 - (gap / 2.0))
        readiness_factor = profile.readiness_score / 100
        return round(min(100.0, base * readiness_factor * 100), 1)
