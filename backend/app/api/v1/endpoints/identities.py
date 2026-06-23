from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.gamification import IdentityProfile
from app.models.user import User
from app.repositories.identity_repository import IdentityRepository
from app.schemas.gamification import IdentityCreate, IdentityResponse, ActionLogRequest

router = APIRouter(prefix="/identities", tags=["identities"])


@router.get("", response_model=list[IdentityResponse])
async def get_identities(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db)
):
    repo = IdentityRepository(db)
    return await repo.get_by_user(str(current_user.id))


@router.post("", response_model=IdentityResponse, status_code=status.HTTP_201_CREATED)
async def create_identity(
    body: IdentityCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db)
):
    repo = IdentityRepository(db)
    
    # Check if identity already exists
    existing = await repo.get_by_user_and_name(str(current_user.id), body.identity_name)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Identity profile '{body.identity_name}' already exists."
        )

    new_identity = IdentityProfile(
        user_id=str(current_user.id),
        identity_name=body.identity_name,
        icon=body.icon,
        color_hex=body.color_hex,
        strength_score=0,
        total_actions=0
    )
    return await repo.create(new_identity)


@router.post("/{identity_id}/action", response_model=IdentityResponse)
async def log_identity_action(
    identity_id: str,
    body: ActionLogRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db)
):
    repo = IdentityRepository(db)
    identity = await repo.get_by_id(identity_id)
    if not identity or identity.user_id != str(current_user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Identity profile not found."
        )

    updated = await repo.record_action(str(current_user.id), identity.identity_name, body.count)
    await db.commit()
    await db.refresh(updated)
    return updated
