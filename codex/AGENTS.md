# Working with an OpenAI-compatible LLM gateway

Drop this file at the root of a repo (or append it to an existing `AGENTS.md`) so Codex
and other agents stop guessing about the endpoint.

## Endpoint facts

- OpenAI-compatible base URL: `https://apimaster.ai/v1`
- Anthropic-compatible base URL: `https://apimaster.ai` — **no `/v1`**
- Key: `$APIMASTER_API_KEY`. Never inline it, never commit it, never print it.

## Before writing code that calls the API

```bash
npx @apimaster/cli check          # is the key good, and which source is it coming from
npx @apimaster/cli models --ids   # which model ids exist today
```

Do not use a model id that did not appear in that list.

## Rules for generated code

1. Use the official OpenAI SDK with `base_url` overridden. Do not hand-roll HTTP.
2. Send the whole conversation history every turn. Server-side continuation
   (`previous_response_id`, `store`) does not work reliably here.
3. Use `/chat/completions` for Claude model ids; `/responses` returns 500 for them.
4. When parsing a `/responses` payload, find the `output` item with `type == "message"`
   instead of indexing `output[0]` — a `reasoning` item may come first.
5. Read the key from the environment. If it is missing, fail with a message naming the
   variable, rather than falling back to a placeholder.
6. Retry only on 429 and 5xx, with exponential backoff. 400/401/402 are permanent.
7. Image generation is slow: set a read timeout of at least 180 s (1k), 300 s (2k),
   600 s (4k), or use the async endpoint and poll.

## Codex CLI configuration

`~/.codex/config.toml`:

```toml
model_provider = "apimaster"
model = "gpt-5.5"

[model_providers.apimaster]
name = "APIMaster"
base_url = "https://apimaster.ai/v1"
env_key = "APIMASTER_API_KEY"
wire_api = "chat"
```

Or run `npx @apimaster/cli use codex`.

## When a request fails

| Symptom | Cause |
| --- | --- |
| 401 | Key has quotes/whitespace, or the tool reads a different env var |
| 404 | `/v1` on the Anthropic base, or missing from the OpenAI base |
| 400 mentioning the Images API | A chat endpoint was called with an image model |
| 408 on image generation | Lower the resolution or switch to async |
| Hangs | `HTTP_PROXY` / VPN — run `npx @apimaster/cli doctor` |
