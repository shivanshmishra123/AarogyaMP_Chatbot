# Alembic migrations

Person A runs: `alembic init alembic` to scaffold this directory fully.
Then: `alembic revision --autogenerate -m "initial"` after models.py is complete.
Then: `alembic upgrade head` to apply migrations.

See Reference §2 (Quick Start — Backend) for full workflow.
