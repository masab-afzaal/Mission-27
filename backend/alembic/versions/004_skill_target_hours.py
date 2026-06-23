"""add target_hours to skill_areas

Revision ID: 004
Revises: 003
Create Date: 2026-06-22
"""
from alembic import op
import sqlalchemy as sa

revision = '004'
down_revision = '003'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'skill_areas',
        sa.Column('target_hours', sa.Float(), nullable=False, server_default='100.0'),
    )


def downgrade() -> None:
    op.drop_column('skill_areas', 'target_hours')
