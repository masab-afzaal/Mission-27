"""
Growth Score Engine – calculates all composite scores for the dashboard.

Score philosophy:
  - All scores live in [0, 100].
  - Each composite score aggregates domain-specific signals with configurable weights.
  - Scores are intentionally simple averages/weighted-averages so they remain interpretable.
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.habit import HabitLog, Habit
from app.models.ielts import IELTSProfile, IELTSStudySession
from app.models.mastery import MasteryStudySession, SkillArea
from app.models.health import WorkoutSession, HealthMetric
from app.models.social import SocialInteraction, SocialHealthProfile
from app.models.goal import Goal, GoalStatus
from app.models.analytics import DailySnapshot


@dataclass
class ScoreBundle:
    growth_score: float
    consistency_score: float
    goal_progress_score: float
    learning_score: float
    health_score: float
    social_score: float
    career_progress_score: float
    ielts_readiness: float
    ai_readiness: float
    burnout_risk: float
    isolation_risk: float
    future_self_alignment: float


class ScoreEngine:
    def __init__(self, session: AsyncSession, user_id: str) -> None:
        self._db = session
        self._uid = user_id

    async def compute(self, target_date: date | None = None) -> ScoreBundle:
        today = target_date or date.today()
        lookback_30 = today - timedelta(days=30)
        lookback_7 = today - timedelta(days=7)

        consistency = await self._consistency_score(lookback_30, today)
        learning = await self._learning_score(lookback_7, today)
        health = await self._health_score(lookback_7, today)
        social = await self._social_score(lookback_30, today)
        goal_progress = await self._goal_progress_score()
        ielts = await self._ielts_readiness()
        ai = await self._ai_readiness()

        career = min(100.0, (learning * 0.5 + goal_progress * 0.3 + consistency * 0.2))
        burnout = self._burnout_risk(consistency, health, social)
        isolation = await self._isolation_risk(lookback_7, today)
        future_alignment = min(100.0, (consistency * 0.35 + goal_progress * 0.35 + learning * 0.30))

        growth = min(100.0, (
            consistency * 0.20 +
            learning * 0.20 +
            health * 0.15 +
            social * 0.10 +
            goal_progress * 0.20 +
            career * 0.15
        ))

        return ScoreBundle(
            growth_score=round(growth, 1),
            consistency_score=round(consistency, 1),
            goal_progress_score=round(goal_progress, 1),
            learning_score=round(learning, 1),
            health_score=round(health, 1),
            social_score=round(social, 1),
            career_progress_score=round(career, 1),
            ielts_readiness=round(ielts, 1),
            ai_readiness=round(ai, 1),
            burnout_risk=round(burnout, 1),
            isolation_risk=round(isolation, 1),
            future_self_alignment=round(future_alignment, 1),
        )

    # ── Private calculators ───────────────────────────────────────────────

    async def _consistency_score(self, start: date, end: date) -> float:
        days = (end - start).days or 1
        stmt = (
            select(func.count(HabitLog.id))
            .join(Habit, Habit.id == HabitLog.habit_id)
            .where(
                HabitLog.user_id == self._uid,
                HabitLog.logged_date.between(start, end),
                HabitLog.completed.is_(True),
                Habit.is_active.is_(True),
            )
        )
        completed = (await self._db.execute(stmt)).scalar_one_or_none() or 0

        total_stmt = (
            select(func.count(Habit.id))
            .where(Habit.user_id == self._uid, Habit.is_active.is_(True))
        )
        total_habits = (await self._db.execute(total_stmt)).scalar_one_or_none() or 1
        expected = total_habits * days

        return min(100.0, (completed / expected) * 100) if expected > 0 else 0.0

    async def _learning_score(self, start: date, end: date) -> float:
        ielts_stmt = (
            select(func.sum(IELTSStudySession.duration_minutes))
            .where(
                IELTSStudySession.user_id == self._uid,
                IELTSStudySession.session_date.between(start, end),
            )
        )
        mastery_stmt = (
            select(func.sum(MasteryStudySession.duration_minutes))
            .where(
                MasteryStudySession.user_id == self._uid,
                MasteryStudySession.session_date.between(start, end),
            )
        )
        ielts_mins = (await self._db.execute(ielts_stmt)).scalar_one_or_none() or 0
        mastery_mins = (await self._db.execute(mastery_stmt)).scalar_one_or_none() or 0
        total_mins = ielts_mins + mastery_mins

        target_mins = 7 * 120
        return min(100.0, (total_mins / target_mins) * 100)

    async def _health_score(self, start: date, end: date) -> float:
        days = (end - start).days or 1
        workout_stmt = (
            select(func.count(WorkoutSession.id))
            .where(
                WorkoutSession.user_id == self._uid,
                WorkoutSession.workout_date.between(start, end),
            )
        )
        workouts = (await self._db.execute(workout_stmt)).scalar_one_or_none() or 0
        sleep_stmt = (
            select(func.avg(HealthMetric.sleep_hours))
            .where(
                HealthMetric.user_id == self._uid,
                HealthMetric.metric_date.between(start, end),
            )
        )
        avg_sleep = (await self._db.execute(sleep_stmt)).scalar_one_or_none() or 0.0

        workout_score = min(100.0, (workouts / (days * 0.7)) * 100)
        sleep_score = min(100.0, (avg_sleep / 7.5) * 100)
        return (workout_score * 0.6 + sleep_score * 0.4)

    async def _social_score(self, start: date, end: date) -> float:
        stmt = (
            select(func.count(SocialInteraction.id))
            .where(
                SocialInteraction.user_id == self._uid,
                SocialInteraction.interaction_date.between(start, end),
            )
        )
        count = (await self._db.execute(stmt)).scalar_one_or_none() or 0
        target = 20
        return min(100.0, (count / target) * 100)

    async def _goal_progress_score(self) -> float:
        stmt = select(func.avg(Goal.progress_percent)).where(
            Goal.user_id == self._uid,
            Goal.status.notin_([GoalStatus.CANCELLED, GoalStatus.COMPLETED]),
        )
        avg = (await self._db.execute(stmt)).scalar_one_or_none() or 0.0
        return min(100.0, float(avg))

    async def _ielts_readiness(self) -> float:
        stmt = select(IELTSProfile).where(IELTSProfile.user_id == self._uid)
        profile = (await self._db.execute(stmt)).scalar_one_or_none()
        if not profile:
            return 0.0
        return min(100.0, float(profile.readiness_score))

    async def _ai_readiness(self) -> float:
        stmt = (
            select(func.avg(SkillArea.mastery_percent))
            .where(SkillArea.user_id == self._uid, SkillArea.domain == "ai_engineering")
        )
        avg = (await self._db.execute(stmt)).scalar_one_or_none() or 0.0
        return min(100.0, float(avg))

    async def _isolation_risk(self, start: date, end: date) -> float:
        stmt = (
            select(func.count(SocialInteraction.id))
            .where(
                SocialInteraction.user_id == self._uid,
                SocialInteraction.interaction_date.between(start, end),
            )
        )
        count = (await self._db.execute(stmt)).scalar_one_or_none() or 0
        target = 5
        lack = max(0, target - count) / target
        return round(lack * 100, 1)

    @staticmethod
    def _burnout_risk(consistency: float, health: float, social: float) -> float:
        low_health = max(0.0, 50 - health) / 50
        low_social = max(0.0, 40 - social) / 40
        high_consistency_pressure = max(0.0, consistency - 90) / 10
        raw = (low_health * 0.4 + low_social * 0.3 + high_consistency_pressure * 0.3) * 100
        return min(100.0, raw)
