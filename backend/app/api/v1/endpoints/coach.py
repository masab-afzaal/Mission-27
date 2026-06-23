from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.score_engine import ScoreEngine

router = APIRouter(prefix="/coach", tags=["ai_coach"])


@router.get("/report")
async def get_coach_report(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    engine = ScoreEngine(db, current_user.id)
    scores = await engine.compute()

    insights = []
    strengths = []
    growth_areas = []
    recommendations = []

    # Consistency insights
    if scores.consistency_score >= 80:
        strengths.append("Exceptional consistency — your daily habits are rock-solid.")
    elif scores.consistency_score < 40:
        insights.append({
            "category": "consistency",
            "title": "Consistency needs work",
            "message": f"Your consistency is at {scores.consistency_score:.0f}%. Focus on completing your daily habits before adding new ones.",
            "priority": "high",
        })
        growth_areas.append("Daily habit consistency")

    # Learning insights
    if scores.learning_score >= 70:
        strengths.append("Strong learning momentum — you're investing in your skills daily.")
    elif scores.learning_score < 30:
        growth_areas.append("Learning time investment")
        recommendations.append("Block 2 hours daily for focused learning (IELTS + AI Engineering).")

    # Health insights
    if scores.burnout_risk >= 60:
        insights.append({
            "category": "wellbeing",
            "title": "Burnout risk is high",
            "message": f"Burnout risk is at {scores.burnout_risk:.0f}%. Prioritize sleep, exercise, and recovery.",
            "priority": "high",
        })
        recommendations.append("Reduce workload by 20%, increase sleep to 7.5+ hours, and get at least 3 workouts this week.")

    if scores.health_score < 40:
        growth_areas.append("Physical health & recovery")
        recommendations.append("Aim for 3 gym sessions + 1 sports activity this week.")

    # Social insights
    if scores.isolation_risk >= 60:
        insights.append({
            "category": "social",
            "title": "Social isolation risk detected",
            "message": f"You haven't been engaging much socially. Remote work makes this worse. Reach out to at least 3 people this week.",
            "priority": "medium",
        })
        growth_areas.append("Social engagement")

    # IELTS
    if scores.ielts_readiness < 40:
        recommendations.append("Dedicate at least 90 min/day to IELTS — prioritize Speaking and Writing as these take the longest to improve.")

    # AI Engineering
    if scores.ai_readiness < 50:
        recommendations.append("Build one end-to-end AI project this month. Applied practice accelerates mastery faster than study alone.")

    # Goal progress
    if scores.goal_progress_score < 30:
        insights.append({
            "category": "goals",
            "title": "Goal progress is slow",
            "message": "Your goals are under 30% progress. Break them into smaller weekly milestones.",
            "priority": "medium",
        })

    # Future alignment
    if scores.future_self_alignment >= 70:
        strengths.append(f"Your daily actions align well with your long-term vision ({scores.future_self_alignment:.0f}%).")

    return {
        "insights": insights,
        "strengths": strengths,
        "growth_areas": growth_areas,
        "recommendations": recommendations,
        "overall_alignment": scores.future_self_alignment,
    }


from pydantic import BaseModel, Field

class ChatMessage(BaseModel):
    role: str
    content: str

class CoachChatRequest(BaseModel):
    message: str
    history: list[ChatMessage] = []


@router.post("/chat")
async def coach_chat(
    body: CoachChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    import os
    import httpx
    from sqlalchemy import select
    from app.services.score_engine import ScoreEngine
    from app.models.habit import Habit
    from app.models.goal import Goal, GoalStatus
    from app.repositories.obstacle_repository import ObstacleRepository

    api_key = settings.GROQ_API_KEY or os.getenv("GROQ_API_KEY")
    if not api_key:
        return {
            "reply": "Groq API Key is not configured. Please set the GROQ_API_KEY environment variable on the backend to enable conversational coaching!"
        }

    # Fetch context metrics
    engine = ScoreEngine(db, current_user.id)
    scores = await engine.compute()

    # Get active habits
    habits = (await db.execute(
        select(Habit).where(Habit.user_id == current_user.id, Habit.is_active.is_(True))
    )).scalars().all()

    # Get active goals
    goals = (await db.execute(
        select(Goal).where(
            Goal.user_id == current_user.id,
            Goal.status.notin_([GoalStatus.CANCELLED, GoalStatus.COMPLETED])
        )
    )).scalars().all()

    # Get active obstacles
    obs_repo = ObstacleRepository(db)
    obstacles = await obs_repo.get_active_blockers(current_user.id)

    # Build system prompt context
    system_prompt = f"""You are a professional, direct, and supportive personal growth coach in the 'Mission 27' application.
The user's name is {current_user.full_name}.
Current Level: {current_user.level} (Total XP: {current_user.xp_total})

Current Growth Performance Scores (0-100 scale):
- Growth Score: {scores.growth_score:.1f} (overall metric)
- Consistency: {scores.consistency_score:.1f}
- Goal Progress: {scores.goal_progress_score:.1f}
- Learning: {scores.learning_score:.1f}
- Health & Recovery: {scores.health_score:.1f}
- Social Engagement: {scores.social_score:.1f}
- Career Progress: {scores.career_progress_score:.1f}
- IELTS Readiness: {scores.ielts_readiness:.1f}
- AI Engineering Readiness: {scores.ai_readiness:.1f}
- Burnout Risk: {scores.burnout_risk:.1f}
- Isolation Risk: {scores.isolation_risk:.1f}
- Future Self Alignment: {scores.future_self_alignment:.1f}

Active Habits:
"""
    if habits:
        for h in habits:
            system_prompt += f"- {h.name} ({h.domain}) — Current Streak: {h.current_streak} days\n"
    else:
        system_prompt += "- None logged yet\n"

    system_prompt += "\nActive Goals:\n"
    if goals:
        for g in goals:
            system_prompt += f"- {g.title} ({g.domain}): {g.progress_percent}% progress. Target end date: {g.target_date or 'N/A'}\n"
    else:
        system_prompt += "- None logged yet\n"

    if obstacles:
        system_prompt += "\nActive Obstacles / Roadblocks:\n"
        for o in obstacles:
            system_prompt += f"- {o.blocker_type} affecting {o.affected_domain or 'general'}: {o.description or ''} (Severity: {o.severity}/5)\n"

    system_prompt += """
Keep your replies conversational, constructive, and action-oriented. Offer specific advice based on the user's scores, habits, and obstacles. Do not give generic advice. Keep answers relatively concise (100-200 words) so they are easy to read in a mobile interface."""

    messages = [{"role": "system", "content": system_prompt}]
    for msg in body.history:
        messages.append({"role": msg.role, "content": msg.content})
    messages.append({"role": "user", "content": body.message})

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "llama-3.1-70b-versatile",
        "messages": messages,
        "max_tokens": 600,
        "temperature": 0.7,
    }

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.GROQ_BASE_URL.rstrip('/')}/chat/completions",
                json=payload,
                headers=headers,
                timeout=30.0
            )
            response.raise_for_status()
            res_data = response.json()
            return {"reply": res_data["choices"][0]["message"]["content"]}
    except Exception as e:
        # Try fallback model llama-3.1-8b-instant
        try:
            payload["model"] = "llama-3.1-8b-instant"
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{settings.GROQ_BASE_URL.rstrip('/')}/chat/completions",
                    json=payload,
                    headers=headers,
                    timeout=30.0
                )
                response.raise_for_status()
                res_data = response.json()
                return {"reply": res_data["choices"][0]["message"]["content"]}
        except Exception as inner_e:
            return {"reply": f"AI Coach service is currently experiencing issues: {str(e)}. Please check your GROQ_API_KEY settings."}

