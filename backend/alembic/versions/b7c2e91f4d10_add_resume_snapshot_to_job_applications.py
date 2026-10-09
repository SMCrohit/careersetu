"""add resume_snapshot to job_applications

Revision ID: b7c2e91f4d10
Revises: 1ad6814b3988
Create Date: 2026-10-09 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b7c2e91f4d10'
down_revision: Union[str, Sequence[str], None] = '1ad6814b3988'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('job_applications', sa.Column('resume_snapshot', sa.JSON(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('job_applications', 'resume_snapshot')
