import { connection } from "next/server";
import { readEnvStatus } from "@/lib/env";

/**
 * GET /api/health
 *
 * A quick "is the app alive?" check. Open http://localhost:3000/api/health
 * in a browser. It shows which settings are present (names only, never
 * secret values). Later it will also check the database connection.
 */
export async function GET() {
  // With Cache Components on, a GET handler would otherwise be built once
  // and frozen. `connection()` makes it run fresh on every request.
  await connection();

  const env = readEnvStatus();

  return Response.json({
    ok: true,
    service: "sawari",
    time: new Date().toISOString(),
    database: env.supabaseConfigured ? "configured, not yet checked" : "not configured",
    missingSettings: env.missing,
    llm: env.llmEnabled ? "on" : "off",
  });
}
