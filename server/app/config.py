"""
AarogyaMP — Configuration (pydantic-settings)
Person A owns this file.
"""
from pathlib import Path
from pydantic_settings import BaseSettings

_ENV_PATH = Path(__file__).resolve().parent.parent / ".env"


class Settings(BaseSettings):
    # Server
    PORT: int = 8000
    CORS_ORIGINS: str = "*"

    # Database
    DATABASE_URL: str = "postgresql+psycopg://aarogya:aarogya@localhost:5432/aarogyamp"

    # JWT
    JWT_SECRET: str = "changeme"
    JWT_ACCESS_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_EXPIRE_DAYS: int = 14

    # Storage
    STORAGE_DIR: str = "./storage"
    MAX_UPLOAD_MB: int = 25

    # LLM — Groq (OpenAI-compatible)
    LLM_BASE_URL: str = "https://api.groq.com/openai/v1"
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "llama-3.3-70b-versatile"
    LLM_TIMEOUT_SECONDS: int = 30

    # STT
    STT_PROVIDER: str = "device"  # device | whisper_api | local_whisper
    STT_API_KEY: str = ""

    # Push
    FCM_SERVER_KEY: str = ""

    # Ops
    ADMIN_OPS_TOKEN: str = "changeme"

    class Config:
        env_file = _ENV_PATH
        env_file_encoding = "utf-8"


settings = Settings()
