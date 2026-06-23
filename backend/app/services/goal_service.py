from datetime import date

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.goal import Goal, GoalStatus, GoalTimeframe, Milestone
from app.repositories.goal_repository import GoalRepository
from app.repositories.user_repository import UserRepository
from app.schemas.goals import GoalCreate, GoalResponse, GoalUpdate


class GoalService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = GoalRepository(session)
        self._user_repo = UserRepository(session)

    async def create_goal(self, user_id: str, payload: GoalCreate) -> GoalResponse:
        goal = Goal(
            user_id=user_id,
            title=payload.title,
            description=payload.description,
            domain=payload.domain,
            timeframe=payload.timeframe,
            priority=payload.priority,
            target_date=payload.target_date,
            success_criteria=payload.success_criteria,
            xp_reward=payload.xp_reward,
            parent_goal_id=payload.parent_goal_id,
        )
        goal = await self._repo.create(goal)

        for i, ms in enumerate(payload.milestones):
            milestone = Milestone(
                goal_id=goal.id,
                title=ms.title,
                order_index=ms.order_index or i,
            )
            self._repo._session.add(milestone)

        await self._repo._session.flush()

        # Re-fetch with eager-loaded milestones to avoid lazy-load in Pydantic validate
        goal = await self._repo.get_with_milestones(goal.id)
        return GoalResponse.model_validate(goal)

    async def list_goals(
        self,
        user_id: str,
        timeframe: GoalTimeframe | None = None,
        status: GoalStatus | None = None,
    ) -> list[GoalResponse]:
        goals = await self._repo.get_user_goals(user_id, timeframe=timeframe, status=status)
        return [GoalResponse.model_validate(g) for g in goals]

    async def update_goal(self, user_id: str, goal_id: str, payload: GoalUpdate) -> GoalResponse:
        goal = await self._repo.get_with_milestones(goal_id)
        if not goal or goal.user_id != user_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")

        for field, value in payload.model_dump(exclude_unset=True).items():
            setattr(goal, field, value)

        if payload.status == GoalStatus.COMPLETED:
            goal.completed_at = date.today()
            user = await self._user_repo.get_by_id(user_id)
            if user:
                await self._user_repo.add_xp(user, goal.xp_reward)

        return GoalResponse.model_validate(goal)

    async def delete_goal(self, user_id: str, goal_id: str) -> None:
        goal = await self._repo.get_by_id(goal_id)
        if not goal or goal.user_id != user_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
        await self._repo.delete(goal)

    async def complete_milestone(self, user_id: str, goal_id: str, milestone_id: str) -> GoalResponse:
        goal = await self._repo.get_with_milestones(goal_id)
        if not goal or goal.user_id != user_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")

        await self._repo.complete_milestone(milestone_id)
        completed = sum(1 for m in goal.milestones if m.is_completed)
        total = len(goal.milestones)
        if total > 0:
            goal.progress_percent = (completed / total) * 100

        return GoalResponse.model_validate(goal)
