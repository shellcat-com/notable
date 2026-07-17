# Parcel marketing site (Astro + Tailwind + React islands)

Parable-inspired motion and layout; deploy as static output.

## Develop

```bash
cd Website
npm install
npm run dev
```

## Build

```bash
npm run build
npm run preview
```

Output lands in `Website/dist/`. Point Vercel or GitHub Pages at that directory.

## Downloads

Place a notarized `Parcel.zip` at `public/downloads/Parcel.zip` before deploying, or run `Scripts/release.sh` which copies the artifact automatically.

Sparkle appcast: `public/appcast.xml` — update `sparkle:edSignature` and `length` after each release.

The previous vanilla HTML draft lives in `legacy/`.
