import { defineConfig } from "vitest/config";

export default defineConfig({
  define: {
    __CASAMA_TARGET__: JSON.stringify("dev"),
    __CASAMA_VERSION__: JSON.stringify("0.1.0"),
    __CASAMA_BROWSER__: JSON.stringify("chromium"),
  },
  test: { include: ["test/**/*.test.ts"], environment: "node" },
});
