from datetime import date, timedelta

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.habit import Habit, HabitLog
from app.repositories.user_repository import UserRepository
from app.schemas.habits import HabitCreate, HabitLogCreate, HabitLogResponse, HabitResponse, TodayHabitStatus


class HabitService:
    def __init__(self, session: AsyncSession) -> None:
        self._db = session
        self._user_repo = UserRepository(session)

    async def create_habit(self, user_id: str, payload: HabitCreate) -> HabitResponse:
        habit = Habit(
            user_id=user_id,
            name=payload.name,
            description=payload.description,
            category=payload.category,
            domain=payload.domain,
            frequency=payload.frequency,
            target_count_per_period=payload.target_count_per_period,
            xp_per_completion=payload.xp_per_completion,
        )
        self._db.add(habit)
        await self._db.flush()
        return HabitResponse.model_validate(habit)

    async def get_habits(self, user_id: str, active_only: bool = True) -> list[HabitResponse]:
        stmt = select(Habit).where(Habit.user_id == user_id)
        if active_only:
            stmt = stmt.where(Habit.is_active.is_(True))
        stmt = stmt.order_by(Habit.created_at.desc())
        habits = (await self._db.execute(stmt)).scalars().all()
        return [HabitResponse.model_validate(h) for h in habits]

    async def get_today_habits(self, user_id: str) -> list[TodayHabitStatus]:
        today = date.today()
        habits_stmt = select(Habit).where(Habit.user_id == user_id, Habit.is_active.is_(True))
        habits = (await self._db.execute(habits_stmt)).scalars().all()

        logs_stmt = select(HabitLog).where(
            HabitLog.user_id == user_id,
            HabitLog.logged_date == today,
        )
        logs = {log.habit_id: log for log in (await self._db.execute(logs_stmt)).scalars().all()}

        return [
            TodayHabitStatus(
                habit=HabitResponse.model_validate(h),
                completed_today=h.id in logs and logs[h.id].completed,
                log_id=logs[h.id].id if h.id in logs else None,
            )
            for h in habits
        ]

    async def log_habit(self, user_id: str, habit_id: str, payload: HabitLogCreate) -> HabitLogResponse:
        stmt = select(Habit).where(Habit.id == habit_id, Habit.user_id == user_id)
        habit = (await self._db.execute(stmt)).scalar_one_or_none()
        if not habit:
            from fastapi import HTTPException, status
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Habit not found")

        existing_stmt = select(HabitLog).where(
            and_(HabitLog.habit_id == habit_id, HabitLog.logged_date == payload.logged_date)
        )
        existing = (await self._db.execute(existing_stmt)).scalar_one_or_none()
        if existing:
            existing.completed = payload.completed
            existing.note = payload.note
            return HabitLogResponse.model_validate(existing)

        xp = habit.xp_per_completion if payload.completed else 0
        log = HabitLog(
            habit_id=habit_id,
            user_id=user_id,
            logged_date=payload.logged_date,
            completed=payload.completed,
            note=payload.note,
            xp_earned=xp,
        )
        self._db.add(log)
        await self._db.flush()

        if payload.completed:
            await self._update_streak(habit, payload.logged_date)
            user = await self._user_repo.get_by_id(user_id)
            if user:
                await self._user_repo.add_xp(user, xp)

        return HabitLogResponse.model_validate(log)

    async def _update_streak(self, habit: Habit, logged_date: date) -> None:
        yesterday = logged_date - timedelta(days=1)
        yesterday_stmt = select(HabitLog).where(
            and_(HabitLog.habit_id == habit.id, HabitLog.logged_date == yesterday, HabitLog.completed.is_(True))
        )
        yesterday_log = (await self._db.execute(yesterday_stmt)).scalar_one_or_none()

        if yesterday_log:
            habit.current_streak += 1
        else:
            habit.current_streak = 1

        habit.longest_streak = max(habit.longest_streak, habit.current_streak)
        habit.total_completions += 1
        await self._update_consistency(habit)

    async def _update_consistency(self, habit: Habit) -> None:
        days_tracked = 30
        start = date.today() - timedelta(days=days_tracked)
        stmt = select(HabitLog).where(
            and_(HabitLog.habit_id == habit.id, HabitLog.logged_date >= start, HabitLog.completed.is_(True))
        )
        logs = (await self._db.execute(stmt)).scalars().all()
        habit.consistency_percent = round((len(logs) / days_tracked) * 100, 1)
