# Sawari

Sawari helps people in Ranchi find their way by shared auto and e-rickshaw. You ask in Hinglish, Hindi or English ("Station se Lalpur kaise jaun?") and get:

- where to board,
- which vehicle to take,
- where to get off or change,
- an approximate fare range,

each with a note on how sure the answer is.

Answers come only from a community-verified route database. The AI may read the question, but it never makes up routes, stops or fares.

**Status:** project skeleton (plan milestones M0–M1). There is no answer engine yet.

## What is in this skeleton

| Path | What it is |
| --- | --- |
| `app/page.tsx` | Placeholder home page (Hinglish, no JavaScript sent to the phone) |
| `app/api/health/route.ts` | `GET /api/health`: shows the app is running and which settings are missing |
| `lib/env.ts` | Checks which settings are present (names only, never values) |
| `lib/text/normalize.ts` | Cleans up query text and detects Hindi script |
| `tests/unit/` | Vitest unit tests |
| `supabase/migrations/` | Database tables, indexes and security rules (PostGIS, Row Level Security, audit history) |
| `supabase/seed.sql` | Empty on purpose: no invented routes, stops or fares |
| `.env.example` | Template of every setting, with no secrets |

## Run it on your computer

**You need:** Node.js 24 (or newer) and npm. Docker Desktop is needed only for the local database (step 4).

1. Install packages (needed only once, or after `package.json` changes):

   ```bash
   npm install
   ```

2. Create your private settings file if it doesn't exist yet. The values can stay empty for now.

   ```bash
   cp .env.example .env.local
   ```

3. Start the app, then open http://localhost:3000 and http://localhost:3000/api/health:

   ```bash
   npm run dev
   ```

4. **Optional, needs Docker Desktop:** start the local database. It runs every migration and prints the URL and keys to copy into `.env.local`.

   ```bash
   npm run db:start
   ```

   The database dashboard (Studio) opens at http://localhost:54323. `npm run db:reset` rebuilds the database from the migrations, and `npm run db:stop` shuts it down.

## Checks before sharing or deploying

```bash
npm run check
```

This runs ESLint, the TypeScript type check and the unit tests. It is the project's only "CI": it runs on your computer, with no GitHub Actions.

| Script | What it does |
| --- | --- |
| `npm run dev` | Development server with live reload |
| `npm run build` / `npm start` | Production build, and running it |
| `npm run lint` | ESLint |
| `npm run typecheck` | Generates Next.js route types, then runs `tsc --noEmit` |
| `npm test` / `npm run test:watch` | Unit tests, once / on every save |
| `npm run db:start` / `db:stop` / `db:status` / `db:reset` | Local Supabase database (needs Docker) |

## Project rules

- Development happens locally. There are no GitHub Actions and no automatic deploys.
- Secrets live only in `.env.local`. Never put a secret key in a variable that starts with `NEXT_PUBLIC_`, because those reach the browser.
- Do not invent Ranchi routes, stops, coordinates or fares. Data comes from field rides, driver interviews, OpenStreetMap, or official charts, and every row records its source.
- Deploying (for example with the Vercel CLI) or pushing database migrations to a hosted Supabase project is a deliberate, approved step, never automatic.

## Next milestones

M2 place resolver → M3 Hinglish rule parser and `POST /api/ask` → M4 route planner → M5 fare ranges → M6 answer card and share page. Day-by-day steps and acceptance criteria are in the Sawari implementation plan.

## Licence

MIT (see `LICENSE`). Map data from OpenStreetMap is © OpenStreetMap contributors, under the ODbL.
