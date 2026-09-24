# Endpoint reference

Condensed from https://apimaster.ai/docs and verified against the live API.
Load this file when you need exact parameters; the main skill file has the rules.

## Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/v1/models` | Current catalog, OpenAI format |
| POST | `/v1/chat/completions` | Chat, all text models |
| POST | `/v1/responses` | Responses API (GPT ids only) |
| POST | `/v1/images/generations` | Image, synchronous |
| POST | `/v1/images/generations/async` | Image, returns `data[0].task_id` |
| GET | `/v1/tasks/{id}?model=<id>` | Image task status |
| POST | `/v1/videos/generations` | Video job (native shape) |
| POST | `/v1/videos` | Video job (OpenAI Video shape) |
| GET | `/v1/videos/{id}` | Video job status |
| GET | `/v1/videos/{id}/content` | MP4 download (send the bearer token) |
| POST | `/v1/messages` on `https://apimaster.ai` | Anthropic Messages (note: no `/v1` in the base) |

## Image parameters

| Field | Required | Notes |
| --- | --- | --- |
| `model` | yes | `gpt-image-2`, `doubao-seedream-5-0-pro-260628`, `gemini-3.1-flash-image`, `midjourney-v8.2`, `midjourney-niji-7` |
| `prompt` | yes | Goes through content moderation |
| `n` | no | Max depends on the serving channel |
| `size` | no | `auto`, `1:1`, `3:2`, `2:3`, `4:3`, `3:4`, `5:4`, `4:5`, `16:9`, `9:16`, `2:1`, `1:2`, `3:1`, `1:3`, `21:9`, `9:21`, or pixels (`1881x836`) |
| `resolution` | no | `1k` (default), `2k`, `4k` |
| `image_urls` | no | Up to 16; public URLs and `data:image/png;base64,…` can be mixed |
| `mask_url` | no | Inpainting; must match the first reference's size and carry alpha |
| `quality` / `background` / `output_format` / `output_compression` / `moderation` | no | **These narrow the eligible channels and can raise the price.** Omit unless required. |

Resolution → pixels (excerpt): `1:1` is 1024², 2048², 2880²; `16:9` is 1536×864,
2048×1152, 3840×2160.

Sync response: `{ "created": …, "data": [{ "url": "…" }] }`
Async submit: `{ "code": 200, "data": [{ "status": "submitted", "task_id": "…" }] }`
Async result path: `data.result.images[0].url[0]`

Task statuses: `submitted` (submit response only) → `pending` / `processing` /
`in_progress` → `completed` | `failed` | `error` | `cancelled`.

## Video parameters

Native shape, `POST /v1/videos/generations`:

| Field | Notes |
| --- | --- |
| `model` | `sora-2`, `sora-2-pro`, `seedance-2.5`, `seedance-2.0`, `kling-v3-motion-control`, `kling-v3-omni`, `MiniMax-H3`, `grok-imagine-video-1.5`; `sora` maps to `sora-2` |
| `prompt` | required |
| `duration` | 4 / 8 / 12 / 16 / 20, default 4 |
| `resolution` | `720p`; `sora-2-pro` also `1024p`, `1080p` |
| `aspect_ratio` | `16:9` (default) or `9:16` — **always set this for image-to-video** |
| `image_urls` | one public URL for image-to-video |

OpenAI-compatible shape, `POST /v1/videos`: `seconds` (string), `size`
(`1280x720`, `720x1280`, `1792x1024`, `1024x1792`), `images`. An unsupported `size`
returns `400 invalid_size`, and this path tops out at 1024p.

Billing is per second: sora-2 720p $0.08/s; sora-2-pro $0.24 / $0.40 / $0.56 per second
at 720p / 1024p / 1080p.

## Behaviour that differs from the OpenAI spec

Measured, not assumed:

- `previous_response_id` returns `null` and does not continue context.
- `store: true` comes back as `false`.
- There is no reachable WebSocket transport for `/v1/responses`.
- Claude ids on `/v1/responses` return `500 not implemented`.

Therefore: full history in every request, and `/chat/completions` for Claude.

## Error codes

| HTTP | Meaning | Retry? |
| --- | --- | --- |
| 400 | Bad parameters or wrong endpoint for the model | no |
| 401 | Bad key | no |
| 402 | No balance | no |
| 408 | Generation timed out | yes, lower resolution or go async |
| 429 | Rate limited | yes, exponential backoff |
| 500 / 502 / 503 | Upstream | yes, bounded |

## Timeouts

| Job | Client read timeout |
| --- | --- |
| Chat | 60 s is plenty |
| Image 1k | ≥ 180 s |
| Image 2k | ≥ 300 s |
| Image 4k | ≥ 600 s |
| Video | poll instead; jobs take 1–3 minutes |
