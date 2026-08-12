#!/usr/bin/env bash
# Summarize Parcel release-readiness evidence into a compact status report.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVIDENCE_DIR="${1:-$ROOT/qa-evidence/final-ship-2026-08-12/local-qa-current}"
AUDIT_PATH="${AUDIT_PATH:-$ROOT/qa-evidence/final-ship-2026-08-12/REQUIREMENTS_AUDIT.md}"

if [[ ! -d "$EVIDENCE_DIR" ]]; then
  echo "ERROR: evidence directory not found: $EVIDENCE_DIR" >&2
  exit 1
fi

extract_counts() {
  local path="$1"
  if [[ -f "$path" ]]; then
    sed -n 's/^--- \([0-9][0-9]*\) passed, \([0-9][0-9]*\) failed, \([0-9][0-9]*\) gated ---$/\1 \2 \3/p' "$path" | tail -n 1
  fi
}

extract_plain_counts() {
  local path="$1"
  if [[ -f "$path" ]]; then
    sed -n 's/^--- \([0-9][0-9]*\) passed, \([0-9][0-9]*\) failed ---$/\1 \2/p' "$path" | tail -n 1
  fi
}

audit_counts() {
  if [[ ! -f "$AUDIT_PATH" ]]; then
    echo "0 0 0 0"
    return
  fi
  awk -F'|' '
    /^\| [^|]+ \| [A-Z\/]+ \|/ && $2 !~ /Requirement/ {
      total += 1
      status = $3
      gsub(/[[:space:]]/, "", status)
      if (status == "PASS") pass += 1
      else if (status == "PASS/GATED") pass_gated += 1
      else if (status == "GATED") gated += 1
    }
    END { print total + 0, pass + 0, pass_gated + 0, gated + 0 }
  ' "$AUDIT_PATH"
}

percent() {
  local numerator="$1"
  local denominator="$2"
  if (( denominator == 0 )); then
    echo "0"
  else
    awk -v n="$numerator" -v d="$denominator" 'BEGIN { printf "%d", int(((n / d) * 100) + 0.5) }'
  fi
}

read -r audit_total audit_pass audit_pass_gated audit_gated < <(audit_counts)
local_done=$((audit_pass + audit_pass_gated))
evidence_percent="$(percent "$local_done" "$audit_total")"
public_percent="$(percent "$audit_pass" "$audit_total")"

release_counts="$(extract_counts "$EVIDENCE_DIR/release/verify-release.log" || true)"
gate_counts="$(extract_counts "$EVIDENCE_DIR/release/gate-preflight.log" || true)"
sparkle_sign_counts="$(extract_counts "$EVIDENCE_DIR/release/sparkle-signing-dry-run.log" || true)"
sparkle_key_counts="$(extract_counts "$EVIDENCE_DIR/release/sparkle-key-consistency.log" || true)"
handoff_counts="$(extract_counts "$EVIDENCE_DIR/release-gate-handoff/release-gate-evidence-current.log" || true)"
handoff_self_test_counts="$(extract_plain_counts "$EVIDENCE_DIR/release/release-gate-evidence-self-test.log" || true)"

echo "# Parcel Ship Status"
echo
echo "Evidence: $EVIDENCE_DIR"
echo
echo "Requirement audit:"
echo "- Total requirements: $audit_total"
echo "- Fully passed: $audit_pass"
echo "- Locally passed but externally gated: $audit_pass_gated"
echo "- Externally gated: $audit_gated"
echo "- Evidence-backed completion: ${evidence_percent}%"
echo "- Public release unblocked: ${public_percent}%"
echo

if [[ -n "$release_counts" ]]; then
  read -r passed failed gated <<<"$release_counts"
  echo "Release artifact verifier: $passed passed, $failed failed, $gated gated"
fi
if [[ -n "$gate_counts" ]]; then
  read -r passed failed gated <<<"$gate_counts"
  echo "Release-machine preflight: $passed passed, $failed failed, $gated gated"
fi
if [[ -n "$sparkle_key_counts" ]]; then
  read -r passed failed gated <<<"$sparkle_key_counts"
  echo "Sparkle key consistency: $passed passed, $failed failed, $gated gated"
fi
if [[ -n "$sparkle_sign_counts" ]]; then
  read -r passed failed gated <<<"$sparkle_sign_counts"
  echo "Sparkle signing dry-run: $passed passed, $failed failed, $gated gated"
fi
if [[ -n "$handoff_counts" ]]; then
  read -r passed failed gated <<<"$handoff_counts"
  echo "Release gate evidence packet: $passed passed, $failed failed, $gated gated"
fi
if [[ -n "$handoff_self_test_counts" ]]; then
  read -r passed failed <<<"$handoff_self_test_counts"
  echo "Release gate evidence verifier self-test: $passed passed, $failed failed"
fi

echo
echo "Remaining gates:"
if [[ -f "$AUDIT_PATH" ]]; then
  awk -F'|' '
    /^\| [^|]+ \| (GATED|PASS\/GATED) \|/ {
      item = $2
      status = $3
      detail = $4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", item)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", detail)
      print "- " item " (" status "): " detail
    }
  ' "$AUDIT_PATH"
fi
