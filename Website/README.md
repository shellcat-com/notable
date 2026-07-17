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

Visual components (`DitherAurora`, `ShimmerButton`, `VelocityMarquee`) are adapted from the Parable registry.

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
| `public/favicon.svg` | Favicon |

Release builds copy `build/Parcel.zip` → `public/downloads/Parcel.zip` via `Scripts/release.sh`.
