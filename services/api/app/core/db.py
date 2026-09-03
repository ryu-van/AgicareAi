from collections.abc import Generator
from contextlib import contextmanager

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from services.api.app.core.config import get_settings

_engine: Engine | None = None
_session_factory: sessionmaker[Session] | None = None


def configure_database(database_url: str | None = None) -> None:
    global _engine, _session_factory
    dispose_database()
    url = database_url or get_settings().database_url
    connect_args = {"check_same_thread": False} if url.startswith("sqlite") else {}
    _engine = create_engine(url, future=True, pool_pre_ping=True, connect_args=connect_args)
    _session_factory = sessionmaker(bind=_engine, autoflush=False, autocommit=False, expire_on_commit=False)


def get_engine() -> Engine:
    if _engine is None:
        configure_database()
    assert _engine is not None
    return _engine


def get_session() -> Generator[Session, None, None]:
    global _session_factory
    if _session_factory is None:
        configure_database()
    assert _session_factory is not None
    session = _session_factory()
    try:
        yield session
    finally:
        session.close()


@contextmanager
def session_scope() -> Generator[Session, None, None]:
    yield from get_session()


def create_all_tables() -> None:
    from services.api.app.db.models import Base

    Base.metadata.create_all(get_engine())


def dispose_database() -> None:
    global _engine, _session_factory
    if _engine is not None:
        _engine.dispose()
    _engine = None
    _session_factory = None
