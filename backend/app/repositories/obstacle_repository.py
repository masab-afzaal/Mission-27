from datetime import date
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.analytics import ObstacleLog
from app.repositories.base import BaseRepository


class ObstacleRepository(BaseRepository[ObstacleLog]):
    def __init__(self, session: AsyncSession) -> None:
        super().__init__(ObstacleLog, session)

    async def get_by_user(self, user_id: str, limit: int = 50, offset: int = 0) -> list[ObstacleLog]:
        stmt = (
            select(ObstacleLog)
            .where(ObstacleLog.user_id == user_id)
            .order_by(ObstacleLog.log_date.desc())
            .offset(offset)
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def get_active_blockers(self, user_id: str) -> list[ObstacleLog]:
        stmt = (
            select(ObstacleLog)
            .where(
                and_(
                    ObstacleLog.user_id == user_id,
                    (ObstacleLog.resolution == None) | (ObstacleLog.resolution == "")
                )
            )
            .order_by(ObstacleLog.log_date.desc())
        )
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def resolve_obstacle(self, obstacle_id: str, user_id: str, resolution: str) -> ObstacleLog | None:
        stmt = select(ObstacleLog).where(
            and_(ObstacleLog.id == obstacle_id, ObstacleLog.user_id == user_id)
        )
        obstacle = (await self._session.execute(stmt)).scalar_one_or_none()
        if not obstacle:
            return None
        obstacle.resolution = resolution
        await self._session.flush()
        return obstacle
