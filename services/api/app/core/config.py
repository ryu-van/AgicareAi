from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "local"
    database_url: str = "sqlite+pysqlite:///./agricare-local.db"
    dev_auth_enabled: bool = False
    gemini_api_key: SecretStr | None = None
    gemini_model: str = "gemini-1.5-flash"
    gemini_api_base: str = "https://generativelanguage.googleapis.com/v1beta"
    ai_mock_fallback: bool = True


    model_config = SettingsConfigDict(env_file=".env", extra="ignore")



@lru_cache
def get_settings() -> Settings:
    return Settings()
