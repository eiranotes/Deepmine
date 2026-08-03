import react from "@vitejs/plugin-react";
import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vite";

const repositoryBase = process.env.PAGES_BASE_PATH ?? "/Deepmine/";

export default defineConfig({
  base: repositoryBase,
  root: fileURLToPath(new URL("./pages-game", import.meta.url)),
  publicDir: fileURLToPath(new URL("./public", import.meta.url)),
  plugins: [react()],
  build: {
    emptyOutDir: true,
    outDir: fileURLToPath(new URL("./pages-dist", import.meta.url)),
  },
});
