-- Local PostgreSQL development only.
-- Supabase provides auth.users automatically; plain PostgreSQL does not.
-- This minimal table exists only so profiles can keep the same foreign key shape.

create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key,
  created_at timestamptz not null default now()
);
