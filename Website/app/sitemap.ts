import type { MetadataRoute } from "next";
import { SITE_URL } from "@/lib/site";

export const dynamic = "force-static";

const routes = [
  "",
  "/docs",
  "/docs/getting-started",
  "/docs/capture",
  "/docs/editor",
  "/docs/recording",
  "/docs/privacy",
  "/docs/shortcuts",
  "/docs/supabase",
] as const;

export default function sitemap(): MetadataRoute.Sitemap {
  return routes.map((route) => ({
    url: `${SITE_URL}${route}`,
    lastModified: new Date("2026-08-11"),
    changeFrequency: route === "" ? "weekly" : "monthly",
    priority: route === "" ? 1 : route === "/docs" ? 0.8 : 0.7,
  }));
}
