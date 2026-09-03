-- AgriCare AI MVP schema draft for Supabase PostgreSQL.
-- Apply locally first. Do not edit after applying; create a new migration.

create extension if not exists pgcrypto;

create type public.agri_domain as enum ('plant', 'animal');
create type public.publish_status as enum ('draft', 'in_review', 'published', 'archived');
create type public.message_role as enum ('user', 'assistant');
create type public.message_status as enum ('queued', 'processing', 'completed', 'failed', 'safety_blocked');
create type public.safety_level as enum ('normal', 'caution', 'urgent');
create type public.journal_entry_type as enum ('observation', 'treatment', 'harvest', 'vaccination', 'feeding');
create type public.reminder_status as enum ('pending', 'completed', 'snoozed', 'cancelled');
create type public.escalation_status as enum ('requested', 'assigned', 'in_progress', 'resolved', 'cancelled');
create type public.sync_status as enum ('applied', 'duplicate', 'conflict', 'rejected');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  phone text,
  locale text not null default 'vi-VN',
  active_domain public.agri_domain,
  region_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.roles (
  id text primary key check (id in ('user', 'expert', 'editor', 'admin')),
  label text not null,
  description text,
  created_at timestamptz not null default now()
);

create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id text not null references public.roles(id) on delete restrict,
  granted_by uuid references public.profiles(id) on delete set null,
  granted_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

create table public.consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  consent_type text not null check (consent_type in ('privacy', 'ai_disclaimer', 'notifications')),
  version text not null,
  accepted_at timestamptz not null default now(),
  revoked_at timestamptz,
  unique (user_id, consent_type, version)
);

create table public.domains (
  id public.agri_domain primary key,
  label text not null,
  sort_order smallint not null default 0,
  active boolean not null default true
);

create table public.subjects (
  id text primary key check (id ~ '^[a-z0-9_]+$'),
  domain public.agri_domain not null references public.domains(id),
  name text not null,
  status public.publish_status not null default 'draft',
  created_at timestamptz not null default now()
);

create table public.farm_contexts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  domain public.agri_domain not null,
  subject_id text references public.subjects(id),
  name text not null check (length(name) between 1 and 120),
  region_code text,
  size_label text,
  notes text check (notes is null or length(notes) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.knowledge_articles (
  id uuid primary key default gen_random_uuid(),
  domain public.agri_domain not null,
  subject_id text not null references public.subjects(id),
  title text not null check (length(title) between 1 and 200),
  summary text,
  content text not null,
  topic text,
  growth_stage text,
  status public.publish_status not null default 'draft',
  source_url text,
  source_name text,
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  published_at timestamptz,
  search_vector tsvector generated always as (to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(summary, '') || ' ' || content)) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.chat_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  domain public.agri_domain not null,
  subject_id text references public.subjects(id),
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.chat_sessions(id) on delete cascade,
  role public.message_role not null,
  content text not null check (length(content) between 1 and 5000),
  status public.message_status not null default 'queued',
  safety_level public.safety_level,
  needs_expert boolean not null default false,
  provider text,
  model text,
  created_at timestamptz not null default now()
);

create table public.chat_citations (
  message_id uuid not null references public.chat_messages(id) on delete cascade,
  article_id uuid not null references public.knowledge_articles(id),
  section text,
  relevance_score numeric(5,4) check (relevance_score between 0 and 1),
  primary key (message_id, article_id)
);

create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject_id text not null references public.subjects(id),
  entry_type public.journal_entry_type not null,
  observed_at timestamptz not null,
  timezone text not null default 'Asia/Ho_Chi_Minh',
  title text not null check (length(title) between 1 and 160),
  notes text check (notes is null or length(notes) <= 5000),
  client_event_id text,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, client_event_id)
);

create table public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject_id text references public.subjects(id),
  title text not null check (length(title) between 1 and 160),
  due_at timestamptz not null,
  timezone text not null default 'Asia/Ho_Chi_Minh',
  recurrence jsonb,
  status public.reminder_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.expert_escalations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source_session_id uuid references public.chat_sessions(id),
  source_journal_entry_id uuid references public.journal_entries(id),
  shared_notes text,
  coarse_region_code text,
  status public.escalation_status not null default 'requested',
  assigned_expert_id uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.sync_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  event_id text not null,
  entity text not null check (entity in ('journal_entry', 'reminder')),
  operation text not null check (operation in ('upsert', 'delete')),
  payload jsonb not null,
  payload_hash text not null,
  status public.sync_status not null,
  entity_id uuid,
  error_code text,
  created_at timestamptz not null default now(),
  unique (user_id, event_id)
);

create table public.idempotency_keys (
  user_id uuid not null references public.profiles(id) on delete cascade,
  key text not null,
  request_hash text not null,
  response_status smallint not null,
  response_body jsonb not null,
  expires_at timestamptz not null default (now() + interval '24 hours'),
  created_at timestamptz not null default now(),
  primary key (user_id, key)
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index subjects_domain_status_idx on public.subjects(domain, status);
create index user_roles_role_user_idx on public.user_roles(role_id, user_id);
create index farm_contexts_user_updated_idx on public.farm_contexts(user_id, updated_at desc);
create index knowledge_published_feed_idx on public.knowledge_articles(status, domain, published_at desc);
create index knowledge_search_idx on public.knowledge_articles using gin(search_vector);
create index chat_sessions_user_updated_idx on public.chat_sessions(user_id, updated_at desc);
create index chat_messages_session_created_idx on public.chat_messages(session_id, created_at asc);
create index journal_user_observed_idx on public.journal_entries(user_id, observed_at desc) where deleted_at is null;
create index reminders_due_idx on public.reminders(user_id, due_at, status);
create index sync_user_created_idx on public.sync_events(user_id, created_at desc);

insert into public.domains (id, label, sort_order) values
  ('plant', 'Trồng trọt', 1), ('animal', 'Chăn nuôi', 2)
on conflict (id) do nothing;

insert into public.roles (id, label, description) values
  ('user', 'User', 'Nông hộ thông thường'),
  ('expert', 'Expert', 'Chuyên gia được phân công xem ca'),
  ('editor', 'Editor', 'Biên tập và duyệt knowledge article'),
  ('admin', 'Admin', 'Quản trị role, policy và audit')
on conflict (id) do nothing;

-- RLS is enabled in 002_rls.sql after local seed verification.
