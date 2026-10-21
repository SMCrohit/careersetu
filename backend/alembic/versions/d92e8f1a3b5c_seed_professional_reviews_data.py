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
    """Seed reviews and backfill applied job resumes in production."""
    try:
        from seed_reviews import seed_if_needed
        seed_if_needed(min_count=15)
    except Exception as e:
        print(f"Notice: Review seeding during migration skipped or handled: {e}")

    try:
        from backfill_resumes import backfill_if_needed
        backfill_if_needed()
    except Exception as e:
        print(f"Notice: Resume backfill during migration skipped or handled: {e}")


def downgrade() -> None:
    """Downgrade: Optionally remove seeded reviews or pass."""
    pass
