from datetime import date
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.analytics import ObstacleLog
from app.models.user import User
from app.repositories.obstacle_repository import ObstacleRepository
from app.schemas.analytics import ObstacleCreate, ObstacleResponse, ObstacleResolve

router = APIRouter(prefix="/obstacles", tags=["obstacles"])


@router.get("", response_model=list[ObstacleResponse])
async def get_obstacles(
    current_user: Annotated[User, Depends(get_current_user)],
    active_only: bool = False,
    db: AsyncSession = Depends(get_db)
):
    repo = ObstacleRepository(db)
    if active_only:
        return await repo.get_active_blockers(str(current_user.id))
    return await repo.get_by_user(str(current_user.id))


@router.post("", response_model=ObstacleResponse, status_code=status.HTTP_201_CREATED)
async def log_obstacle(
    body: ObstacleCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db)
):
    repo = ObstacleRepository(db)
    new_obstacle = ObstacleLog(
        user_id=str(current_user.id),
        log_date=date.today(),
        blocker_type=body.blocker_type,
        affected_domain=body.affected_domain,
        description=body.description,
        severity=body.severity,
        resolution=None
    )
    return await repo.create(new_obstacle)


@router.post("/{obstacle_id}/resolve", response_model=ObstacleResponse)
async def resolve_obstacle(
    obstacle_id: str,
    body: ObstacleResolve,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db)
):
    repo = ObstacleRepository(db)
    obstacle = await repo.get_by_id(obstacle_id)
    if not obstacle or obstacle.user_id != str(current_user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Obstacle log not found."
        )

    updated = await repo.resolve_obstacle(obstacle_id, str(current_user.id), body.resolution)
    await db.commit()
    await db.refresh(updated)
    return updated
