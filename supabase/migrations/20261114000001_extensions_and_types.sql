-- =====================================================================
-- Migration 1: extensions and shared types
-- =====================================================================
-- PostGIS  = maps and distances (points, lines, "stops within 500 m").
-- pg_trgm  = fuzzy text matching, so "lalpr" can still find "Lalpur".
-- Supabase keeps extensions in their own "extensions" schema, which is
-- already on the database search path, so types like `geography`
-- work without a prefix.
create extension if not exists postgis with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- Kinds of vehicle Sawari knows about. 'walk' is used for walking legs.
create type public.vehicle_type as enum ('shared_auto', 'e_rickshaw', 'city_bus', 'walk');

-- Lifecycle of a route or stop (see plan Section 9).
--   reported  = someone said it exists, nobody has ridden it yet
--   observed  = one accepted field ride
--   verified  = two independent accepted field rides agree
--   disputed  = fresh evidence contradicts it
--   stale     = not re-checked within its freshness window
--   suspended = temporarily not running (strike, diversion, road work)
--   retired   = confirmed gone; kept for history
create type public.verification_status as enum
  ('reported', 'observed', 'verified', 'disputed', 'stale', 'suspended', 'retired');

-- Where a piece of information came from.
create type public.source_type as enum
  ('field_ride', 'driver_interview', 'user_report', 'official_chart', 'team_research');

-- Roles for logged-in people. Passengers never log in.
create type public.user_role as enum ('volunteer', 'reviewer', 'admin');
