from datetime import date
from pydantic import BaseModel


class ScoreBundleResponse(BaseModel):
    growth_score: float
    consistency_score: float
    goal_progress_score: float
    learning_score: float
    health_score: float
    social_score: float
    career_progress_score: float
    ielts_readiness: float
    ai_readiness: float
    burnout_risk: float
    isolation_risk: float
    future_self_alignment: float


class DailySnapshotResponse(ScoreBundleResponse):
    snapshot_date: date
    study_minutes: int
    exercise_minutes: int
    social_minutes: int
    xp_earned_today: int
    habits_completed: int
    habits_total: int
    domain_breakdown: dict | None = None

    model_config = {"from_attributes": True}


class DashboardSummaryResponse(BaseModel):
    today: ScoreBundleResponse
    last_7_days: list[DailySnapshotResponse]
    active_streaks: list[dict]
    neglected_domains: list[str]
    user_level: int
    user_xp: int
