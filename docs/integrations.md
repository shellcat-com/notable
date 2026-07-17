# Connected services — Parcel / notable repo

Repo: [github.com/bswxyz/notable](https://github.com/bswxyz/notable)

| Service | Purpose | Where configured |
|---------|---------|------------------|
| **GitHub** | Source, Releases, CI | `.github/workflows/` |
| **Vercel** | Marketing site `parcel.parable.dev` | `Website/vercel.json`, connect repo root `Website/` |
| **Supabase** | Optional Capture upload (Storage) | Parcel → Preferences → Upload |
| **Mobbin** | UI research MCP | `.cursor/mcp.json` |
| **Higgsfield** | Icon / marketing assets MCP | `.cursor/mcp.json` |
| **Parable** | Component registry MCP | Cursor MCP catalog |
| **Sparkle** | In-app updates | `Website/public/appcast.xml`, `Scripts/release.sh` |

## GitHub

- **Default branch:** `master`
- **Release:** tag `v*` → `release.yml` builds signed `Parcel.zip` + website artifact
- **CI:** push/PR → `build.yml` compiles Parcel Debug

Set repository **About → Website** to `https://parcel.parable.dev`.

## Vercel

1. Import `bswxyz/notable` in Vercel.
2. Set **Root Directory** to `Website`.
3. Framework preset: **Astro** (or use `vercel.json`).
4. Custom domain: `parcel.parable.dev`.

## Supabase

1. Create a **public** Storage bucket (e.g. `captures`).
2. In Parcel: **Preferences → Upload** — paste project URL, anon key, bucket.
3. Optional: set **Public base URL** to your CDN or `https://<project>.supabase.co/storage/v1/object/public/<bucket>`.

Never commit anon keys. Use Cursor **Supabase MCP** (authenticate in Settings → MCP) to inspect buckets from the agent.

## MCP (Cursor)

See [mcp-setup.md](mcp-setup.md). Mobbin and Higgsfield are configured in `.cursor/mcp.json`.

## App identity

| | Value |
|---|--------|
| Display name | Parcel |
| Bundle ID | `dev.parable.Parcel` |
| Legacy (Notable) | Migrated automatically via `AppIdentity.migrateFromNotableIfNeeded()` |
