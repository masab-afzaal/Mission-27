from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.namaz import NamazLog
from app.models.user import User
from app.repositories.user_repository import UserRepository

router = APIRouter(prefix="/namaz", tags=["namaz"])


class NamazUpdateRequest(BaseModel):
    fajr: bool = False
    dhuhr: bool = False
    asr: bool = False
    maghrib: bool = False
    isha: bool = False


class NamazResponse(BaseModel):
    log_date: date
    fajr: bool
    dhuhr: bool
    asr: bool
    maghrib: bool
    isha: bool
    count: int
    xp_earned: int

    model_config = {"from_attributes": True}


class NamazDayStats(BaseModel):
    date: date
    count: int


class NamazStatsResponse(BaseModel):
    days: list[NamazDayStats]
    total_prayers: int
    avg_per_day: float


async def _get_or_create_today(db: AsyncSession, user_id: str) -> NamazLog:
    today = date.today()
    log = (await db.execute(
        select(NamazLog).where(
            NamazLog.user_id == user_id,
            NamazLog.log_date == today,
        )
    )).scalar_one_or_none()
    if not log:
        log = NamazLog(user_id=user_id, log_date=today)
        db.add(log)
        await db.commit()
        await db.refresh(log)
    return log


@router.get("/today", response_model=NamazResponse)
async def get_today_namaz(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    log = await _get_or_create_today(db, str(current_user.id))
    count = sum([log.fajr, log.dhuhr, log.asr, log.maghrib, log.isha])
    return NamazResponse(
        log_date=log.log_date, fajr=log.fajr, dhuhr=log.dhuhr,
        asr=log.asr, maghrib=log.maghrib, isha=log.isha,
        count=count, xp_earned=log.xp_earned,
    )


@router.post("/log", response_model=NamazResponse)
async def update_namaz_log(
    body: NamazUpdateRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    uid = str(current_user.id)
    log = await _get_or_create_today(db, uid)

    old_count = sum([log.fajr, log.dhuhr, log.asr, log.maghrib, log.isha])

    # Guard: prevent unchecking prayers (once checked, cannot be unchecked)
    body.fajr = body.fajr or log.fajr
    body.dhuhr = body.dhuhr or log.dhuhr
    body.asr = body.asr or log.asr
    body.maghrib = body.maghrib or log.maghrib
    body.isha = body.isha or log.isha

    log.fajr = body.fajr
    log.dhuhr = body.dhuhr
    log.asr = body.asr
    log.maghrib = body.maghrib
    log.isha = body.isha

    new_count = sum([body.fajr, body.dhuhr, body.asr, body.maghrib, body.isha])
    new_prayers = max(0, new_count - old_count)
    if new_prayers > 0:
        xp_gained = new_prayers * 5
        log.xp_earned = (log.xp_earned or 0) + xp_gained
        await UserRepository(db).add_xp(current_user, xp_gained)

    await db.commit()
    await db.refresh(log)
    return NamazResponse(
        log_date=log.log_date, fajr=log.fajr, dhuhr=log.dhuhr,
        asr=log.asr, maghrib=log.maghrib, isha=log.isha,
        count=new_count, xp_earned=log.xp_earned,
    )


@router.get("/stats", response_model=NamazStatsResponse)
async def get_namaz_stats(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
    period: int = 30,
):
    today = date.today()
    since = today - timedelta(days=period - 1)

    logs = (await db.execute(
        select(NamazLog).where(
            NamazLog.user_id == str(current_user.id),
            NamazLog.log_date >= since,
            NamazLog.log_date <= today,
        ).order_by(NamazLog.log_date)
    )).scalars().all()

    by_date = {
        lg.log_date: sum([lg.fajr, lg.dhuhr, lg.asr, lg.maghrib, lg.isha])
        for lg in logs
    }

    days = [
        NamazDayStats(date=since + timedelta(days=i), count=by_date.get(since + timedelta(days=i), 0))
        for i in range(period)
    ]
    total = sum(s.count for s in days)
    return NamazStatsResponse(days=days, total_prayers=total, avg_per_day=round(total / period, 1))
