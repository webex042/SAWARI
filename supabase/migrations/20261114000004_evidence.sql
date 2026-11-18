-- =====================================================================
-- Migration 4: evidence (append-only facts collected in the field)
-- =====================================================================
-- Evidence is never edited to "fix" a route. A contradiction is a new
-- row. Route status is computed from evidence later (plan Section 9),
-- so ten identical unverified reports can never make a route verified.

-- One volunteer ride, recorded in the mapper app.
create table public.ride_sessions (
  id                bigint generated always as identity primary key,
  mapper_id         uuid not null references public.profiles (id),
  claimed_route_id  bigint references public.routes (id),   -- null = proposing a new route
  claimed_direction text check (claimed_direction in ('outbound', 'inbound', 'loop')),
  vehicle           public.vehicle_type not null,
  started_at        timestamptz not null,
  ended_at          timestamptz,
  client_session_id uuid unique not null,   -- made on the phone; stops duplicate uploads
  track             geography(LineString, 4326),  -- built on the server from gps_points
  point_count       integer,
  median_accuracy_m real,
  quality_flags     jsonb not null default '{}',  -- e.g. {"gaps": 2, "shared_facts_ok": true}
  review_status     text not null default 'submitted'
                    check (review_status in ('submitted', 'accepted', 'rejected', 'needs_info')),
  created_at        timestamptz not null default now()
);
create index ride_sessions_mapper_idx on public.ride_sessions (mapper_id, started_at desc);
create index ride_sessions_route_idx on public.ride_sessions (claimed_route_id);

-- Raw GPS points for a ride (about one every 5 seconds).
create table public.gps_points (
  session_id bigint not null references public.ride_sessions (id) on delete cascade,
  t          timestamptz not null,
  geom       geography(Point, 4326) not null,
  accuracy_m real,
  speed_mps  real,
  primary key (session_id, t)              -- same point sent twice = rejected, not duplicated
);

-- Stops the volunteer tapped during the ride.
create table public.observed_stops (
  id          bigint generated always as identity primary key,
  session_id  bigint not null references public.ride_sessions (id) on delete cascade,
  seq         smallint not null,
  stop_id     bigint references public.stops (id),   -- matched existing stop, or null if new
  geom        geography(Point, 4326) not null,
  label       text,                                  -- what the volunteer typed
  action      text check (action in ('boarded', 'alighted', 'vehicle_stopped', 'transfer')),
  observed_at timestamptz not null
);
create index observed_stops_session_idx on public.observed_stops (session_id);

-- Route boards and markings seen on vehicles. No number plates stored.
create table public.vehicle_sightings (
  id          bigint generated always as identity primary key,
  session_id  bigint references public.ride_sessions (id) on delete cascade,
  stop_id     bigint references public.stops (id),
  vehicle     public.vehicle_type not null,
  board_text  text,          -- route board words, typed out
  marking     text,          -- colour band, sticker, zone code
  photo_path  text,          -- storage path; plates and faces must be blurred
  observed_at timestamptz not null,
  reported_by uuid references public.profiles (id)
);

-- Fares: paid, quoted, or stated by a driver. Never a single "official" number.
create table public.fare_observations (
  id              bigint generated always as identity primary key,
  route_id        bigint references public.routes (id),
  from_stop_id    bigint references public.stops (id),
  to_stop_id      bigint references public.stops (id),
  amount_inr      numeric(6, 2) not null check (amount_inr > 0 and amount_inr < 1000),
  kind            text not null check (kind in ('paid', 'quoted', 'driver_stated', 'user_reported')),
  vehicle         public.vehicle_type not null,
  observed_at     timestamptz not null,
  ride_session_id bigint references public.ride_sessions (id) on delete set null,
  reported_by     uuid references public.profiles (id),
  anon_id         uuid,                      -- for passenger-reported fares
  is_outlier      boolean not null default false,
  created_at      timestamptz not null default now()
);
create index fare_obs_lookup on public.fare_observations
  (route_id, from_stop_id, to_stop_id, observed_at desc);

-- Each "this confirms / contradicts the route" event.
create table public.route_verifications (
  id                  bigint generated always as identity primary key,
  route_id            bigint not null references public.routes (id),
  pattern_id          bigint references public.route_patterns (id),
  method              text not null check (method in
                      ('field_ride', 'driver_confirm', 'reviewer_check', 'official_chart', 'user_report')),
  verdict             text not null check (verdict in ('confirms', 'contradicts', 'partial')),
  evidence_session_id bigint references public.ride_sessions (id),
  verifier_id         uuid references public.profiles (id),
  notes               text,
  verified_at         timestamptz not null default now()
);
create index route_verif_route on public.route_verifications (route_id, verified_at desc);

-- ---------------------------------------------------------------------
-- Security: volunteers add and read their OWN evidence; reviewers read
-- everything. Nobody edits evidence directly.
-- ---------------------------------------------------------------------
alter table public.ride_sessions       enable row level security;
alter table public.gps_points          enable row level security;
alter table public.observed_stops      enable row level security;
alter table public.vehicle_sightings   enable row level security;
alter table public.fare_observations   enable row level security;
alter table public.route_verifications enable row level security;

create policy rides_insert_own on public.ride_sessions
  for insert to authenticated with check (mapper_id = auth.uid());
create policy rides_read_own_or_reviewer on public.ride_sessions
  for select to authenticated using (mapper_id = auth.uid() or public.is_reviewer());

-- For child tables, "own" means "belongs to one of my ride sessions".
create policy gps_insert_own on public.gps_points
  for insert to authenticated with check (exists (
    select 1 from public.ride_sessions r where r.id = session_id and r.mapper_id = auth.uid()));
create policy gps_read_own_or_reviewer on public.gps_points
  for select to authenticated using (public.is_reviewer() or exists (
    select 1 from public.ride_sessions r where r.id = session_id and r.mapper_id = auth.uid()));

create policy obs_stops_insert_own on public.observed_stops
  for insert to authenticated with check (exists (
    select 1 from public.ride_sessions r where r.id = session_id and r.mapper_id = auth.uid()));
create policy obs_stops_read_own_or_reviewer on public.observed_stops
  for select to authenticated using (public.is_reviewer() or exists (
    select 1 from public.ride_sessions r where r.id = session_id and r.mapper_id = auth.uid()));

create policy sightings_insert_own on public.vehicle_sightings
  for insert to authenticated with check (reported_by = auth.uid());
create policy sightings_read_own_or_reviewer on public.vehicle_sightings
  for select to authenticated using (reported_by = auth.uid() or public.is_reviewer());

create policy fares_insert_own on public.fare_observations
  for insert to authenticated with check (reported_by = auth.uid());
create policy fares_read_own_or_reviewer on public.fare_observations
  for select to authenticated using (reported_by = auth.uid() or public.is_reviewer());

create policy verifications_reviewer_all on public.route_verifications
  for all to authenticated using (public.is_reviewer()) with check (public.is_reviewer());
