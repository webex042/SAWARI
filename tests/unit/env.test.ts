import { describe, expect, test } from "vitest";
import { readEnvStatus } from "@/lib/env";

// A complete fake set of database settings (not real keys).
const DB = {
  NEXT_PUBLIC_SUPABASE_URL: "http://127.0.0.1:54321",
  NEXT_PUBLIC_SUPABASE_ANON_KEY: "fake-anon-key",
  SUPABASE_SERVICE_ROLE_KEY: "fake-service-key",
};

describe("readEnvStatus", () => {
  test("reports every missing database setting by name", () => {
    const status = readEnvStatus({});
    expect(status.supabaseConfigured).toBe(false);
    expect(status.missing).toEqual([
      "NEXT_PUBLIC_SUPABASE_URL",
      "NEXT_PUBLIC_SUPABASE_ANON_KEY",
      "SUPABASE_SERVICE_ROLE_KEY",
    ]);
  });

  test("treats blank values as missing", () => {
    const status = readEnvStatus({ ...DB, SUPABASE_SERVICE_ROLE_KEY: "   " });
    expect(status.missing).toEqual(["SUPABASE_SERVICE_ROLE_KEY"]);
  });

  test("is configured when all database settings are present", () => {
    const status = readEnvStatus(DB);
    expect(status.supabaseConfigured).toBe(true);
    expect(status.missing).toEqual([]);
  });

  test("keeps the LLM off unless switched on with a key and a model", () => {
    expect(readEnvStatus({ ...DB, GEMINI_API_KEY: "k", GEMINI_MODEL: "m" }).llmEnabled).toBe(false);
    expect(readEnvStatus({ ...DB, LLM_ENABLED: "true", GEMINI_MODEL: "m" }).llmEnabled).toBe(false);
    expect(
      readEnvStatus({ ...DB, LLM_ENABLED: "true", GEMINI_API_KEY: "k", GEMINI_MODEL: "m" }).llmEnabled,
    ).toBe(true);
  });

  test("never includes secret values in its output", () => {
    const text = JSON.stringify(readEnvStatus(DB));
    expect(text).not.toContain("fake-service-key");
    expect(text).not.toContain("fake-anon-key");
  });
});
