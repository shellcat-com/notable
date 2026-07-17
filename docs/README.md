# Documentation

Everything you need to build, verify, and ship Parcel.

## Start here

| | |
|---|---|
| [architecture.md](architecture.md) | Render pipeline, coordinate rules, module map — read before touching Editor or export |
| [parity.md](parity.md) | Feature parity vs macshot reference — what's done, what's deferred |
| [QA_CHECKLIST.md](QA_CHECKLIST.md) | Manual verification matrix for Capture, recording, Vision, upload |

## Release & integrations

| | |
|---|---|
| [integrations.md](integrations.md) | GitHub, Vercel, Supabase, Mobbin, Higgsfield wiring |
| [mcp-setup.md](mcp-setup.md) | Cursor MCP configuration for connected services |
| [MACOS13_VM_QA.md](MACOS13_VM_QA.md) | macOS 13 fallback paths (written but dev-machine untested) |

## Agent / contributor guides

| | |
|---|---|
| [../AGENTS.md](../AGENTS.md) | Canonical glossary, hard constraints, project layout |
| [../CONTRIBUTING.md](../CONTRIBUTING.md) | Setup, build, PR expectations |

## Glossary (quick reference)

Use these exact terms in code and UI — no synonyms:

| Term | Meaning |
|------|---------|
| **Capture** | Grabbing pixels + the resulting full-resolution image |
| **Selection** | User-chosen region within a Capture |
| **Overlay** | Full-screen selection UI (`NSPanel` + SwiftUI) |
| **Editor** | Mark-up window for copy/save/upload |
| **Annotation** | One mark-up object (Arrow, Censor, Text, …) |
| **Tool** | Active annotation mode |
| **Canvas** | Capture + Annotations drawing surface |
| **Layer** | Z-ordered Annotation stack |
