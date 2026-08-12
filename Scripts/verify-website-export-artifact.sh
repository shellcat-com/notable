#!/usr/bin/env bash
# Verify the static website export contains the current public ZIP and Sparkle appcast.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBLIC_DIR="$ROOT/Website/public"
OUT_DIR="$ROOT/Website/out"

passes=0
failures=0

pass() { echo "PASS: $*"; passes=$((passes + 1)); }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

file_size() {
  if stat -f %z "$1" >/dev/null 2>&1; then
    stat -f %z "$1"
  else
    stat -c %s "$1"
  fi
}

sha256_digest() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{ print $1 }'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{ print $1 }'
  else
    echo "sha256-unavailable"
  fi
}

echo "==> Parcel website export artifact verification"
echo "    public: $PUBLIC_DIR"
echo "    out: $OUT_DIR"

if [[ -d "$OUT_DIR" ]]; then
  pass "Website/out exists"
else
  fail "Website/out is missing; run npm --prefix Website run build first"
fi

for relative in downloads/Parcel.zip appcast.xml; do
  public_file="$PUBLIC_DIR/$relative"
  out_file="$OUT_DIR/$relative"

  if [[ -f "$public_file" ]]; then
    pass "Public asset exists: $relative"
  else
    fail "Public asset missing: $relative"
    continue
  fi

  if [[ -f "$out_file" ]]; then
    pass "Exported asset exists: $relative"
  else
    fail "Exported asset missing: $relative"
    continue
  fi

  if cmp -s "$public_file" "$out_file"; then
    size="$(file_size "$out_file")"
    digest="$(sha256_digest "$out_file")"
    pass "Exported asset matches public source: $relative ($size bytes, sha256 $digest)"
  else
    fail "Exported asset differs from public source: $relative"
  fi
done

echo
echo "--- $passes passed, $failures failed ---"
if (( failures > 0 )); then
  exit 1
fi
