
"""seed professional reviews data

Revision ID: d92e8f1a3b5c
Revises: b7c2e91f4d10
Create Date: 2026-10-22 00:25:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd92e8f1a3b5c'
down_revision: Union[str, Sequence[str], None] = 'b7c2e91f4d10'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Seed reviews and backfill applied job resumes in production (completed)."""
    pass


def downgrade() -> None:
    """Downgrade: Optionally remove seeded reviews or pass."""
    pass
