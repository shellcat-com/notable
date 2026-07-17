# Security policy

## Supported versions

| Version | Supported |
|---------|-----------|
| Latest release on `master` / tagged `v*` | Yes |
| Older tags | Best effort |

## Reporting a vulnerability

**Please do not open a public GitHub issue for security-sensitive reports.**

Email or DM the maintainer with:

1. Description of the issue and impact
2. Steps to reproduce
3. Affected macOS version and Parcel build (Debug vs Release)
4. Proof-of-concept if available

Parcel is a local-first menu bar app. Areas of interest:

- ScreenCaptureKit / TCC permission handling
- Supabase upload credentials storage (UserDefaults — user-provided keys only)
- Sandbox entitlements in Release builds
- Sparkle update signature verification

We aim to acknowledge reports within **72 hours** and ship fixes in the next tagged release when confirmed.

## Out of scope

- Issues requiring physical access to an unlocked Mac
- Missing Screen Recording permission (expected TCC behavior)
- Ad-hoc Debug builds without notarization (dev builds are unsigned by design)
