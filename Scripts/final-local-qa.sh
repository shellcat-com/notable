#!/usr/bin/env bash
# Run Parcel checks that do not require Developer ID credentials, notarization,
# Screen Recording TCC for transient builds, Supabase credentials, extra displays, or VMs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STAMP="${STAMP:-$(date +%Y-%m-%d-%H%M%S)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$ROOT/qa-evidence/local-qa-$STAMP}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/ParcelLocalQA-$STAMP}"

mkdir -p "$EVIDENCE_DIR"/{build,privacy,recording,release,website}

run() {
  local name="$1"
  shift
  echo "==> $name"
  "$@" >"$EVIDENCE_DIR/$name.log" 2>&1
}

run build/xcodegen xcodegen generate
run build/debug-build xcodebuild -project Parcel.xcodeproj -scheme Parcel -configuration Debug -derivedDataPath "$DERIVED_DATA/debug" build
run build/release-build xcodebuild -project Parcel.xcodeproj -scheme Parcel -configuration Release -derivedDataPath "$DERIVED_DATA/release" build
run build/unit-tests xcodebuild test -project Parcel.xcodeproj -scheme ParcelUnit -configuration Debug -derivedDataPath "$DERIVED_DATA/unit"
PARCEL_APP_PATH="$DERIVED_DATA/release/Build/Products/Release/Parcel.app" run build/smoke-check swift Scripts/smoke_check.swift
run privacy/no-network-ai Scripts/verify-no-network-ai.sh
run recording/smoke-recording-finalize swift Scripts/smoke-recording-finalize.swift
run release/script-syntax bash -n \
  Scripts/release.sh \
  Scripts/verify-release.sh \
  Scripts/verify-release-gates.sh \
  Scripts/update-appcast.sh \
  Scripts/test-update-appcast.sh \
  Scripts/test-real-sparkle-signing.sh \
  Scripts/verify-sparkle-key-consistency.sh \
  Scripts/verify-no-network-ai.sh \
  Scripts/verify-workflows.sh \
  Scripts/verify-website-export-artifact.sh \
  Scripts/write-release-gate-handoff.sh \
  Scripts/write-release-manual-proof-assertions.sh \
  Scripts/verify-release-gate-evidence.sh \
  Scripts/test-release-gate-evidence.sh \
  Scripts/ship-status.sh \
  Scripts/final-local-qa.sh
run release/workflow-syntax Scripts/verify-workflows.sh
run release/release-gate-evidence-self-test Scripts/test-release-gate-evidence.sh
echo "==> release/release-preflight-hook"
if RUN_RELEASE_PREFLIGHT=1 Scripts/release.sh >"$EVIDENCE_DIR/release/release-preflight-hook.log" 2>&1; then
  echo "release_preflight_hook=pass" >"$EVIDENCE_DIR/release/release-preflight-hook.status"
else
  preflight_hook_status=$?
  if grep -Eq -- '--- [0-9]+ passed, 0 failed, [1-9][0-9]* gated ---' "$EVIDENCE_DIR/release/release-preflight-hook.log"; then
    echo "release_preflight_hook=gated status=$preflight_hook_status" >"$EVIDENCE_DIR/release/release-preflight-hook.status"
  else
    cat "$EVIDENCE_DIR/release/release-preflight-hook.log" >&2
    exit "$preflight_hook_status"
  fi
fi
run release/appcast-update-dry-run Scripts/test-update-appcast.sh
echo "==> release/sparkle-key-consistency"
if Scripts/verify-sparkle-key-consistency.sh >"$EVIDENCE_DIR/release/sparkle-key-consistency.log" 2>&1; then
  echo "sparkle_key_consistency=pass" >"$EVIDENCE_DIR/release/sparkle-key-consistency.status"
else
  sparkle_key_status=$?
  if grep -Eq -- '--- [0-9]+ passed, 0 failed, [1-9][0-9]* gated ---' "$EVIDENCE_DIR/release/sparkle-key-consistency.log"; then
    echo "sparkle_key_consistency=gated status=$sparkle_key_status" >"$EVIDENCE_DIR/release/sparkle-key-consistency.status"
  else
    cat "$EVIDENCE_DIR/release/sparkle-key-consistency.log" >&2
    exit "$sparkle_key_status"
  fi
fi
echo "==> release/sparkle-signing-dry-run"
if Scripts/test-real-sparkle-signing.sh >"$EVIDENCE_DIR/release/sparkle-signing-dry-run.log" 2>&1; then
  echo "sparkle_signing_dry_run=pass" >"$EVIDENCE_DIR/release/sparkle-signing-dry-run.status"
else
  sparkle_status=$?
  if grep -Eq -- '--- [0-9]+ passed, 0 failed, [1-9][0-9]* gated ---' "$EVIDENCE_DIR/release/sparkle-signing-dry-run.log"; then
    echo "sparkle_signing_dry_run=gated status=$sparkle_status" >"$EVIDENCE_DIR/release/sparkle-signing-dry-run.status"
  else
    cat "$EVIDENCE_DIR/release/sparkle-signing-dry-run.log" >&2
    exit "$sparkle_status"
  fi
fi
echo "==> release/gate-preflight"
if Scripts/verify-release-gates.sh >"$EVIDENCE_DIR/release/gate-preflight.log" 2>&1; then
  echo "gate_preflight=pass" >"$EVIDENCE_DIR/release/gate-preflight.status"
else
  gate_status=$?
  if grep -Eq -- '--- [0-9]+ passed, 0 failed, [1-9][0-9]* gated ---' "$EVIDENCE_DIR/release/gate-preflight.log"; then
    echo "gate_preflight=gated status=$gate_status" >"$EVIDENCE_DIR/release/gate-preflight.status"
  else
    cat "$EVIDENCE_DIR/release/gate-preflight.log" >&2
    exit "$gate_status"
  fi
fi
echo "==> release/release-gate-handoff"
handoff_dir="$EVIDENCE_DIR/release-gate-handoff"
if EVIDENCE_DIR="$handoff_dir" Scripts/write-release-gate-handoff.sh >"$EVIDENCE_DIR/release/release-gate-handoff.log" 2>&1; then
  echo "release_gate_handoff=pass" >"$EVIDENCE_DIR/release/release-gate-handoff.status"
else
  handoff_status=$?
  cat "$EVIDENCE_DIR/release/release-gate-handoff.log" >&2
  exit "$handoff_status"
fi
echo "==> release/release-gate-evidence"
if Scripts/verify-release-gate-evidence.sh "$handoff_dir" >"$handoff_dir/release-gate-evidence-current.log" 2>&1; then
  echo "release_gate_evidence=pass" >"$EVIDENCE_DIR/release/release-gate-evidence.status"
else
  evidence_status=$?
  if grep -Eq -- '--- [0-9]+ passed, 0 failed, [1-9][0-9]* gated ---' "$handoff_dir/release-gate-evidence-current.log"; then
    echo "release_gate_evidence=gated status=$evidence_status" >"$EVIDENCE_DIR/release/release-gate-evidence.status"
  else
    cat "$handoff_dir/release-gate-evidence-current.log" >&2
    exit "$evidence_status"
  fi
fi
run website/lint npm --prefix Website run lint
run website/build npm --prefix Website run build
run website/export-artifact Scripts/verify-website-export-artifact.sh

if Scripts/verify-release.sh Website/public/downloads/Parcel.zip >"$EVIDENCE_DIR/release/verify-release.log" 2>&1; then
  echo "release_verify=pass" >"$EVIDENCE_DIR/summary.txt"
else
  status=$?
  if grep -Eq -- '--- [0-9]+ passed, 0 failed, [1-9][0-9]* gated ---' "$EVIDENCE_DIR/release/verify-release.log"; then
    echo "release_verify=gated status=$status" >"$EVIDENCE_DIR/summary.txt"
  else
    echo "release_verify=fail status=$status" >"$EVIDENCE_DIR/summary.txt"
  fi
fi

{
  echo "evidence_dir=$EVIDENCE_DIR"
  echo "derived_data=$DERIVED_DATA"
  echo
  tail -n 20 "$EVIDENCE_DIR/privacy/no-network-ai.log" || true
  echo
  echo "release_script_syntax=pass"
  tail -n 20 "$EVIDENCE_DIR/release/script-syntax.log" || true
  echo
  echo "workflow_syntax=pass"
  tail -n 20 "$EVIDENCE_DIR/release/workflow-syntax.log" || true
  echo
  echo "release_gate_evidence_self_test=pass"
  tail -n 20 "$EVIDENCE_DIR/release/release-gate-evidence-self-test.log" || true
  echo
  cat "$EVIDENCE_DIR/release/release-preflight-hook.status" || true
  tail -n 25 "$EVIDENCE_DIR/release/release-preflight-hook.log" || true
  echo
  tail -n 20 "$EVIDENCE_DIR/release/appcast-update-dry-run.log" || true
  echo
  cat "$EVIDENCE_DIR/release/sparkle-key-consistency.status" || true
  tail -n 20 "$EVIDENCE_DIR/release/sparkle-key-consistency.log" || true
  echo
  cat "$EVIDENCE_DIR/release/sparkle-signing-dry-run.status" || true
  tail -n 20 "$EVIDENCE_DIR/release/sparkle-signing-dry-run.log" || true
  echo
  cat "$EVIDENCE_DIR/release/gate-preflight.status" || true
  tail -n 25 "$EVIDENCE_DIR/release/gate-preflight.log" || true
  echo
  cat "$EVIDENCE_DIR/release/release-gate-handoff.status" || true
  tail -n 5 "$EVIDENCE_DIR/release/release-gate-handoff.log" || true
  echo
  cat "$EVIDENCE_DIR/release/release-gate-evidence.status" || true
  tail -n 25 "$EVIDENCE_DIR/release-gate-handoff/release-gate-evidence-current.log" || true
  echo
  tail -n 20 "$EVIDENCE_DIR/build/unit-tests.log" || true
  echo
  tail -n 20 "$EVIDENCE_DIR/website/export-artifact.log" || true
  echo
  tail -n 20 "$EVIDENCE_DIR/release/verify-release.log" || true
} >>"$EVIDENCE_DIR/summary.txt"

Scripts/ship-status.sh "$EVIDENCE_DIR" >"$EVIDENCE_DIR/ship-status.txt"
{
  echo
  cat "$EVIDENCE_DIR/ship-status.txt"
} >>"$EVIDENCE_DIR/summary.txt"

cat "$EVIDENCE_DIR/summary.txt"
