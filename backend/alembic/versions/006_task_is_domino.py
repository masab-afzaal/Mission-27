"""add is_domino flag to tasks

Revision ID: 006
Revises: 853846726201
Create Date: 2026-07-03

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '006'
down_revision: Union[str, None] = '853846726201'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'tasks',
        sa.Column('is_domino', sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade() -> None:
    op.drop_column('tasks', 'is_domino')
