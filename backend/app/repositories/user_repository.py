from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    def __init__(self, session: AsyncSession) -> None:
        super().__init__(User, session)

    async def get_by_email(self, email: str) -> User | None:
        stmt = select(User).where(User.email == email.lower())
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_username(self, username: str) -> User | None:
        stmt = select(User).where(User.username == username.lower())
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def email_exists(self, email: str) -> bool:
        user = await self.get_by_email(email)
        return user is not None

    async def username_exists(self, username: str) -> bool:
        user = await self.get_by_username(username)
        return user is not None

    async def add_xp(self, user: User, points: int) -> User:
        user.xp_total += points
        user.level = self._calculate_level(user.xp_total)
        await self._session.flush()
        return user

    @staticmethod
    def _calculate_level(xp: int) -> int:
        """Level = floor(sqrt(xp / 100)) + 1, capped at 100."""
        import math
        return min(100, int(math.sqrt(xp / 100)) + 1)
