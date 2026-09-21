from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "local"
    database_url: str = "sqlite+pysqlite:///./agricare-local.db"
    dev_auth_enabled: bool = False
    jwt_secret_key: SecretStr = SecretStr("agrian-dev-secret-key-change-in-prod-1234567890")
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30
    gemini_api_key: SecretStr | None = None
    gemini_model: str = "gemini-1.5-flash"
    gemini_api_base: str = "https://generativelanguage.googleapis.com/v1beta"
    ai_mock_fallback: bool = True


    model_config = SettingsConfigDict(env_file=".env", extra="ignore")



@lru_cache
def get_settings() -> Settings:
    return Settings()
