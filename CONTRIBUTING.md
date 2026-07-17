# Contributing to Parcel

Thanks for helping improve Parcel. This project is MIT-licensed, SwiftUI-first, and **local-first** — no network LLM calls.

## Setup

```sh
brew install xcodegen
xcodegen generate
```

## Build

```sh
xcodebuild -project Parcel.xcodeproj -scheme Parcel -configuration Debug \
  -derivedDataPath .derivedData build CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES
open .derivedData/Build/Products/Debug/Parcel.app
```

## QA

Run through [docs/QA_CHECKLIST.md](docs/QA_CHECKLIST.md) before submitting Capture/recording changes.

## Glossary

Use canonical terms from [AGENTS.md](AGENTS.md): Capture, Selection, Overlay, Editor, Annotation, Tool, Canvas, Layer.
