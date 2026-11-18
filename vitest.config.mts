// Vitest = the test runner. `npm test` runs every file in tests/ once.
// We test plain TypeScript logic (parser, planner, fares) in a Node
// environment; browser/component tests can be added later.
import { defineConfig } from "vitest/config";

export default defineConfig({
  // Lets tests import with the same "@/lib/..." paths the app uses
  // (read from tsconfig.json).
  resolve: { tsconfigPaths: true },
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
  },
});
