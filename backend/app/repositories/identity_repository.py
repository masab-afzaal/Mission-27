from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.gamification import IdentityProfile
from app.repositories.base import BaseRepository


class IdentityRepository(BaseRepository[IdentityProfile]):
    def __init__(self, session: AsyncSession) -> None:
        super().__init__(IdentityProfile, session)

    async def get_by_user(self, user_id: str) -> list[IdentityProfile]:
        stmt = select(IdentityProfile).where(IdentityProfile.user_id == user_id)
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def get_by_user_and_name(self, user_id: str, identity_name: str) -> IdentityProfile | None:
        stmt = select(IdentityProfile).where(
            IdentityProfile.user_id == user_id,
            IdentityProfile.identity_name == identity_name
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def record_action(self, user_id: str, identity_name: str, count: int = 1) -> IdentityProfile | None:
        """Increment action count for an identity and dynamically update its strength score."""
        identity = await self.get_by_user_and_name(user_id, identity_name)
        if not identity:
            return None
        
        identity.total_actions += count
        # dynamic progression: strength climbs steadily and plateaus at 100
        identity.strength_score = min(100, int(identity.total_actions * 2.5))
        await self._session.flush()
        return identity
