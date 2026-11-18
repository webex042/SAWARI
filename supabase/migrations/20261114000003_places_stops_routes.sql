-- =====================================================================
-- Migration 3: places, stops and routes (the "map" of the network)
-- =====================================================================
-- These tables hold the current best summary. Raw evidence (rides, GPS,
-- fares) lives in migration 4 and is never overwritten.
--
-- geography(Point, 4326) = a latitude/longitude point. Distances on
-- `geography` come back in metres, which keeps queries simple.

-- Named locations people talk about: areas, chowks, stations, colleges,
-- landmarks. ("Locations" and "Landmarks" from the plan live here.)
create table public.places (
  id         bigint generated always as identity primary key,
  name       text not null,              -- e.g. 'Ranchi Railway Station'
  name_hi    text,                       -- Devanagari form, if known
  kind       text not null check (kind in
             ('area', 'landmark', 'station', 'college', 'hospital', 'market', 'chowk', 'other')),
  geom       geography(Point, 4326) not null,
  osm_id     text,                       -- OpenStreetMap id, if imported from OSM
  source     public.source_type not null,
  created_at timestamptz not null default now()
);
create index places_geom_gix on public.places using gist (geom);

-- Every way people say a place: nicknames, spellings, Hindi script.
create table public.place_aliases (
  id         bigint generated always as identity primary key,
  place_id   bigint not null references public.places (id) on delete cascade,
  alias      text not null,              -- 'station', 'ranchi junction', ...
  alias_norm text generated always as (lower(alias)) stored,
  weight     real not null default 1.0,  -- higher = more likely meaning
  unique (place_id, alias_norm)
);
-- Trigram index: makes fuzzy search on aliases fast.
create index place_aliases_trgm on public.place_aliases
  using gin (alias_norm extensions.gin_trgm_ops);

-- Boarding points / stands where vehicles stop.
create table public.stops (
  id                  bigint generated always as identity primary key,
  code                text unique not null,    -- internal code, e.g. 'STP-0001'
  name                text not null,           -- e.g. 'Station auto stand (exit side)'
  place_id            bigint references public.places (id),
  side_note           text,                    -- side of road, nearby landmark
  geom                geography(Point, 4326) not null,
  is_designated_stand boolean not null default false,
  status              public.verification_status not null default 'reported',
  last_verified_at    timestamptz,
  created_by          uuid references public.profiles (id),
  created_at          timestamptz not null default now()
);
create index stops_geom_gix on public.stops using gist (geom);

-- A route as people know it (both directions together).
create table public.routes (
  id                bigint generated always as identity primary key,
  code              text unique not null,      -- internal, e.g. 'RNC-AU-001'
  official_route_no text,                      -- only if from an official chart
  name              text not null,
  vehicle           public.vehicle_type not null,
  status            public.verification_status not null default 'reported',
  confidence        real not null default 0 check (confidence between 0 and 1),
  operating_hours   text,                      -- free text with its source, for now
  last_verified_at  timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- One row per direction of a route, with its cleaned path on the map.
create table public.route_patterns (
  id                bigint generated always as identity primary key,
  route_id          bigint not null references public.routes (id) on delete cascade,
  direction         text not null check (direction in ('outbound', 'inbound', 'loop')),
  headsign          text,                      -- what drivers call out
  geom              geography(LineString, 4326),
  duration_min_low  smallint,
  duration_min_high smallint,
  status            public.verification_status not null default 'reported',
  unique (route_id, direction)
);
create index route_patterns_geom_gix on public.route_patterns using gist (geom);

-- The ordered list of stops for each pattern.
create table public.route_stops (
  pattern_id        bigint not null references public.route_patterns (id) on delete cascade,
  seq               smallint not null,         -- 1, 2, 3 ... along the direction of travel
  stop_id           bigint not null references public.stops (id),
  can_board         boolean not null default true,
  can_alight        boolean not null default true,
  dist_from_start_m integer,
  primary key (pattern_id, seq)
);
create index route_stops_stop_idx on public.route_stops (stop_id);

-- Keep routes.updated_at current on every change.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger routes_set_updated_at
  before update on public.routes
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- Security: this is public, non-personal network data. Logged-in
-- volunteers may read it (to pick routes in the mapper app); only
-- reviewers may change it. Passengers read it through the server API.
-- ---------------------------------------------------------------------
alter table public.places         enable row level security;
alter table public.place_aliases  enable row level security;
alter table public.stops          enable row level security;
alter table public.routes         enable row level security;
alter table public.route_patterns enable row level security;
alter table public.route_stops    enable row level security;

create policy places_read on public.places for select to authenticated using (true);
create policy places_write on public.places for all to authenticated
  using (public.is_reviewer()) with check (public.is_reviewer());

create policy place_aliases_read on public.place_aliases for select to authenticated using (true);
create policy place_aliases_write on public.place_aliases for all to authenticated
  using (public.is_reviewer()) with check (public.is_reviewer());

create policy stops_read on public.stops for select to authenticated using (true);
create policy stops_write on public.stops for all to authenticated
  using (public.is_reviewer()) with check (public.is_reviewer());

create policy routes_read on public.routes for select to authenticated using (true);
create policy routes_write on public.routes for all to authenticated
  using (public.is_reviewer()) with check (public.is_reviewer());

create policy route_patterns_read on public.route_patterns for select to authenticated using (true);
create policy route_patterns_write on public.route_patterns for all to authenticated
  using (public.is_reviewer()) with check (public.is_reviewer());

create policy route_stops_read on public.route_stops for select to authenticated using (true);
create policy route_stops_write on public.route_stops for all to authenticated
  using (public.is_reviewer()) with check (public.is_reviewer());
