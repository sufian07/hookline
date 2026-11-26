import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

// Builds into Rails' public/ so one process serves the API and the dashboard.
export default defineConfig({
  plugins: [react()],
  build: { outDir: "../public/dashboard", emptyOutDir: true },
  base: "/dashboard/",
  server: { proxy: { "/api": "http://localhost:3000" } },
  test: {
    environment: "jsdom",
    setupFiles: ["./src/test/setup.ts"],
    restoreMocks: true,
  },
});
