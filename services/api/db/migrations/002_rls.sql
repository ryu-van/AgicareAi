-- Row-level security for Supabase authenticated clients.
-- The FastAPI service should still enforce authorization at its boundary.

alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.user_roles enable row level security;
alter table public.consents enable row level security;
alter table public.farm_contexts enable row level security;
alter table public.chat_sessions enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_citations enable row level security;
alter table public.journal_entries enable row level security;
alter table public.reminders enable row level security;
alter table public.expert_escalations enable row level security;
alter table public.sync_events enable row level security;
alter table public.idempotency_keys enable row level security;
alter table public.audit_events enable row level security;
alter table public.domains enable row level security;
alter table public.subjects enable row level security;
alter table public.knowledge_articles enable row level security;

create policy profiles_owner_select on public.profiles
  for select using (id = auth.uid());
create policy profiles_owner_update on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

create policy roles_authenticated_read on public.roles
  for select to authenticated using (true);
create policy user_roles_owner_read on public.user_roles
  for select using (user_id = auth.uid());

create policy consents_owner_access on public.consents
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy farm_contexts_owner_access on public.farm_contexts
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy chat_sessions_owner_access on public.chat_sessions
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy chat_messages_session_owner_access on public.chat_messages
  for all using (
    exists (select 1 from public.chat_sessions s where s.id = session_id and s.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.chat_sessions s where s.id = session_id and s.user_id = auth.uid())
  );

create policy chat_citations_session_owner_access on public.chat_citations
  for all using (
    exists (
      select 1
      from public.chat_messages m
      join public.chat_sessions s on s.id = m.session_id
      where m.id = message_id and s.user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1
      from public.chat_messages m
      join public.chat_sessions s on s.id = m.session_id
      where m.id = message_id and s.user_id = auth.uid()
    )
  );

create policy journal_entries_owner_access on public.journal_entries
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy reminders_owner_access on public.reminders
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy escalations_owner_access on public.expert_escalations
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy escalations_assigned_expert_read on public.expert_escalations
  for select using (assigned_expert_id = auth.uid());
create policy escalations_assigned_expert_update on public.expert_escalations
  for update using (assigned_expert_id = auth.uid()) with check (assigned_expert_id = auth.uid());
create policy sync_events_owner_access on public.sync_events
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy idempotency_owner_access on public.idempotency_keys
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy domains_public_read on public.domains
  for select using (active = true);
create policy subjects_public_read on public.subjects
  for select using (status = 'published');
create policy knowledge_published_public_read on public.knowledge_articles
  for select using (status = 'published');

-- audit_events is intentionally not readable by end users.
