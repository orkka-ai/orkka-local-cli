# Orkka Local

Run Orkka's full AI-dev-team pipeline **on your own machine, for free**, using your own
AI subscription — Claude, ChatGPT/Codex, Gemini, or GitHub Copilot — or **fully offline
with local Ollama models** (no subscription at all). No API key, no credit card, no
cloud account: agents execute through the vendor CLIs you're already logged into, work
in git worktrees over your real local repos, and merge results back into them. Any one
connected provider runs the pipeline (the QA browser-testing lane needs Claude
specifically).

```
┌─ Docker (lightweight core) ────────────┐   ┌─ Your machine ──────────────────────┐
│ postgres                               │   │ orkka-local (runner)                │
│ orkka-local-host   127.0.0.1:6752      │◄──┤  • spawns `claude` with YOUR login  │
│ orkka-local-ui     127.0.0.1:6750      │   │  • git worktrees over YOUR repos    │
└────────────────────────────────────────┘   │  • YOUR toolchains (npm, dotnet, …) │
                                             └─────────────────────────────────────┘
```

The split matters: the containers are the dumb core (DB, API, UI). All the trusted
work — Claude auth, git, running your tests — happens in a small runner process on the
host, the same model as a self-hosted CI runner. It cannot live in a container.

## Install

Prerequisites: **Docker** (running) and **at least one AI provider ready** — Claude
(`claude /login`, Pro/Max subscription; use the native installer, not npm), Codex
(`codex login`, ChatGPT subscription), Gemini (API key — Google shut down the CLI's
free personal Google-account sign-in in June 2026: create a free key at
[aistudio.google.com/apikey](https://aistudio.google.com/apikey) and save it on the
Orkka Local **Settings page** once the stack is up — every agent run and Muse's image
generation receive it automatically. File-based alternatives on the runner machine:
`GEMINI_API_KEY=<your key>` in `~/.gemini/.env` plus
`"selectedAuthType": "gemini-api-key"` in `~/.gemini/settings.json` — Orkka mirrors
`~/.gemini/.env` into every task workspace, so one file covers local and
cloud-cloned repos; `ORKKA_GEMINI_API_KEY` in `~/.orkka/stack.env` works too), GitHub
Copilot (`copilot login`, paid Copilot plan — note every agent run consumes premium
requests from your Copilot quota), or **Ollama** for a no-subscription setup: install
[Ollama](https://ollama.com), pull a coding model (`ollama pull gpt-oss:20b`), and
install the free Codex CLI (`npm install -g @openai/codex` — no OpenAI account needed;
it supplies the agent harness that drives your local models).

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/ruanpelissoli/orkka-local-cli/main/install.ps1 | iex
```

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/ruanpelissoli/orkka-local-cli/main/install.sh | bash
```

## Run

```
orkka-local start
```

First run pulls the images, generates local secrets in `~/.orkka/`, waits for the API,
opens http://localhost:6750, and keeps running as the agent runner — leave the window
open while you work. Other commands: `orkka-local stop`, `orkka-local status`.

## Update

```
orkka-local update
```

Updates the binary to the latest release and pulls the latest container images, then
restart with `orkka-local start`. (Re-running the install one-liner works too.)

First steps in the UI: create a project → **Repos** → add your local repo folders →
write a task → watch your team take it from Drafting to a reviewed, mergeable PR.

## How it behaves (things worth knowing)

- **Everything binds to 127.0.0.1.** This stack is not meant to face a network. Ports:
  UI 6750, API 6752, Postgres 5433 (debugging convenience only — override with
  `ORKKA_PG_PORT=<port>` in `~/.orkka/stack.env` if 5433 is taken).
- **Agents use your subscription.** Task/plan/review runs are one task at a time
  (concurrency 1) and count against your Claude plan's usage limits, exactly as if you
  ran `claude` yourself. Rate-limit messages surface in the task timeline.
- **Claude keeps logging you out?** Parallel claude processes share one credentials
  file, and its refresh token is single-use — concurrent runs can race a refresh and
  invalidate your login. The fix: run `claude setup-token` (prints a long-lived token),
  add `CLAUDE_CODE_OAUTH_TOKEN=<token>` to `~/.orkka/stack.env`, and Orkka authenticates
  every agent with it from the next run on (no restart needed). `orkka-local doctor claude`
  shows which auth mode is in effect.
- **Terms of service:** Orkka Local drives the `claude` CLI in headless mode under your
  personal login. Review Anthropic's current commercial terms and make your own call —
  this project doesn't extract or proxy your credentials (the runner never reads them;
  only the `claude` process does).
- **Your repos are the source of truth.** The runner keeps a bare mirror under
  `~/.orkka/repos` whose origin IS your repo; agent branches (`orkka/task-…`) land
  directly in your repo, and merging a PR squash-merges inside it (requires a clean
  tree with the base branch checked out).
- **Chat agents read your original repo paths** (read-only tools) — same trust model
  as running `claude` in that folder yourself.
- **Design assets and diagrams live in Docker volumes**, not loose files on your
  machine: Muse's images in the data volume, Archie's diagrams in the database. Muse
  authors SVGs out of the box; to enable raster images/GIFs, save a Gemini API key on
  the Settings page (effective immediately, no restart) or add
  `ORKKA_GEMINI_API_KEY=<your key>` to `~/.orkka/stack.env` and run `orkka-local start`
  again (either way the same key also authenticates Gemini dev agents if you use them).
- **Git LFS files appear as pointers** to agents (smudge is disabled so nothing can
  hang a headless checkout). Fine for code; binary-heavy workflows will notice.
- **Dev-phase worktrees** live next to your repo in a `{repo}-worktrees` sibling folder
  (e.g. `C:\Code\my-app` → `C:\Code\my-app-worktrees\task-…`) so you can watch agents
  work; they are cleaned up after merge.

## Uninstall

```
orkka-local uninstall
```

Removes the stack, its Docker volumes, and `~/.orkka` (your own repos are never
touched).

## Support

Something not working? [Open an issue](https://github.com/ruanpelissoli/orkka-local-cli/issues).

## About this repository

This repo hosts the Orkka Local **distribution**: the install scripts above and the
release binaries under [Releases](https://github.com/ruanpelissoli/orkka-local-cli/releases),
published automatically by Orkka's CI. The container images live on GHCR
(`ghcr.io/ruanpelissoli/orkka-local-host`, `ghcr.io/ruanpelissoli/orkka-local-ui`) and
are pulled automatically by `orkka-local start`.
