from fastapi import APIRouter

from app.api.v1.endpoints import (
    auth, health, dashboard, goals, ielts, habits,
    knowledge, coach, social, mastery,
    pomodoro, achievements, nudges, checkin,
    namaz, events, domino, identities, obstacles,
    tasks,
)

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(dashboard.router)
api_router.include_router(goals.router)
api_router.include_router(ielts.router)
api_router.include_router(habits.router)
api_router.include_router(knowledge.router)
api_router.include_router(coach.router)
api_router.include_router(social.router)
api_router.include_router(mastery.router)
api_router.include_router(pomodoro.router)
api_router.include_router(achievements.router)
api_router.include_router(nudges.router)
api_router.include_router(checkin.router)
api_router.include_router(namaz.router)
api_router.include_router(events.router)
api_router.include_router(domino.router)
api_router.include_router(identities.router)
api_router.include_router(obstacles.router)
api_router.include_router(tasks.router)
