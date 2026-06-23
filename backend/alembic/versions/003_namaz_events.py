"""Add namaz tracker, day events, domino task

Revision ID: 003
Revises: 002
Create Date: 2026-06-22
"""
from typing import Sequence, Union
import sqlalchemy as sa
from alembic import op

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "namaz_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("log_date", sa.Date(), nullable=False),
        sa.Column("fajr", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("dhuhr", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("asr", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("maghrib", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("isha", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("xp_earned", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_namaz_logs_user_id", "namaz_logs", ["user_id"])
    op.create_unique_constraint("uq_namaz_user_date", "namaz_logs", ["user_id", "log_date"])

    op.create_table(
        "day_events",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("event_date", sa.Date(), nullable=False),
        sa.Column("event_type", sa.String(20), nullable=False),
        sa.Column("category", sa.String(50), nullable=False),
        sa.Column("description", sa.String(300), nullable=False),
        sa.Column("points", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_day_events_user_id", "day_events", ["user_id"])
    op.create_index("ix_day_events_date", "day_events", ["event_date"])

    op.add_column("daily_snapshots", sa.Column("domino_task", sa.String(300), nullable=True))
    op.add_column("daily_snapshots", sa.Column("domino_done", sa.Boolean(), nullable=False, server_default="false"))


def downgrade() -> None:
    op.drop_column("daily_snapshots", "domino_done")
    op.drop_column("daily_snapshots", "domino_task")
    op.drop_index("ix_day_events_date", table_name="day_events")
    op.drop_index("ix_day_events_user_id", table_name="day_events")
    op.drop_table("day_events")
    op.drop_index("ix_namaz_logs_user_id", table_name="namaz_logs")
    op.drop_table("namaz_logs")
