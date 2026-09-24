#!/usr/bin/env bash
# Configure a tool against an OpenAI-compatible endpoint, verifying before writing.
#
#   ./setup.sh claude-code
#   ./setup.sh codex --base-url https://apimaster.ai/v1
set -euo pipefail

TOOL="${1:-claude-code}"
shift || true
BASE_URL="https://apimaster.ai/v1"
while [ $# -gt 0 ]; do
  case "$1" in
    --base-url) BASE_URL="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "${APIMASTER_API_KEY:-}" ]; then
  echo "APIMASTER_API_KEY is not set." >&2
  echo "  export APIMASTER_API_KEY=sk-...   # get one at https://apimaster.ai/docs/getting-started/api-key" >&2
  exit 2
fi

echo "==> verifying the key against ${BASE_URL}"
npx --yes @apimaster/cli check --base-url "$BASE_URL" --skip-chat || {
  echo "Key check failed — not writing any config." >&2
  exit 1
}

echo "==> writing config for ${TOOL}"
npx --yes @apimaster/cli use "$TOOL" --base-url "$BASE_URL" --write

echo "==> done. Verify with:"
case "$TOOL" in
  claude-code) echo "    claude   # then /model claude-sonnet-4-6" ;;
  codex)       echo "    codex \"print hello\"" ;;
  *)           echo "    npx @apimaster/cli ping \$(npx @apimaster/cli models --ids | head -1)" ;;
esac
