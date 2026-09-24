# agent-skills

Drop-in skills that teach coding agents how to use an OpenAI-compatible LLM gateway —
the endpoints, the two base URLs, the behaviour that differs from the spec, and the
failure modes.

| Agent | What to install | Where |
| --- | --- | --- |
| Claude Code | `claude/apimaster/` | `~/.claude/skills/apimaster/` (personal) or `.claude/skills/apimaster/` (repo) |
| Codex / any `AGENTS.md` agent | `codex/AGENTS.md` | repo root, appended to an existing `AGENTS.md` |

## Install (Claude Code)

```bash
git clone https://github.com/apimaster-ai/agent-skills
mkdir -p ~/.claude/skills
cp -r agent-skills/claude/apimaster ~/.claude/skills/
```

Then ask Claude anything like *"set up APIMaster for this project"*, *"why am I getting a
404 from Claude Code"*, or *"add image generation to this script"* — the skill loads on its
own from the description.

## What the skill knows

- The two base URLs and which tools use which (the `/v1` trap)
- How to verify a key before writing any config file
- Which endpoint each model family needs
- The measured behaviour differences: `previous_response_id` and `store` not working,
  Claude ids failing on `/responses`, `reasoning` items preceding `message` items
- Image/video parameters, timeouts, polling cadence
- A symptom → cause troubleshooting table

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/setup.sh <tool>` | Verify the key, then write that tool's config |
| `scripts/smoke.sh` | Model list + chat + image, as a pass/fail table |

Both are plain bash with no dependencies beyond `curl` and `npx`.

## License

MIT
