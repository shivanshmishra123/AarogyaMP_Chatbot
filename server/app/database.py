"""
AarogyaMP — SQLAlchemy Engine & Session (Milestone 0 stub)
Person A owns this file.
"""
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.config import settings

connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}
    # Ensure storage directory exists if using local sqlite file
    if "///" in settings.DATABASE_URL:
        db_path = settings.DATABASE_URL.split("///", 1)[1]
        if db_path and not db_path.startswith(":memory:"):
            Path(db_path).parent.mkdir(parents=True, exist_ok=True)

engine = create_engine(settings.DATABASE_URL, echo=False, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def init_db():
    """Create all tables defined in models.py if not already present."""
    import app.models  # noqa: F401
    Base.metadata.create_all(bind=engine)


# Dependency for FastAPI route handlers
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
