-- User credentials table for email/phone and password authentication

create table if not exists public.user_credentials (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  identifier varchar(120) not null unique,
  password_hash varchar(255) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_user_credentials_identifier on public.user_credentials (identifier);
