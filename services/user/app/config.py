"""Configuration management for user service."""

from functools import lru_cache
from typing import Literal
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings with environment variable support."""

    # Service config
    service_name: str = "user"
    environment: Literal["development", "staging", "production"] = "development"
    debug: bool = False
    
    # Server config
    host: str = "0.0.0.0"
    port: int = 8000
    workers: int = 1
    
    # Database config
    database_url: str = "sqlite+aiosqlite:///./user.db"
    database_echo: bool = False
    
    # CORS
    cors_origins: list[str] = ["*"]
    
    # Monitoring
    enable_metrics: bool = True
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()

