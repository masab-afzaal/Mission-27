"""Initial schema – all domain tables

Revision ID: 001
Revises:
Create Date: 2026-06-21
"""
from typing import Sequence, Union
import sqlalchemy as sa
from alembic import op

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── users ──────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("username", sa.String(50), nullable=False),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("full_name", sa.String(100), nullable=False),
        sa.Column("is_active", sa.Boolean(), default=True, nullable=False),
        sa.Column("is_verified", sa.Boolean(), default=False, nullable=False),
        sa.Column("xp_total", sa.Integer(), default=0, nullable=False),
        sa.Column("level", sa.Integer(), default=1, nullable=False),
        sa.Column("timezone", sa.String(50), default="UTC", nullable=False),
        sa.Column("work_start_hour", sa.Integer(), default=18, nullable=False),
        sa.Column("work_end_hour", sa.Integer(), default=3, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("email"),
        sa.UniqueConstraint("username"),
    )
    op.create_index("ix_users_email", "users", ["email"])
    op.create_index("ix_users_username", "users", ["username"])

    # ── goals ─────────────────────────────────────────────────────────────
    op.create_table(
        "goals",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("parent_goal_id", sa.String(36), sa.ForeignKey("goals.id", ondelete="SET NULL"), nullable=True),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("domain", sa.String(100), nullable=False),
        sa.Column("timeframe", sa.String(20), nullable=False),
        sa.Column("status", sa.String(20), default="not_started", nullable=False),
        sa.Column("priority", sa.String(20), default="medium", nullable=False),
        sa.Column("target_date", sa.Date(), nullable=True),
        sa.Column("progress_percent", sa.Float(), default=0.0, nullable=False),
        sa.Column("xp_reward", sa.Integer(), default=50, nullable=False),
        sa.Column("success_criteria", sa.Text(), nullable=True),
        sa.Column("completed_at", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_goals_user_id", "goals", ["user_id"])

    # ── milestones ────────────────────────────────────────────────────────
    op.create_table(
        "milestones",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("goal_id", sa.String(36), sa.ForeignKey("goals.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("is_completed", sa.Boolean(), default=False, nullable=False),
        sa.Column("order_index", sa.Integer(), default=0, nullable=False),
        sa.Column("completed_at", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_milestones_goal_id", "milestones", ["goal_id"])

    # ── habits ────────────────────────────────────────────────────────────
    op.create_table(
        "habits",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("category", sa.String(50), nullable=False),
        sa.Column("domain", sa.String(100), nullable=False),
        sa.Column("frequency", sa.String(20), default="daily", nullable=False),
        sa.Column("target_count_per_period", sa.Integer(), default=1, nullable=False),
        sa.Column("current_streak", sa.Integer(), default=0, nullable=False),
        sa.Column("longest_streak", sa.Integer(), default=0, nullable=False),
        sa.Column("total_completions", sa.Integer(), default=0, nullable=False),
        sa.Column("consistency_percent", sa.Float(), default=0.0, nullable=False),
        sa.Column("xp_per_completion", sa.Integer(), default=10, nullable=False),
        sa.Column("is_active", sa.Boolean(), default=True, nullable=False),
        sa.Column("custom_days", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_habits_user_id", "habits", ["user_id"])

    # ── habit_logs ────────────────────────────────────────────────────────
    op.create_table(
        "habit_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("habit_id", sa.String(36), sa.ForeignKey("habits.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("logged_date", sa.Date(), nullable=False),
        sa.Column("completed", sa.Boolean(), default=True, nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("xp_earned", sa.Integer(), default=0, nullable=False),
    )
    op.create_index("ix_habit_logs_habit_id", "habit_logs", ["habit_id"])
    op.create_index("ix_habit_logs_user_id", "habit_logs", ["user_id"])

    # ── ielts_profiles ────────────────────────────────────────────────────
    op.create_table(
        "ielts_profiles",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("target_band", sa.Float(), default=8.0, nullable=False),
        sa.Column("exam_date", sa.Date(), nullable=True),
        sa.Column("current_band_estimate", sa.Float(), default=0.0, nullable=False),
        sa.Column("readiness_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("reading_band", sa.Float(), default=0.0, nullable=False),
        sa.Column("listening_band", sa.Float(), default=0.0, nullable=False),
        sa.Column("writing_band", sa.Float(), default=0.0, nullable=False),
        sa.Column("speaking_band", sa.Float(), default=0.0, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── ielts_study_sessions ──────────────────────────────────────────────
    op.create_table(
        "ielts_study_sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("profile_id", sa.String(36), sa.ForeignKey("ielts_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("skill", sa.String(30), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column("session_date", sa.Date(), nullable=False),
        sa.Column("topics_covered", sa.JSON(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("quality_rating", sa.Integer(), default=3, nullable=False),
        sa.Column("xp_earned", sa.Integer(), default=0, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ielts_study_sessions_profile_id", "ielts_study_sessions", ["profile_id"])
    op.create_index("ix_ielts_study_sessions_user_id", "ielts_study_sessions", ["user_id"])

    # ── ielts_mock_tests ──────────────────────────────────────────────────
    op.create_table(
        "ielts_mock_tests",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("profile_id", sa.String(36), sa.ForeignKey("ielts_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("test_date", sa.Date(), nullable=False),
        sa.Column("reading_score", sa.Float(), nullable=True),
        sa.Column("listening_score", sa.Float(), nullable=True),
        sa.Column("writing_score", sa.Float(), nullable=True),
        sa.Column("speaking_score", sa.Float(), nullable=True),
        sa.Column("overall_band", sa.Float(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("weak_areas", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── vocabulary_entries ────────────────────────────────────────────────
    op.create_table(
        "vocabulary_entries",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("profile_id", sa.String(36), sa.ForeignKey("ielts_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("word", sa.String(100), nullable=False),
        sa.Column("definition", sa.Text(), nullable=False),
        sa.Column("example_sentence", sa.Text(), nullable=True),
        sa.Column("tags", sa.JSON(), nullable=True),
        sa.Column("mastery_level", sa.Integer(), default=0, nullable=False),
        sa.Column("next_review_date", sa.Date(), nullable=True),
        sa.Column("review_count", sa.Integer(), default=0, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── skill_areas ───────────────────────────────────────────────────────
    op.create_table(
        "skill_areas",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("domain", sa.String(30), nullable=False),
        sa.Column("name", sa.String(150), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("proficiency", sa.String(30), default="beginner", nullable=False),
        sa.Column("mastery_percent", sa.Float(), default=0.0, nullable=False),
        sa.Column("total_study_hours", sa.Float(), default=0.0, nullable=False),
        sa.Column("icon", sa.String(50), nullable=True),
        sa.Column("order_index", sa.Integer(), default=0, nullable=False),
        sa.Column("is_active", sa.Boolean(), default=True, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_skill_areas_user_id", "skill_areas", ["user_id"])

    # ── skill_topics ──────────────────────────────────────────────────────
    op.create_table(
        "skill_topics",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("skill_area_id", sa.String(36), sa.ForeignKey("skill_areas.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("is_completed", sa.Boolean(), default=False, nullable=False),
        sa.Column("confidence_level", sa.Integer(), default=0, nullable=False),
        sa.Column("retention_level", sa.Integer(), default=0, nullable=False),
        sa.Column("last_studied", sa.Date(), nullable=True),
        sa.Column("next_review", sa.Date(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("resources", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── mastery_study_sessions ────────────────────────────────────────────
    op.create_table(
        "mastery_study_sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("skill_area_id", sa.String(36), sa.ForeignKey("skill_areas.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("session_date", sa.Date(), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column("topics_covered", sa.JSON(), nullable=True),
        sa.Column("session_type", sa.String(50), default="study", nullable=False),
        sa.Column("quality_rating", sa.Integer(), default=3, nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("xp_earned", sa.Integer(), default=0, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── workout_sessions ──────────────────────────────────────────────────
    op.create_table(
        "workout_sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("workout_date", sa.Date(), nullable=False),
        sa.Column("workout_type", sa.String(30), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column("intensity_level", sa.Integer(), default=3, nullable=False),
        sa.Column("exercises", sa.JSON(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("energy_before", sa.Integer(), default=5, nullable=False),
        sa.Column("energy_after", sa.Integer(), default=5, nullable=False),
        sa.Column("xp_earned", sa.Integer(), default=0, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_workout_sessions_user_id", "workout_sessions", ["user_id"])

    # ── health_metrics ────────────────────────────────────────────────────
    op.create_table(
        "health_metrics",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("metric_date", sa.Date(), nullable=False),
        sa.Column("weight_kg", sa.Float(), nullable=True),
        sa.Column("body_fat_percent", sa.Float(), nullable=True),
        sa.Column("sleep_hours", sa.Float(), nullable=True),
        sa.Column("sleep_quality", sa.Integer(), nullable=True),
        sa.Column("energy_level", sa.Integer(), nullable=True),
        sa.Column("water_ml", sa.Integer(), nullable=True),
        sa.Column("mood_score", sa.Integer(), nullable=True),
        sa.Column("stress_level", sa.Integer(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── sports_activities ─────────────────────────────────────────────────
    op.create_table(
        "sports_activities",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("sport_name", sa.String(100), nullable=False),
        sa.Column("activity_date", sa.Date(), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column("location", sa.String(200), nullable=True),
        sa.Column("with_others", sa.Boolean(), default=False, nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("xp_earned", sa.Integer(), default=0, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── social_interactions ───────────────────────────────────────────────
    op.create_table(
        "social_interactions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("interaction_date", sa.Date(), nullable=False),
        sa.Column("interaction_type", sa.String(40), nullable=False),
        sa.Column("person_name", sa.String(100), nullable=True),
        sa.Column("duration_minutes", sa.Integer(), nullable=True),
        sa.Column("quality_rating", sa.Integer(), default=3, nullable=False),
        sa.Column("is_professional", sa.Boolean(), default=False, nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("xp_earned", sa.Integer(), default=0, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_social_interactions_user_id", "social_interactions", ["user_id"])

    # ── social_health_profiles ────────────────────────────────────────────
    op.create_table(
        "social_health_profiles",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("social_health_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("isolation_risk_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("weekly_interaction_target", sa.Integer(), default=5, nullable=False),
        sa.Column("professional_network_size", sa.Integer(), default=0, nullable=False),
        sa.Column("last_calculated_at", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── knowledge_notes ───────────────────────────────────────────────────
    op.create_table(
        "knowledge_notes",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(300), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("note_type", sa.String(40), nullable=False),
        sa.Column("domain", sa.String(100), nullable=True),
        sa.Column("tags", sa.JSON(), nullable=True),
        sa.Column("linked_note_ids", sa.JSON(), nullable=True),
        sa.Column("source_url", sa.String(500), nullable=True),
        sa.Column("is_pinned", sa.Boolean(), default=False, nullable=False),
        sa.Column("is_archived", sa.Boolean(), default=False, nullable=False),
        sa.Column("view_count", sa.Integer(), default=0, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_knowledge_notes_user_id", "knowledge_notes", ["user_id"])

    # ── research_papers ───────────────────────────────────────────────────
    op.create_table(
        "research_papers",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(500), nullable=False),
        sa.Column("authors", sa.JSON(), nullable=True),
        sa.Column("abstract", sa.Text(), nullable=True),
        sa.Column("url", sa.String(500), nullable=True),
        sa.Column("tags", sa.JSON(), nullable=True),
        sa.Column("is_read", sa.Boolean(), default=False, nullable=False),
        sa.Column("is_summarised", sa.Boolean(), default=False, nullable=False),
        sa.Column("personal_notes", sa.Text(), nullable=True),
        sa.Column("key_insights", sa.JSON(), nullable=True),
        sa.Column("date_read", sa.Date(), nullable=True),
        sa.Column("relevance_score", sa.Integer(), default=3, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── research_projects ─────────────────────────────────────────────────
    op.create_table(
        "research_projects",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(300), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("status", sa.String(50), default="planning", nullable=False),
        sa.Column("target_venue", sa.String(200), nullable=True),
        sa.Column("submission_deadline", sa.Date(), nullable=True),
        sa.Column("writing_progress_percent", sa.Integer(), default=0, nullable=False),
        sa.Column("tags", sa.JSON(), nullable=True),
        sa.Column("milestones", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── achievements ──────────────────────────────────────────────────────
    op.create_table(
        "achievements",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("key", sa.String(100), nullable=False, unique=True),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("category", sa.String(40), nullable=False),
        sa.Column("xp_reward", sa.Integer(), default=0, nullable=False),
        sa.Column("icon", sa.String(50), nullable=True),
        sa.Column("requirement", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── user_achievements ─────────────────────────────────────────────────
    op.create_table(
        "user_achievements",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("achievement_id", sa.String(36), sa.ForeignKey("achievements.id", ondelete="CASCADE"), nullable=False),
        sa.Column("earned_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_user_achievements_user_id", "user_achievements", ["user_id"])

    # ── xp_transactions ───────────────────────────────────────────────────
    op.create_table(
        "xp_transactions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("amount", sa.Integer(), nullable=False),
        sa.Column("source", sa.String(100), nullable=False),
        sa.Column("source_id", sa.String(36), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("earned_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_xp_transactions_user_id", "xp_transactions", ["user_id"])

    # ── identity_profiles ─────────────────────────────────────────────────
    op.create_table(
        "identity_profiles",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("identity_name", sa.String(100), nullable=False),
        sa.Column("strength_score", sa.Integer(), default=0, nullable=False),
        sa.Column("total_actions", sa.Integer(), default=0, nullable=False),
        sa.Column("icon", sa.String(50), nullable=True),
        sa.Column("color_hex", sa.String(7), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_identity_profiles_user_id", "identity_profiles", ["user_id"])

    # ── daily_snapshots ───────────────────────────────────────────────────
    op.create_table(
        "daily_snapshots",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("snapshot_date", sa.Date(), nullable=False),
        sa.Column("growth_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("consistency_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("goal_progress_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("learning_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("health_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("social_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("career_progress_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("ielts_readiness", sa.Float(), default=0.0, nullable=False),
        sa.Column("ai_readiness", sa.Float(), default=0.0, nullable=False),
        sa.Column("burnout_risk", sa.Float(), default=0.0, nullable=False),
        sa.Column("isolation_risk", sa.Float(), default=0.0, nullable=False),
        sa.Column("future_self_alignment", sa.Float(), default=0.0, nullable=False),
        sa.Column("study_minutes", sa.Integer(), default=0, nullable=False),
        sa.Column("exercise_minutes", sa.Integer(), default=0, nullable=False),
        sa.Column("social_minutes", sa.Integer(), default=0, nullable=False),
        sa.Column("xp_earned_today", sa.Integer(), default=0, nullable=False),
        sa.Column("habits_completed", sa.Integer(), default=0, nullable=False),
        sa.Column("habits_total", sa.Integer(), default=0, nullable=False),
        sa.Column("domain_breakdown", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_daily_snapshots_user_id", "daily_snapshots", ["user_id"])

    # ── weekly_reviews ────────────────────────────────────────────────────
    op.create_table(
        "weekly_reviews",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("week_start_date", sa.Date(), nullable=False),
        sa.Column("week_end_date", sa.Date(), nullable=False),
        sa.Column("summary", sa.Text(), nullable=True),
        sa.Column("achievements", sa.JSON(), nullable=True),
        sa.Column("failures", sa.JSON(), nullable=True),
        sa.Column("lessons_learned", sa.JSON(), nullable=True),
        sa.Column("next_week_priorities", sa.JSON(), nullable=True),
        sa.Column("avg_growth_score", sa.Float(), default=0.0, nullable=False),
        sa.Column("xp_earned", sa.Integer(), default=0, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_weekly_reviews_user_id", "weekly_reviews", ["user_id"])

    # ── obstacle_logs ─────────────────────────────────────────────────────
    op.create_table(
        "obstacle_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("log_date", sa.Date(), nullable=False),
        sa.Column("blocker_type", sa.String(100), nullable=False),
        sa.Column("affected_domain", sa.String(100), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("resolution", sa.Text(), nullable=True),
        sa.Column("severity", sa.Integer(), default=3, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_obstacle_logs_user_id", "obstacle_logs", ["user_id"])


def downgrade() -> None:
    for table in [
        "obstacle_logs", "weekly_reviews", "daily_snapshots",
        "identity_profiles", "xp_transactions", "user_achievements", "achievements",
        "research_projects", "research_papers", "knowledge_notes",
        "social_health_profiles", "social_interactions",
        "sports_activities", "health_metrics", "workout_sessions",
        "mastery_study_sessions", "skill_topics", "skill_areas",
        "vocabulary_entries", "ielts_mock_tests", "ielts_study_sessions", "ielts_profiles",
        "habit_logs", "habits", "milestones", "goals", "users",
    ]:
        op.drop_table(table)
