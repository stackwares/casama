/**
 * End-to-end tests: the built e2e extension (dist/e2e: the dev build with site access granted) loaded in Playwright's Chromium, signing in
 * to a running Casama server. `pnpm e2e` builds first. See e2e/harness.ts for the settings.
 */
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "e2e",
  workers: 1,
  timeout: 90_000,
  expect: { timeout: 20_000 },
  reporter: [["list"]],
  use: { trace: "retain-on-failure" },
});
