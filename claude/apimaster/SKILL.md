---
name: apimaster
description: Configure, test and troubleshoot an OpenAI-compatible LLM endpoint (APIMaster or any gateway) for this project. Use when the user asks to set up an API key, switch provider or base URL, pick a model, debug a 401/404/timeout from an LLM endpoint, or add image/video generation to their code.
---

# APIMaster / OpenAI-compatible endpoint setup

Use this skill when a project needs to talk to an OpenAI-compatible LLM gateway, or when
requests to one are failing.

## Before anything else: establish the facts

Never guess the base URL, the model id or the key. Check:

```bash
npx apimaster-cli check --json          # key + both protocol families, exit code tells you what broke
npx apimaster-cli models --kind chat    # what this endpoint actually serves today
npx apimaster-cli doctor                # environment, config files, proxies, clock skew
```

Exit codes: `0` ok · `2` auth · `3` balance · `4` unreachable · `5` usage.

If `apimaster-cli` is not available, use curl:

```bash
curl -s https://apimaster.ai/v1/models -H "Authorization: Bearer $APIMASTER_API_KEY" | head -c 400
```

## The two base URLs

This is the mistake that costs people the most time:

| Protocol | Base URL | Used by |
| --- | --- | --- |
| OpenAI-compatible | `https://apimaster.ai/v1` | OpenAI SDKs, Codex, Cline, Continue, LiteLLM, Open WebUI |
| Anthropic-compatible | `https://apimaster.ai` **(no `/v1`)** | Claude Code, Anthropic SDK |

A 404 from Claude Code is almost always `/v1` left on the end of `ANTHROPIC_BASE_URL`.

## Configuring a tool

```bash
npx apimaster-cli use                    # list tools
npx apimaster-cli use claude-code --write
npx apimaster-cli use codex
```

For Claude Code, the target is `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://apimaster.ai",
    "ANTHROPIC_AUTH_TOKEN": "YOUR_API_KEY"
  }
}
```

Some builds read `ANTHROPIC_API_KEY` instead — if a 401 persists with a key you know is
good, set both.

## Writing code against the endpoint

Point the official SDK at the base URL; do not write a bespoke HTTP client.

```python
from openai import OpenAI
client = OpenAI(base_url="https://apimaster.ai/v1", api_key=os.environ["APIMASTER_API_KEY"])
```

Rules that come from measured behaviour, not from the spec:

1. **Send the full conversation history every turn.** Server-side continuation
   (`previous_response_id`, `store: true`) is not reliable on this gateway.
2. **Claude models: use `/chat/completions`, not `/responses`.** The latter returns
   `500 not implemented` for Claude ids.
3. **Parse `/responses` defensively.** Iterate `output` for the item with
   `type == "message"`; a `reasoning` item can come first, so `output[0]` is wrong.
4. **Never hardcode a model id you have not listed.** Catalogs change.

## Image and video

Images: `POST /v1/images/generations` (sync) or `/v1/images/generations/async` + poll
`GET /v1/tasks/{id}?model=...`. Videos: `POST /v1/videos/generations`, poll
`GET /v1/videos/{id}`, download `GET /v1/videos/{id}/content`.

- Sync image timeouts: 1k ≥ 180s, 2k ≥ 300s, 4k ≥ 600s. A 408 means retry via async.
- Poll pattern: wait 10–20s, then every 3–5s. `pending` is not a failure.
- Image-to-video: always set `aspect_ratio` explicitly or a portrait reference is
  treated as 16:9.
- Optional image parameters (`quality`, `background`, `output_format`) restrict which
  upstream channels can serve the request and can route to a more expensive one. Send
  only what is needed.

See `references/api-notes.md` for the full parameter tables.

## Troubleshooting map

| Symptom | First thing to check |
| --- | --- |
| 401 | Key copied with quotes or a trailing newline; wrong env var for this tool |
| 404 | `/v1` present on the Anthropic base, or missing from the OpenAI base |
| 400 "use the Images API" | A chat endpoint was called with an image model |
| 402 | Balance |
| 408 on image generation | Lower resolution, or switch to the async endpoint |
| 429 | Back off exponentially |
| Works in one shell, not another | Two different keys — `apimaster-cli check` prints which source it used |
| Hangs with no response | `HTTP_PROXY`/VPN intercepting TLS — `apimaster-cli doctor` reports these |

## Scripts in this skill

- `scripts/setup.sh` — resolve a key, verify it, write the config for a named tool
- `scripts/smoke.sh` — one chat, one image and one model-list call, printed as a pass/fail table
