# Contributing to Parcel

Thank you for helping improve Parcel. This is an MIT-licensed, SwiftUI-first, **local-first** macOS app — part of the [Parable](https://github.com/bswxyz/parable) ecosystem.

## Before you start

1. Read [AGENTS.md](AGENTS.md) for glossary, architecture constraints, and build decisions.
2. Skim [docs/architecture.md](docs/architecture.md) if your change touches Capture, Editor, or export.
3. For Capture/recording/Vision changes, plan to run [docs/QA_CHECKLIST.md](docs/QA_CHECKLIST.md).

**Non-negotiable:** no network LLM or AI calls. On-device Apple frameworks only.

## Setup

```sh
brew install xcodegen
git clone https://github.com/bswxyz/notable.git
cd notable
xcodegen generate
```

## Build & run

```sh
xcodebuild -project Parcel.xcodeproj -scheme Parcel -configuration Debug \
  -derivedDataPath .derivedData build CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES
open .derivedData/Build/Products/Debug/Parcel.app
```

Grant **Screen Recording** on first Capture, then quit and reopen Parcel.

## Website (optional)

```sh
cd Website && npm ci && npm run dev
```

## Pull requests

- Keep diffs focused — one concern per PR when possible.
- Match existing naming and patterns in the surrounding code.
- Use canonical glossary terms (Capture, not screenshot; Annotation, not shape).
- Do not regress the render pipeline: **on screen === saved**.
- Undo stack covers **annotations only** — Adjustments and Beautify stay out of ⌘Z.

Fill out the [pull request template](.github/pull_request_template.md).

## Issues

Use the [bug report](.github/ISSUE_TEMPLATE/bug_report.yml) or [feature request](.github/ISSUE_TEMPLATE/feature_request.yml) templates. Include macOS version and whether Screen Recording was granted after install.

## Code of conduct

Be direct, be kind, be precise. Parcel is a craft project — good prose in UI copy and docs matters as much as good Swift.
