"""Add new features: pomodoro, goal sessions, user enhancements, SM-2, morning check-in

Revision ID: 002
Revises: 001
Create Date: 2026-06-22
"""
from typing import Sequence, Union
import sqlalchemy as sa
from alembic import op

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── users: add streak_shield_tokens + fcm_token ──────────────────────
    op.add_column("users", sa.Column("streak_shield_tokens", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("users", sa.Column("fcm_token", sa.String(500), nullable=True))

    # ── habits: add linked_goal_id ─────────────────────────────────────────
    op.add_column("habits", sa.Column("linked_goal_id", sa.String(36), nullable=True))
    op.create_foreign_key("fk_habits_linked_goal_id", "habits", "goals", ["linked_goal_id"], ["id"], ondelete="SET NULL")

    # ── vocabulary_entries: add SM-2 fields ────────────────────────────────
    op.add_column("vocabulary_entries", sa.Column("ease_factor", sa.Float(), nullable=False, server_default="2.5"))
    op.add_column("vocabulary_entries", sa.Column("interval_days", sa.Integer(), nullable=False, server_default="1"))
    op.add_column("vocabulary_entries", sa.Column("last_review_date", sa.Date(), nullable=True))

    # ── daily_snapshots: add morning check-in fields ───────────────────────
    op.add_column("daily_snapshots", sa.Column("morning_checkin_done", sa.Boolean(), nullable=False, server_default="false"))
    op.add_column("daily_snapshots", sa.Column("morning_mood", sa.Integer(), nullable=True))
    op.add_column("daily_snapshots", sa.Column("morning_energy", sa.Integer(), nullable=True))
    op.add_column("daily_snapshots", sa.Column("morning_intentions", sa.JSON(), nullable=True))

    # ── weekly_reviews: add ai_generated flag ─────────────────────────────
    op.add_column("weekly_reviews", sa.Column("ai_generated", sa.Boolean(), nullable=False, server_default="false"))

    # ── goal_sessions ─────────────────────────────────────────────────────
    op.create_table(
        "goal_sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("goal_id", sa.String(36), sa.ForeignKey("goals.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("session_date", sa.Date(), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column("what_i_did", sa.Text(), nullable=False),
        sa.Column("progress_made", sa.Float(), nullable=False, server_default="0"),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("xp_earned", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_goal_sessions_goal_id", "goal_sessions", ["goal_id"])
    op.create_index("ix_goal_sessions_user_id", "goal_sessions", ["user_id"])

    # ── pomodoro_sessions ─────────────────────────────────────────────────
    op.create_table(
        "pomodoro_sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("session_date", sa.Date(), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("work_minutes", sa.Integer(), nullable=False, server_default="25"),
        sa.Column("break_minutes", sa.Integer(), nullable=False, server_default="5"),
        sa.Column("cycles_completed", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("task_description", sa.Text(), nullable=True),
        sa.Column("domain", sa.String(100), nullable=True),
        sa.Column("linked_goal_id", sa.String(36), sa.ForeignKey("goals.id", ondelete="SET NULL"), nullable=True),
        sa.Column("is_completed", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("xp_earned", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_pomodoro_sessions_user_id", "pomodoro_sessions", ["user_id"])


def downgrade() -> None:
    op.drop_table("pomodoro_sessions")
    op.drop_table("goal_sessions")
    op.drop_column("weekly_reviews", "ai_generated")
    op.drop_column("daily_snapshots", "morning_intentions")
    op.drop_column("daily_snapshots", "morning_energy")
    op.drop_column("daily_snapshots", "morning_mood")
    op.drop_column("daily_snapshots", "morning_checkin_done")
    op.drop_column("vocabulary_entries", "last_review_date")
    op.drop_column("vocabulary_entries", "interval_days")
    op.drop_column("vocabulary_entries", "ease_factor")
    op.drop_column("habits", "linked_goal_id")
    op.drop_column("users", "fcm_token")
    op.drop_column("users", "streak_shield_tokens")
