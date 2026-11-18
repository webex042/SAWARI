/**
 * Reads Sawari's settings from environment variables.
 *
 * Where the values come from:
 *   - On your computer: the file `.env.local` (never shared, never committed).
 *   - On a host (later, only after you approve a deploy): the host's settings page.
 *
 * Safety rule: Next.js only sends variables whose names start with
 * `NEXT_PUBLIC_` to the browser. Secret keys (service role key, Gemini key)
 * must NOT start with `NEXT_PUBLIC_`, so they stay on the server.
 */

/** Settings the app needs before it can talk to the database. */
const REQUIRED_FOR_DATABASE = [
  "NEXT_PUBLIC_SUPABASE_URL",
  "NEXT_PUBLIC_SUPABASE_ANON_KEY",
  "SUPABASE_SERVICE_ROLE_KEY",
] as const;

export type EnvStatus = {
  /** True when all database settings are filled in. */
  supabaseConfigured: boolean;
  /** True only when the LLM is switched on AND has a key and a model name. */
  llmEnabled: boolean;
  /** Names (never values) of missing database settings. */
  missing: string[];
};

/** A value counts as "set" only if it is not empty or just spaces. */
function isSet(value: string | undefined): boolean {
  return typeof value === "string" && value.trim().length > 0;
}

/**
 * Checks which settings are present. It reports names only, never the
 * secret values themselves, so its output is safe to show in a health check.
 *
 * `env` defaults to the real environment; tests pass a fake one.
 */
export function readEnvStatus(
  env: Record<string, string | undefined> = process.env,
): EnvStatus {
  const missing = REQUIRED_FOR_DATABASE.filter((name) => !isSet(env[name]));

  // The LLM stays off unless someone deliberately sets LLM_ENABLED=true.
  const llmEnabled =
    env.LLM_ENABLED === "true" && isSet(env.GEMINI_API_KEY) && isSet(env.GEMINI_MODEL);

  return {
    supabaseConfigured: missing.length === 0,
    llmEnabled,
    missing: [...missing],
  };
}
