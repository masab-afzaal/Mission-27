import structlog
from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator
from datetime import date, datetime, timezone

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import ORJSONResponse
from sqlalchemy import select

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import AsyncSessionLocal

logger = structlog.get_logger()
scheduler = AsyncIOScheduler()


async def _save_daily_snapshots() -> None:
    """Midnight cron: compute and persist DailySnapshot for all active users."""
    from app.models.user import User
    from app.models.analytics import DailySnapshot
    from app.services.score_engine import ScoreEngine

    today = date.today()
    async with AsyncSessionLocal() as db:
        users = (await db.execute(select(User).where(User.is_active.is_(True)))).scalars().all()
        for user in users:
            existing = (await db.execute(
                select(DailySnapshot).where(
                    DailySnapshot.user_id == str(user.id),
                    DailySnapshot.snapshot_date == today,
                )
            )).scalar_one_or_none()

            engine = ScoreEngine(db, str(user.id))
            scores = await engine.compute(target_date=today)

            if existing:
                # Update scores but preserve morning check-in data
                existing.growth_score = scores.growth_score
                existing.consistency_score = scores.consistency_score
                existing.goal_progress_score = scores.goal_progress_score
                existing.learning_score = scores.learning_score
                existing.health_score = scores.health_score
                existing.social_score = scores.social_score
                existing.career_progress_score = scores.career_progress_score
                existing.ielts_readiness = scores.ielts_readiness
                existing.ai_readiness = scores.ai_readiness
                existing.burnout_risk = scores.burnout_risk
                existing.isolation_risk = scores.isolation_risk
                existing.future_self_alignment = scores.future_self_alignment
            else:
                snapshot = DailySnapshot(
                    user_id=str(user.id),
                    snapshot_date=today,
                    growth_score=scores.growth_score,
                    consistency_score=scores.consistency_score,
                    goal_progress_score=scores.goal_progress_score,
                    learning_score=scores.learning_score,
                    health_score=scores.health_score,
                    social_score=scores.social_score,
                    career_progress_score=scores.career_progress_score,
                    ielts_readiness=scores.ielts_readiness,
                    ai_readiness=scores.ai_readiness,
                    burnout_risk=scores.burnout_risk,
                    isolation_risk=scores.isolation_risk,
                    future_self_alignment=scores.future_self_alignment,
                )
                db.add(snapshot)

        await db.commit()
        logger.info("Daily snapshots saved", users=len(users), date=str(today))

    # Grant snapshot achievements
    async with AsyncSessionLocal() as db:
        from app.services.achievement_service import AchievementService
        for user in users:
            await AchievementService(db).check_and_grant(str(user.id), "snapshot_saved")


async def _generate_weekly_review() -> None:
    """Sunday 8pm cron: generate AI-powered weekly review for all users."""
    import os
    from datetime import timedelta
    from app.models.user import User
    from app.models.analytics import DailySnapshot, WeeklyReview
    from sqlalchemy import func

    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        logger.warning("ANTHROPIC_API_KEY not set — skipping weekly AI review")
        return

    try:
        import anthropic
        client = anthropic.Anthropic(api_key=api_key)
    except ImportError:
        logger.warning("anthropic package not installed — skipping weekly review")
        return

    today = date.today()
    week_start = today - timedelta(days=7)
    week_end = today

    async with AsyncSessionLocal() as db:
        users = (await db.execute(select(User).where(User.is_active.is_(True)))).scalars().all()
        for user in users:
            # Get week's snapshots
            snaps = (await db.execute(
                select(DailySnapshot)
                .where(DailySnapshot.user_id == str(user.id),
                       DailySnapshot.snapshot_date.between(week_start, week_end))
                .order_by(DailySnapshot.snapshot_date)
            )).scalars().all()

            if not snaps:
                continue

            avg_growth = sum(s.growth_score for s in snaps) / len(snaps)

            # Build context for Claude
            snap_summary = "\n".join([
                f"{s.snapshot_date}: growth={s.growth_score:.0f}, consistency={s.consistency_score:.0f}, "
                f"learning={s.learning_score:.0f}, health={s.health_score:.0f}, "
                f"social={s.social_score:.0f}, goals={s.goal_progress_score:.0f}"
                for s in snaps
            ])

            try:
                message = client.messages.create(
                    model="claude-haiku-4-5-20251001",
                    max_tokens=400,
                    messages=[{
                        "role": "user",
                        "content": f"""You are a personal growth coach. Analyze this week's performance data for {user.full_name}:

{snap_summary}

Write a brief weekly review (150-200 words) covering:
1. What domain they dominated this week
2. What slipped and why it matters
3. One specific pattern you noticed
4. Three concrete priorities for next week

Be direct, personal, and specific to the data. No generic advice."""
                    }]
                )
                summary = message.content[0].text
            except Exception as e:
                logger.error("Claude weekly review failed", error=str(e), user=str(user.id))
                continue

            review = WeeklyReview(
                user_id=str(user.id),
                week_start_date=week_start,
                week_end_date=week_end,
                summary=summary,
                avg_growth_score=round(avg_growth, 1),
                ai_generated=True,
            )
            db.add(review)

        await db.commit()
        logger.info("Weekly AI reviews generated", users=len(users))


async def _seed_achievements() -> None:
    """Seed achievement definitions on startup."""
    from app.services.achievement_service import AchievementService
    async with AsyncSessionLocal() as db:
        await AchievementService(db).seed_achievements()
    logger.info("Achievements seeded")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    logger.info("Mission 27 API starting", env=settings.ENVIRONMENT)

    # Seed achievements
    await _seed_achievements()

    # Schedule cron jobs
    scheduler.add_job(_save_daily_snapshots, CronTrigger(hour=23, minute=59))
    scheduler.add_job(_generate_weekly_review, CronTrigger(day_of_week="sun", hour=20, minute=0))
    scheduler.start()
    logger.info("Scheduler started: daily snapshot + Sunday AI review")

    yield

    scheduler.shutdown()
    logger.info("Mission 27 API shutting down")


def create_application() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        debug=settings.DEBUG,
        default_response_class=ORJSONResponse,
        lifespan=lifespan,
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router)
    return app


app = create_application()
