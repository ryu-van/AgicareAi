-- Local PostgreSQL compatibility patch for databases initialized before the ORM payload hash was added.

alter table public.sync_events
  add column if not exists payload_hash text not null default '';
