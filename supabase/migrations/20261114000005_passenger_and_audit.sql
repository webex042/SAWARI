-- =====================================================================
-- Migration 5: passenger searches, feedback, analytics, change history
-- =====================================================================
-- Passengers are anonymous: `anon_id` is a random id kept in their
-- browser, not a phone number or name.

-- Every question asked, and what Sawari answered (for audit and metrics).
create table public.trip_searches (
  id              uuid primary key default gen_random_uuid(),
  anon_id         uuid,
  raw_text        text,            -- emptied after 90 days by a retention job (later migration)
  language        text,            -- 'hinglish', 'hi-Deva', 'en'
  parsed          jsonb,           -- structured output of the parser
  parser          text check (parser in ('rules', 'llm', 'none')),
  origin_place_id bigint references public.places (id),
  dest_place_id   bigint references public.places (id),
  result_status   text not null check (result_status in
                  ('answered', 'partial', 'no_route', 'unresolved', 'error')),
  result          jsonb,           -- itineraries with record ids shown to the user
  top_confidence  real,
  latency_ms      integer,
  created_at      timestamptz not null default now()
);
create index trip_searches_od on public.trip_searches (origin_place_id, dest_place_id, created_at desc);
create index trip_searches_created on public.trip_searches (created_at desc);

-- "Sahi tha? / Galat hai?" answers from passengers.
create table public.feedback (
  id                bigint generated always as identity primary key,
  search_id         uuid references public.trip_searches (id) on delete set null,
  route_id          bigint references public.routes (id),
  stop_id           bigint references public.stops (id),
  kind              text not null check (kind in ('worked', 'wrong_stop', 'wrong_vehicle',
                    'wrong_fare', 'route_not_running', 'unsafe', 'other')),
  reported_fare_inr numeric(6, 2),
  comment           text check (char_length(comment) <= 500),
  anon_id           uuid,
  status            text not null default 'new'
                    check (status in ('new', 'triaged', 'actioned', 'rejected')),
  created_at        timestamptz not null default now()
);
create index feedback_status_idx on public.feedback (status, created_at desc);

-- Product analytics events. No personal data; event names are allow-listed in the API.
create table public.events (
  id         bigint generated always as identity primary key,
  anon_id    uuid,
  name       text not null,   -- 'search_submitted', 'answer_viewed', 'feedback_sent', ...
  props      jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index events_name_time on public.events (name, created_at desc);

-- Full history of every change to routes, stops and route patterns.
create table public.route_change_history (
  id          bigint generated always as identity primary key,
  table_name  text not null,
  record_id   bigint not null,
  change_type text not null,          -- 'insert', 'update', 'delete'
  old_row     jsonb,
  new_row     jsonb,
  reason      text,
  changed_by  uuid default auth.uid(),
  changed_at  timestamptz not null default now()
);
create index route_history_record on public.route_change_history (table_name, record_id, changed_at desc);

-- Trigger function: copies the old and new row into the history table.
-- `security definer` lets it write history even though normal users
-- have no permission to insert into route_change_history themselves.
create or replace function public.log_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.route_change_history (table_name, record_id, change_type, old_row, new_row)
  values (
    tg_table_name,
    coalesce((to_jsonb(new) ->> 'id')::bigint, (to_jsonb(old) ->> 'id')::bigint, 0),
    lower(tg_op),
    case when tg_op = 'INSERT' then null else to_jsonb(old) end,
    case when tg_op = 'DELETE' then null else to_jsonb(new) end
  );
  return coalesce(new, old);
end;
$$;

create trigger routes_audit
  after insert or update or delete on public.routes
  for each row execute function public.log_change();
create trigger stops_audit
  after insert or update or delete on public.stops
  for each row execute function public.log_change();
create trigger route_patterns_audit
  after insert or update or delete on public.route_patterns
  for each row execute function public.log_change();

-- ---------------------------------------------------------------------
-- Security: passengers never touch these tables directly; the server
-- API writes them with the service role. Reviewers may read them.
-- ---------------------------------------------------------------------
alter table public.trip_searches        enable row level security;
alter table public.feedback             enable row level security;
alter table public.events               enable row level security;
alter table public.route_change_history enable row level security;

create policy searches_reviewer_read on public.trip_searches
  for select to authenticated using (public.is_reviewer());
create policy feedback_reviewer_read on public.feedback
  for select to authenticated using (public.is_reviewer());
create policy feedback_reviewer_update on public.feedback
  for update to authenticated using (public.is_reviewer()) with check (public.is_reviewer());
create policy events_reviewer_read on public.events
  for select to authenticated using (public.is_reviewer());
create policy history_reviewer_read on public.route_change_history
  for select to authenticated using (public.is_reviewer());
