# Parcel Release Readiness

Use this runbook when preparing the public website ZIP. It keeps local checks, credential gates,
and final artifact verification separate so a missing external dependency is explicit.

## 1. Preflight External Gates

```sh
Scripts/verify-release-gates.sh
Scripts/write-release-gate-handoff.sh
Scripts/verify-release-gate-evidence.sh qa-evidence/final-ship-YYYY-MM-DD/release-gate-handoff-current
```

The preflight checks local tools, Developer ID identity, notary credential availability (including
the named `NOTARYTOOL_PROFILE` keychain profile), Sparkle signing material, appcast/ZIP write
access, Screen Recording verification, second-display access, Supabase live-test credentials, and
macOS 13 fallback availability.
The handoff script writes a dated `RELEASE_GATE_HANDOFF.md` packet with the exact proof files a
release machine should capture for Developer ID, notarization, TCC, second-display, Supabase,
macOS 13, appcast, final ZIP, and website deployment gates.
The evidence verifier checks that a completed packet has the expected final logs and that manual
proof notes are explicitly marked `VERIFIED: yes`. Manual proof templates are created with
`VERIFIED: no`; only change that line after the checks and metadata fields in the template are
complete. The template's packet ZIP hash is informational; fill the blank final ZIP hash after the
Developer ID signed and notarized `Website/public/downloads/Parcel.zip` is produced.

For Computer Use UI proof, capture `node_repl` + `@oai/sky` evidence against the exact final/test
`Parcel.app` path. If Sky cannot drive Parcel's menu-bar/Overlay surfaces on the release machine,
include both the failed Parcel/SystemUIServer probe output and a normal-window sanity probe proving
whether Sky itself can inspect another app window.

Expected local-only output on an uncredentialed machine is `0 failed` with one or more `GATE`
items. A public release machine should reach `0 failed, 0 gated`.

Useful inputs:

```sh
export DEVELOPMENT_TEAM=QFH99B6X5V
export NOTARYTOOL_PROFILE=parcel-release
# or:
export APPLE_ID=you@example.com
export APPLE_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx

export SPARKLE_ED_KEY_FILE=/secure/path/parcel-sparkle.key
# or SPARKLE_ED_PRIVATE_KEY / Keychain account parcel.parable.dev
export SPARKLE_KEYCHAIN_ACCOUNT=parcel.parable.dev

export PARCEL_SCREEN_RECORDING_VERIFIED=1
export PARCEL_COMPUTER_USE_VERIFIED=1
export PARCEL_SECOND_DISPLAY_VERIFIED=1
export PARCEL_SUPABASE_URL=https://example.supabase.co
export PARCEL_SUPABASE_ANON_KEY=...
export PARCEL_SUPABASE_BUCKET=captures
export PARCEL_SUPABASE_LIVE_VERIFIED=1
export PARCEL_MACOS13_VM_VERIFIED=1
```

## 2. Run Local Verification

```sh
STAMP=$(date +%Y-%m-%d-final-local) \
EVIDENCE_DIR="$PWD/qa-evidence/final-ship-$(date +%Y-%m-%d)/local-qa-current" \
DERIVED_DATA=/tmp/ParcelFinalLocalQA \
Scripts/final-local-qa.sh
```

This runs XcodeGen, Debug/Release builds, `ParcelUnit`, release smoke checks, no-network-AI
verification, recording finalization, appcast updater dry-run, release gate preflight, website
lint/build, website export asset verification, and public ZIP verification.

## 3. Build The Public ZIP

With gates satisfied:

```sh
UPDATE_APPCAST=1 \
DEVELOPMENT_TEAM=QFH99B6X5V \
NOTARYTOOL_PROFILE=parcel-release \
RELEASE_EVIDENCE_DIR="$PWD/qa-evidence/final-ship-YYYY-MM-DD/release-gate-handoff-current" \
Scripts/release.sh
```

`Scripts/release.sh` archives, exports with Developer ID, notarizes, staples, zips, copies
`build/Parcel.zip` to `Website/public/downloads/Parcel.zip`, and can update
`Website/public/appcast.xml` when Sparkle signing material is available. The appcast updater
derives title/version/build/pubDate from the final ZIP app before writing length/signature, then
validates a temporary updated appcast before replacing the source file. For a non-`SKIP_NOTARIZE`
release, it runs `Scripts/verify-release-gates.sh` before archiving and `Scripts/verify-release.sh`
against the website ZIP before exiting. When `RELEASE_EVIDENCE_DIR` is set, the release script also
writes the preflight, notarization, stapling validation, Gatekeeper, appcast-update, and final
public-ZIP verifier proof logs expected by `Scripts/verify-release-gate-evidence.sh`.

If using the Keychain-stored Sparkle key, approve the `sign_update` Keychain prompt on the release
machine. For non-interactive release jobs, provide `SPARKLE_ED_KEY_FILE` or
`SPARKLE_ED_PRIVATE_KEY`. Use `VERIFY_RELEASE=0` only for intentionally gated local packaging
experiments. Use `RUN_RELEASE_PREFLIGHT=0` only when intentionally bypassing the full
release-machine gate check.

## 4. Verify The Final Artifact

```sh
Scripts/verify-release.sh Website/public/downloads/Parcel.zip
npm --prefix Website run lint
npm --prefix Website run build
Scripts/verify-website-export-artifact.sh
```

The release verifier must report `0 failed, 0 gated` before deploying the website. Public
`Scripts/release.sh` runs the gate preflight and final verifier automatically; this manual command
is the explicit post-release double-check. `Scripts/verify-website-export-artifact.sh` proves the
static export payload contains the current `downloads/Parcel.zip` and `appcast.xml`.

## 5. Publish The Website Payload

`Website/out` is the deployable static website payload. Deploy that exact output after the final
artifact verifier and website export verifier pass. The tag-release GitHub workflow builds and
verifies this payload, uploads it as the `website-dist` artifact, and only then creates the GitHub
Release. A connected Vercel project can deploy the same payload, or you can deploy it manually from
the release runner. Do not deploy from stale repository contents unless the final generated
`Website/public/downloads/Parcel.zip` and `Website/public/appcast.xml` have also been committed.

## GitHub Release Secrets

Tagged `v*` releases use `.github/workflows/release.yml`. Configure these secrets before relying
on tag-triggered public releases:

| Secret | Notes |
|--------|-------|
| `DEVELOPMENT_TEAM` | Apple Developer Team ID. |
| `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64` | Base64-encoded Developer ID Application `.p12` certificate for CI signing. |
| `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD` | Password for the Developer ID Application `.p12`. |
| `KEYCHAIN_PASSWORD` | Optional CI keychain password; the workflow generates an ephemeral one if omitted. |
| `APPLE_ID` + `APPLE_APP_PASSWORD` | Notary credentials for CI. |
| `SPARKLE_ED_PRIVATE_KEY` | Sparkle EdDSA private key for non-interactive appcast signing. |
| `SPARKLE_KEYCHAIN_ACCOUNT` | Optional; defaults to `parcel.parable.dev`. |
| `PARCEL_SCREEN_RECORDING_VERIFIED` | Set to `1` only after exact release/test app path QA passes. |
| `PARCEL_COMPUTER_USE_VERIFIED` | Set to `1` only after menu bar, Overlay, Editor, Preferences, History, and Recording UI proof passes for the exact release/test app path. |
| `PARCEL_SECOND_DISPLAY_VERIFIED` | Set to `1` only after second-display QA passes. |
| `PARCEL_SUPABASE_URL`, `PARCEL_SUPABASE_ANON_KEY`, `PARCEL_SUPABASE_BUCKET` | Live Supabase upload QA gate. |
| `PARCEL_SUPABASE_LIVE_VERIFIED` | Set to `1` only after live Supabase upload success, disabled state, and bad-credentials behavior are verified. |
| `PARCEL_MACOS13_VM_VERIFIED` | Set to `1` only after macOS 13 fallback QA passes. |

## Current Gates

The 2026-08-12 local verification evidence is in `qa-evidence/final-ship-2026-08-12/`.
Public release remains gated until a release machine provides Developer ID signing,
notarization credentials, Screen Recording verification for the exact app path, second-display
QA proof, live Supabase credentials, and macOS 13 fallback QA. Sparkle signing now passes on this
machine against a temp appcast; the real appcast should only be signed after the final Developer ID
signed and notarized ZIP is produced.
Computer Use on this machine can inspect a normal System Settings window, but exact Parcel app-path
and SystemUIServer/menu-bar probes time out, so final Parcel UI proof remains a release-machine gate.
