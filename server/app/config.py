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
    LLM_TIMEOUT_SECONDS: int = 75

    # Database
    DATABASE_URL: str = "postgresql+psycopg://aarogya:aarogya@localhost:5432/aarogyamp"

    # JWT
    JWT_SECRET: str = "changeme"
    JWT_ACCESS_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_EXPIRE_DAYS: int = 14

    # Storage
    STORAGE_DIR: str = "./storage"
    MAX_UPLOAD_MB: int = 25

    # LLM — defaults to local Ollama (llama3.1:8b); override via .env to use Groq or any OpenAI-compat provider
    LLM_BASE_URL: str = "http://ollama:11434/v1"
    LLM_API_KEY: str = "ollama"        # Ollama ignores this; Groq requires a real key
    LLM_MODEL: str = "llama3.1:8b"
    LLM_TIMEOUT_SECONDS: int = 75      # CPU inference can take 30-75s; keep above Flutter's 90s Dio timeout

    # STT
    STT_PROVIDER: str = "device"  # device | whisper_api | local_whisper
    STT_API_KEY: str = ""

    # Push — ntfy (self-hosted) + legacy FCM
    NTFY_BASE_URL: str = "http://localhost:8080"
    FCM_SERVER_KEY: str = ""

    # Ops
    ADMIN_OPS_TOKEN: str = "changeme"

    class Config:
        env_file = _ENV_PATH
        env_file_encoding = "utf-8"
        extra = "ignore"


settings = Settings()
