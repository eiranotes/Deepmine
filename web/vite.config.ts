import { existsSync } from "node:fs";
import vinext from "vinext";
import { defineConfig, type PluginOption } from "vite";
import hostingConfig from "./.openai/hosting.json";

const SITE_CREATOR_PLACEHOLDER_DATABASE_ID =
  "00000000-0000-4000-8000-000000000000";
const sitesPluginPath = "./build/sites-vite-plugin";

const { d1, r2 } = hostingConfig;
const isCodexSeatbeltSandbox = process.env.CODEX_SANDBOX === "seatbelt";

const localBindingConfig = {
  main: "./worker/index.ts",
  compatibility_flags: ["nodejs_compat"],
  d1_databases: d1
    ? [
        {
          binding: d1,
          database_name: "site-creator-d1",
          database_id: SITE_CREATOR_PLACEHOLDER_DATABASE_ID,
        },
      ]
    : [],
  r2_buckets: r2
    ? [
        {
          binding: r2,
          bucket_name: "site-creator-r2",
        },
      ]
    : [],
};

async function optionalSitesPlugin(): Promise<PluginOption[]> {
  const sourceExists = existsSync(new URL(`${sitesPluginPath}.ts`, import.meta.url));
  const javascriptExists = existsSync(new URL(`${sitesPluginPath}.js`, import.meta.url));
  if (!sourceExists && !javascriptExists) return [];

  const sitesModule = await import(/* @vite-ignore */ sitesPluginPath);
  return typeof sitesModule.sites === "function" ? [sitesModule.sites()] : [];
}

export default defineConfig(async () => {
  process.env.WRANGLER_WRITE_LOGS ??= "false";
  process.env.WRANGLER_LOG_PATH ??= ".wrangler/logs";
  process.env.MINIFLARE_REGISTRY_PATH ??= ".wrangler/registry";

  const { cloudflare } = await import("@cloudflare/vite-plugin");
  const sitesPlugins = await optionalSitesPlugin();

  return {
    server: isCodexSeatbeltSandbox
      ? { watch: { useFsEvents: false, usePolling: true } }
      : undefined,
    plugins: [
      vinext(),
      ...sitesPlugins,
      cloudflare({
        viteEnvironment: { name: "rsc", childEnvironments: ["ssr"] },
        config: localBindingConfig,
      }),
    ],
  };
});
