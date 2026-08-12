#!/usr/bin/env bash
# Verify Parcel's app source contains no cloud/network AI integrations.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

passes=0
failures=0

pass() { echo "PASS: $*"; passes=$((passes + 1)); }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

echo "==> Parcel no-network-AI verification"

forbidden_pattern='OpenAI|ChatGPT|Anthropic|Claude|Gemini|generativelanguage|Mistral|Cohere|Perplexity|Replicate|HuggingFace|api\.openai|bedrock-runtime|AzureOpenAI|Raycast AI'
if command -v rg >/dev/null 2>&1; then
  forbidden_matches="$(rg -n -i "$forbidden_pattern" Sources/Parcel project.yml || true)"
else
  forbidden_matches="$({
    find Sources/Parcel -type f \( \
      -name '*.swift' -o -name '*.plist' -o -name '*.entitlements' \
      -o -name '*.xcprivacy' -o -name '*.json' \
    \) -exec grep -EniH "$forbidden_pattern" {} +
    grep -EniH "$forbidden_pattern" project.yml
  } 2>/dev/null || true)"
fi
if [[ -n "$forbidden_matches" ]]; then
  echo "$forbidden_matches"
  fail "Cloud/network AI identifiers found in app source"
else
  pass "No cloud/network AI identifiers in app source"
fi

if command -v rg >/dev/null 2>&1; then
  network_matches="$(rg -n 'URLSession|URLRequest|NSURLConnection|WKWebView' Sources/Parcel -g '*.swift' || true)"
else
  network_matches="$(find Sources/Parcel -type f -name '*.swift' -exec grep -EnH 'URLSession|URLRequest|NSURLConnection|WKWebView' {} + || true)"
fi
if [[ -z "$network_matches" ]]; then
  pass "No runtime network client APIs in app source"
elif echo "$network_matches" | awk -F: '$1 != "Sources/Parcel/Upload/UploadService.swift" { bad = 1 } END { exit bad ? 0 : 1 }'; then
  echo "$network_matches"
  fail "Runtime network APIs appear outside optional Supabase upload"
else
  echo "$network_matches"
  pass "Runtime network APIs are limited to optional Supabase upload"
fi

if command -v rg >/dev/null 2>&1; then
  framework_matches="$(rg -n 'import Vision|import NaturalLanguage|import Translation' Sources/Parcel/Vision Sources/Parcel/Capture/ScrollCapture.swift || true)"
else
  framework_matches="$(grep -REn 'import Vision|import NaturalLanguage|import Translation' Sources/Parcel/Vision Sources/Parcel/Capture/ScrollCapture.swift || true)"
fi
if [[ -n "$framework_matches" ]]; then
  echo "$framework_matches"
  pass "Vision/translation code uses Apple local frameworks"
else
  fail "Apple local Vision/translation framework imports not found"
fi

echo
echo "--- $passes passed, $failures failed ---"
if (( failures > 0 )); then
  exit 1
fi
