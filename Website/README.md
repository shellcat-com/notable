# Parcel marketing site — Next.js 16 + React 19 + Tailwind v4 + Motion

Same stack as [Parable](https://github.com/bswxyz/parable): Next.js App Router, shadcn-style tokens, and Motion animations.

## Stack

| Layer | Choice |
|-------|--------|
| Framework | Next.js 16 (static export) |
| UI | React 19 |
| Styling | Tailwind CSS v4 |
| Animation | Motion (`motion/react`) |
| Fonts | Geist Sans, Geist Mono, Instrument Serif |
| Theme | next-themes (dark default) |

## Brand colors

Edit **`lib/theme.ts`** — one file controls accent, secondary, aurora gradient, and backgrounds site-wide:

```ts
export const theme = {
  accent: "#5ee4b5",    // mint — CTAs, glow
  secondary: "#8b5cf6", // violet — icons, links
  tertiary: "#ec4899",  // fuchsia — gradient stops
  ink: "#070708",       // hero/footer background
  aurora: ["#8b5cf6", "#5ee4b5", "#ec4899"],
};
```

Variables are injected on `<html>` in `app/layout.tsx` as `--brand-*` CSS custom properties.


## Pages

| Route | Purpose |
|-------|---------|
| `/` | Product-led marketing landing — workflow, capabilities, privacy, download |
| `/docs` | User documentation index |
| `/docs/getting-started` | Install & first Capture |
| `/docs/capture` | Freeze-then-select, scroll stitch |
| `/docs/editor` | Tools, Layers, Beautify, export |
| `/docs/recording` | MP4, trim, GIF |
| `/docs/shortcuts` | Keyboard reference |
| `/docs/privacy` | On-device Vision, permissions |
| `/docs/supabase` | Optional upload setup |

Contributor architecture docs remain in the repo [`docs/`](../docs/) folder.

## Develop

```sh
cd Website
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Build

```sh
npm run build
```

Static output lands in `out/` — deployed to [parcel.parable.dev](https://parcel.parable.dev) via Vercel (root directory: `Website`).

## Deploy (Vercel)

1. Import the repo in Vercel
2. Set **Root Directory** to `Website`
3. Framework preset: **Next.js** (auto-detected)
4. Custom domain: `parcel.parable.dev`

## Public assets

| Path | Purpose |
|------|---------|
| `public/downloads/Parcel.zip` | macOS app download |
| `public/appcast.xml` | Sparkle update feed |
| `public/og.svg` | Open Graph image |
| `public/media/hero-workflow.mp4` | Silent staged Parcel workflow loop |
| `public/media/hero-workflow-poster.webp` | Reduced-motion and preload fallback |
| `public/media/workflow-*.webp` | Staged Overlay, Editor, and output campaign stills |
| `public/assets/hero-marketing.png` | Legacy campaign visual, intentionally unused |
| `public/favicon.svg` | Favicon |

Release builds copy `build/Parcel.zip` → `public/downloads/Parcel.zip` via `Scripts/release.sh`.
