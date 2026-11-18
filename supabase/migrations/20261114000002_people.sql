-- =====================================================================
-- Migration 2: people (volunteers, reviewers, admins)
-- =====================================================================
-- Passengers are anonymous and have no row here. Volunteers and
-- reviewers log in with Supabase Auth; `auth.users` is Supabase's own
-- login table, and `profiles` adds Sawari-specific fields to it.

create table public.profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  display_name    text not null,
  role            public.user_role not null default 'volunteer',
  consent_version text not null,          -- which consent text they accepted
  consent_at      timestamptz not null,   -- when they accepted it
  created_at      timestamptz not null default now()
);

-- Extra details for volunteer mappers (one row per profile).
create table public.mappers (
  profile_id      uuid primary key references public.profiles (id) on delete cascade,
  college         text,
  home_area       text,
  trust_level     smallint not null default 0 check (trust_level between 0 and 3),
  onboarded_at    timestamptz,            -- set after the training ride is reviewed
  rides_submitted integer not null default 0,
  rides_accepted  integer not null default 0
);

-- Helper used by many security rules below: "is the logged-in person a
-- reviewer or admin?". `security definer` lets it read profiles even
-- when the caller could not read that table directly.
create or replace function public.is_reviewer()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('reviewer', 'admin')
  );
$$;

-- ---------------------------------------------------------------------
-- Row Level Security (RLS): every table starts locked. Each policy
-- below opens exactly one door. The server (using the service role key)
-- bypasses RLS, so passenger features work through the API only.
-- ---------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.mappers  enable row level security;

create policy profiles_read_own_or_reviewer on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_reviewer());

create policy profiles_insert_own on public.profiles
  for insert to authenticated
  with check (id = auth.uid() and role = 'volunteer');

create policy mappers_read_own_or_reviewer on public.mappers
  for select to authenticated
  using (profile_id = auth.uid() or public.is_reviewer());

create policy mappers_insert_own on public.mappers
  for insert to authenticated
  with check (profile_id = auth.uid());
-- No update policies yet: role, trust level and counters are changed by
-- the server or a reviewer tool, never directly by the volunteer.
