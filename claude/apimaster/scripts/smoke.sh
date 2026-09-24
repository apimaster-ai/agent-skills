#!/usr/bin/env bash
# Three calls that prove an endpoint is usable: model list, chat, image.
set -uo pipefail

BASE_URL="${APIMASTER_BASE_URL:-https://apimaster.ai/v1}"
KEY="${APIMASTER_API_KEY:-}"
[ -z "$KEY" ] && { echo "APIMASTER_API_KEY is not set" >&2; exit 2; }

pass=0; fail=0
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '  ok    %s\n' "$label"; pass=$((pass+1))
  else
    printf '  FAIL  %s\n' "$label"; fail=$((fail+1))
  fi
}

echo "smoke test against ${BASE_URL}"
check "GET /models" curl -sf "${BASE_URL}/models" -H "Authorization: Bearer ${KEY}"
check "POST /chat/completions" curl -sf "${BASE_URL}/chat/completions" \
  -H "Authorization: Bearer ${KEY}" -H "Content-Type: application/json" \
  -d '{"model":"gpt-5.5","messages":[{"role":"user","content":"say ok"}],"max_tokens":5}'
check "POST /images/generations" curl -sf --max-time 240 "${BASE_URL}/images/generations" \
  -H "Authorization: Bearer ${KEY}" -H "Content-Type: application/json" \
  -d '{"model":"gpt-image-2","prompt":"a red circle on white"}'

echo "${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
