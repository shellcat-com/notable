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
if rg -n -i "$forbidden_pattern" Sources/Parcel project.yml; then
  fail "Cloud/network AI identifiers found in app source"
else
  pass "No cloud/network AI identifiers in app source"
fi

network_matches="$(rg -n 'URLSession|URLRequest|NSURLConnection|WKWebView' Sources/Parcel -g '*.swift' || true)"
if [[ -z "$network_matches" ]]; then
  pass "No runtime network client APIs in app source"
elif echo "$network_matches" | awk -F: '$1 != "Sources/Parcel/Upload/UploadService.swift" { bad = 1 } END { exit bad ? 0 : 1 }'; then
  echo "$network_matches"
  fail "Runtime network APIs appear outside optional Supabase upload"
else
  echo "$network_matches"
  pass "Runtime network APIs are limited to optional Supabase upload"
fi

if rg -n 'import Vision|import NaturalLanguage|import Translation' Sources/Parcel/Vision Sources/Parcel/Capture/ScrollCapture.swift; then
  pass "Vision/translation code uses Apple local frameworks"
else
  fail "Apple local Vision/translation framework imports not found"
fi

echo
echo "--- $passes passed, $failures failed ---"
if (( failures > 0 )); then
  exit 1
fi
