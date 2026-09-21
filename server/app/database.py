"""
AarogyaMP — SQLAlchemy Engine & Session (Milestone 0 stub)
Person A owns this file.
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.config import settings

engine = create_engine(settings.DATABASE_URL, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


# Dependency for FastAPI route handlers
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
