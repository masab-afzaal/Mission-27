"""Achievement service — seeds definitions and grants badges on qualifying events."""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.gamification import Achievement, AchievementCategory, UserAchievement
from app.models.habit import Habit, HabitLog
from app.models.goal import Goal, GoalSession, GoalStatus
from app.models.ielts import VocabularyEntry, IELTSStudySession
from app.models.mastery import MasteryStudySession
from app.models.social import SocialInteraction
from app.models.health import WorkoutSession
from app.models.pomodoro import PomodoroSession
from app.models.analytics import DailySnapshot
from app.models.user import User
from app.repositories.user_repository import UserRepository


ACHIEVEMENT_DEFINITIONS: list[dict[str, Any]] = [
    {"key": "first_habit", "name": "Habit Initiated", "description": "Create your first habit", "category": AchievementCategory.STREAK, "xp_reward": 50, "icon": "🔁"},
    {"key": "streak_7", "name": "Week Warrior", "description": "Maintain a 7-day habit streak", "category": AchievementCategory.STREAK, "xp_reward": 100, "icon": "🔥"},
    {"key": "streak_30", "name": "Month Maverick", "description": "Maintain a 30-day habit streak", "category": AchievementCategory.STREAK, "xp_reward": 300, "icon": "💫"},
    {"key": "streak_100", "name": "Century Streak", "description": "Maintain a 100-day habit streak", "category": AchievementCategory.STREAK, "xp_reward": 1000, "icon": "💯"},
    {"key": "first_goal", "name": "Goal Setter", "description": "Create your first goal", "category": AchievementCategory.MILESTONE, "xp_reward": 50, "icon": "🎯"},
    {"key": "first_goal_complete", "name": "Goal Achieved", "description": "Complete your first goal", "category": AchievementCategory.MILESTONE, "xp_reward": 200, "icon": "✅"},
    {"key": "goal_session_5", "name": "Daily Worker", "description": "Log 5 goal work sessions", "category": AchievementCategory.MILESTONE, "xp_reward": 100, "icon": "💼"},
    {"key": "first_ielts_session", "name": "IELTS Pioneer", "description": "Log your first IELTS study session", "category": AchievementCategory.IELTS, "xp_reward": 50, "icon": "📝"},
    {"key": "ielts_mock_test", "name": "Test Taker", "description": "Take your first IELTS mock test", "category": AchievementCategory.IELTS, "xp_reward": 100, "icon": "📋"},
    {"key": "vocab_50", "name": "Vocabulary Builder", "description": "Add 50 vocabulary words", "category": AchievementCategory.IELTS, "xp_reward": 150, "icon": "📚"},
    {"key": "mastery_session_10", "name": "Consistent Learner", "description": "Complete 10 mastery study sessions", "category": AchievementCategory.MASTERY, "xp_reward": 100, "icon": "🧠"},
    {"key": "mastery_session_50", "name": "Knowledge Seeker", "description": "Complete 50 mastery study sessions", "category": AchievementCategory.MASTERY, "xp_reward": 300, "icon": "🔬"},
    {"key": "social_10", "name": "Social Connector", "description": "Log 10 social interactions", "category": AchievementCategory.SOCIAL, "xp_reward": 100, "icon": "👥"},
    {"key": "social_50", "name": "Social Butterfly", "description": "Log 50 social interactions", "category": AchievementCategory.SOCIAL, "xp_reward": 250, "icon": "🦋"},
    {"key": "workout_10", "name": "Fitness Initiator", "description": "Complete 10 workout sessions", "category": AchievementCategory.HEALTH, "xp_reward": 100, "icon": "💪"},
    {"key": "workout_50", "name": "Gym Warrior", "description": "Complete 50 workout sessions", "category": AchievementCategory.HEALTH, "xp_reward": 300, "icon": "🏋️"},
    {"key": "level_5", "name": "Rising Star", "description": "Reach level 5", "category": AchievementCategory.MILESTONE, "xp_reward": 100, "icon": "⭐"},
    {"key": "level_10", "name": "Mission Operator", "description": "Reach level 10", "category": AchievementCategory.MILESTONE, "xp_reward": 200, "icon": "🚀"},
    {"key": "level_25", "name": "Elite Agent", "description": "Reach level 25", "category": AchievementCategory.MILESTONE, "xp_reward": 500, "icon": "👑"},
    {"key": "pomodoro_10", "name": "Focus Initiator", "description": "Complete 10 Pomodoro sessions", "category": AchievementCategory.CONSISTENCY, "xp_reward": 100, "icon": "🍅"},
    {"key": "pomodoro_100", "name": "Deep Worker", "description": "Complete 100 Pomodoro sessions", "category": AchievementCategory.CONSISTENCY, "xp_reward": 500, "icon": "🧘"},
    {"key": "morning_checkin_7", "name": "Morning Ritualist", "description": "Complete 7 morning check-ins in a row", "category": AchievementCategory.CONSISTENCY, "xp_reward": 150, "icon": "🌅"},
    {"key": "note_10", "name": "Knowledge Keeper", "description": "Create 10 knowledge notes", "category": AchievementCategory.RESEARCH, "xp_reward": 100, "icon": "📓"},
    {"key": "research_paper", "name": "Researcher", "description": "Add your first research paper", "category": AchievementCategory.RESEARCH, "xp_reward": 75, "icon": "🔭"},
    {"key": "snapshot_30", "name": "Consistent Tracker", "description": "Track 30 daily snapshots", "category": AchievementCategory.CONSISTENCY, "xp_reward": 200, "icon": "📊"},
]


class AchievementService:
    def __init__(self, session: AsyncSession) -> None:
        self._db = session

    async def seed_achievements(self) -> None:
        """Upsert all predefined achievements — safe to call on every startup."""
        for defn in ACHIEVEMENT_DEFINITIONS:
            existing = (await self._db.execute(
                select(Achievement).where(Achievement.key == defn["key"])
            )).scalar_one_or_none()
            if not existing:
                ach = Achievement(
                    key=defn["key"],
                    name=defn["name"],
                    description=defn["description"],
                    category=defn["category"],
                    xp_reward=defn["xp_reward"],
                    icon=defn.get("icon"),
                )
                self._db.add(ach)
        await self._db.commit()

    async def check_and_grant(self, user_id: str, event: str) -> list[dict]:
        """Check relevant achievements for an event and grant newly-earned ones.
        Returns list of newly earned achievements (for client notification)."""
        newly_earned: list[dict] = []
        user_repo = UserRepository(self._db)
        user = await user_repo.get_by_id(user_id)
        if not user:
            return []

        candidates = self._get_candidates_for_event(event, user_id, user)

        for key in candidates:
            if await self._already_earned(user_id, key):
                continue
            ach = (await self._db.execute(
                select(Achievement).where(Achievement.key == key)
            )).scalar_one_or_none()
            if not ach:
                continue
            if await self._meets_requirement(user_id, key, user):
                ua = UserAchievement(
                    user_id=user_id,
                    achievement_id=ach.id,
                    earned_at=datetime.now(timezone.utc),
                )
                self._db.add(ua)
                await user_repo.add_xp(user, ach.xp_reward)
                newly_earned.append({"key": ach.key, "name": ach.name, "icon": ach.icon, "xp_reward": ach.xp_reward})

        await self._db.commit()
        return newly_earned

    async def get_user_achievements(self, user_id: str) -> list[dict]:
        result = await self._db.execute(
            select(UserAchievement, Achievement)
            .join(Achievement, UserAchievement.achievement_id == Achievement.id)
            .where(UserAchievement.user_id == user_id)
            .order_by(UserAchievement.earned_at.desc())
        )
        rows = result.all()
        return [
            {
                "key": ach.key, "name": ach.name, "description": ach.description,
                "category": ach.category.value, "xp_reward": ach.xp_reward,
                "icon": ach.icon, "earned_at": ua.earned_at.isoformat(),
            }
            for ua, ach in rows
        ]

    async def get_all_achievements(self, user_id: str) -> list[dict]:
        all_ach = (await self._db.execute(select(Achievement))).scalars().all()
        earned_keys = set()
        result = await self._db.execute(
            select(UserAchievement, Achievement)
            .join(Achievement)
            .where(UserAchievement.user_id == user_id)
        )
        earned_map: dict[str, str] = {}
        for ua, ach in result.all():
            earned_keys.add(ach.key)
            earned_map[ach.key] = ua.earned_at.isoformat()

        return [
            {
                "key": a.key, "name": a.name, "description": a.description,
                "category": a.category.value, "xp_reward": a.xp_reward,
                "icon": a.icon, "earned": a.key in earned_keys,
                "earned_at": earned_map.get(a.key),
            }
            for a in all_ach
        ]

    async def _already_earned(self, user_id: str, key: str) -> bool:
        ach = (await self._db.execute(
            select(Achievement).where(Achievement.key == key)
        )).scalar_one_or_none()
        if not ach:
            return False
        ua = (await self._db.execute(
            select(UserAchievement).where(
                UserAchievement.user_id == user_id,
                UserAchievement.achievement_id == ach.id,
            )
        )).scalar_one_or_none()
        return ua is not None

    def _get_candidates_for_event(self, event: str, user_id: str, user: User) -> list[str]:
        mapping: dict[str, list[str]] = {
            "habit_created": ["first_habit"],
            "habit_logged": ["streak_7", "streak_30", "streak_100"],
            "goal_created": ["first_goal"],
            "goal_completed": ["first_goal_complete"],
            "goal_session_logged": ["goal_session_5"],
            "ielts_session_logged": ["first_ielts_session"],
            "ielts_mock_test_logged": ["ielts_mock_test"],
            "vocab_added": ["vocab_50"],
            "mastery_session_logged": ["mastery_session_10", "mastery_session_50"],
            "social_logged": ["social_10", "social_50"],
            "workout_logged": ["workout_10", "workout_50"],
            "xp_added": ["level_5", "level_10", "level_25"],
            "pomodoro_logged": ["pomodoro_10", "pomodoro_100"],
            "morning_checkin": ["morning_checkin_7"],
            "note_created": ["note_10"],
            "paper_added": ["research_paper"],
            "snapshot_saved": ["snapshot_30"],
        }
        return mapping.get(event, [])

    async def _meets_requirement(self, user_id: str, key: str, user: User) -> bool:
        async def count(stmt) -> int:
            return (await self._db.execute(stmt)).scalar_one_or_none() or 0

        async def gt(stmt, n: int) -> bool:
            return (await count(stmt)) > n

        async def ge(stmt, n: int) -> bool:
            return (await count(stmt)) >= n

        checks: dict[str, Any] = {
            "first_habit": lambda: gt(select(func.count(Habit.id)).where(Habit.user_id == user_id), 0),
            "streak_7": lambda: ge(select(func.max(Habit.current_streak)).where(Habit.user_id == user_id), 7),
            "streak_30": lambda: ge(select(func.max(Habit.current_streak)).where(Habit.user_id == user_id), 30),
            "streak_100": lambda: ge(select(func.max(Habit.current_streak)).where(Habit.user_id == user_id), 100),
            "first_goal": lambda: gt(select(func.count(Goal.id)).where(Goal.user_id == user_id), 0),
            "first_goal_complete": lambda: gt(select(func.count(Goal.id)).where(Goal.user_id == user_id, Goal.status == GoalStatus.COMPLETED), 0),
            "goal_session_5": lambda: ge(select(func.count(GoalSession.id)).where(GoalSession.user_id == user_id), 5),
            "first_ielts_session": lambda: gt(select(func.count(IELTSStudySession.id)).where(IELTSStudySession.user_id == user_id), 0),
            "vocab_50": lambda: ge(select(func.count(VocabularyEntry.id)).where(VocabularyEntry.user_id == user_id), 50),
            "mastery_session_10": lambda: ge(select(func.count(MasteryStudySession.id)).where(MasteryStudySession.user_id == user_id), 10),
            "mastery_session_50": lambda: ge(select(func.count(MasteryStudySession.id)).where(MasteryStudySession.user_id == user_id), 50),
            "social_10": lambda: ge(select(func.count(SocialInteraction.id)).where(SocialInteraction.user_id == user_id), 10),
            "social_50": lambda: ge(select(func.count(SocialInteraction.id)).where(SocialInteraction.user_id == user_id), 50),
            "workout_10": lambda: ge(select(func.count(WorkoutSession.id)).where(WorkoutSession.user_id == user_id), 10),
            "workout_50": lambda: ge(select(func.count(WorkoutSession.id)).where(WorkoutSession.user_id == user_id), 50),
            "level_5": lambda: user.level >= 5,
            "level_10": lambda: user.level >= 10,
            "level_25": lambda: user.level >= 25,
            "pomodoro_10": lambda: ge(select(func.count(PomodoroSession.id)).where(PomodoroSession.user_id == user_id, PomodoroSession.is_completed.is_(True)), 10),
            "pomodoro_100": lambda: ge(select(func.count(PomodoroSession.id)).where(PomodoroSession.user_id == user_id, PomodoroSession.is_completed.is_(True)), 100),
            "morning_checkin_7": lambda: ge(select(func.count(DailySnapshot.id)).where(DailySnapshot.user_id == user_id, DailySnapshot.morning_checkin_done.is_(True)), 7),
            "snapshot_30": lambda: ge(select(func.count(DailySnapshot.id)).where(DailySnapshot.user_id == user_id), 30),
        }

        fn = checks.get(key)
        if fn is None:
            return False
        result = fn()
        if hasattr(result, "__await__"):
            result = await result
        return bool(result)
