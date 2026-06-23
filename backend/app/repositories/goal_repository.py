from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.goal import Goal, GoalStatus, GoalTimeframe, Milestone
from app.repositories.base import BaseRepository


class GoalRepository(BaseRepository[Goal]):
    def __init__(self, session: AsyncSession) -> None:
        super().__init__(Goal, session)

    async def get_user_goals(
        self,
        user_id: str,
        timeframe: GoalTimeframe | None = None,
        status: GoalStatus | None = None,
    ) -> list[Goal]:
        stmt = (
            select(Goal)
            .options(selectinload(Goal.milestones))
            .where(Goal.user_id == user_id)
        )
        if timeframe:
            stmt = stmt.where(Goal.timeframe == timeframe)
        if status:
            stmt = stmt.where(Goal.status == status)
        stmt = stmt.order_by(Goal.priority, Goal.created_at.desc())
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def get_with_milestones(self, goal_id: str) -> Goal | None:
        stmt = (
            select(Goal)
            .options(selectinload(Goal.milestones))
            .where(Goal.id == goal_id)
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def complete_milestone(self, milestone_id: str) -> Milestone | None:
        from datetime import date
        stmt = select(Milestone).where(Milestone.id == milestone_id)
        result = await self._session.execute(stmt)
        milestone = result.scalar_one_or_none()
        if milestone:
            milestone.is_completed = True
            milestone.completed_at = date.today()
            await self._session.flush()
        return milestone
