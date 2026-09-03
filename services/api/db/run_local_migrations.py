"""Apply pending local PostgreSQL migrations without resetting the database."""

from pathlib import Path

from sqlalchemy import create_engine, text

from services.api.app.core.config import get_settings

MIGRATION_DIR = Path(__file__).parent / "migrations"
MIGRATIONS = (
    "000_local_bootstrap.sql",
    "001_initial_schema.sql",
    "002_local_compat.sql",
    "003_mvp1_knowledge_seed.sql",
)


def run() -> None:
    engine = create_engine(get_settings().database_url, pool_pre_ping=True, connect_args={"connect_timeout": 5})
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                create table if not exists public.schema_migrations (
                  filename text primary key,
                  applied_at timestamptz not null default now()
                )
                """
            )
        )
        existing_tables = connection.execute(
            text(
                """
                select table_schema || '.' || table_name
                from information_schema.tables
                where table_schema = 'public' and table_name <> 'schema_migrations'
                order by table_name
                """
            )
        ).scalars().all()
        applied = set(connection.execute(text("select filename from public.schema_migrations")).scalars().all())
        if existing_tables and not applied:
            baseline = MIGRATIONS[:3]
            connection.execute(
                text("insert into public.schema_migrations (filename) values (:filename)"),
                [{"filename": name} for name in baseline],
            )
            applied.update(baseline)
            print("Recorded existing local schema baseline: " + ", ".join(baseline))

        for migration_name in MIGRATIONS:
            if migration_name in applied:
                continue
            migration_sql = (MIGRATION_DIR / migration_name).read_text(encoding="utf-8")
            print(f"Applying {migration_name}")
            connection.exec_driver_sql(migration_sql)
            connection.execute(
                text("insert into public.schema_migrations (filename) values (:filename)"),
                {"filename": migration_name},
            )

    engine.dispose()
    print("Local PostgreSQL migrations completed.")


if __name__ == "__main__":
    run()
