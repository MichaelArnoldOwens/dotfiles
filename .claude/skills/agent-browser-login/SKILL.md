---
name: agent-browser-login
description: Use when opening Pacific's local dev environment in agent-browser and authentication is needed. Use when the user says "open Pacific in agent-browser", "browse localhost", "agent-browser login", or provides a localhost URL to test in a browser. Also use when agent-browser shows a login modal or auth redirect on Pacific.
argument-hint: "<localhost URL, e.g. http://localhost:8641/home> [--env=prod|dev]"
---

# Agent Browser Login for Pacific

Open and authenticate agent-browser against Pacific's local dev server.

## Arguments

- **URL** (required) — the page you want to land on
- **`--env=prod` | `--env=dev`** (optional, default `prod`) — sets `localStorage.dev-config-api-env` so the frontend points at the right API. When omitted, default to `prod` for testing.

## Credentials

Read at runtime from `~/.env` (bare `KEY=value` lines — no `export` prefix):

- **Email:** `$HEYGEN_EMAIL`
- **Password:** `$HEYGEN_P`

Never inline credentials in this skill file — it lives in a public dotfiles repo. Each user populates `~/.env` themselves; the repo never ships real values.

Load them into the current shell before any agent-browser commands:

```bash
set -a; source ~/.env; set +a
```

If `~/.env` is missing OR `HEYGEN_EMAIL` is empty, prompt the user before proceeding:

```bash
if [[ ! -f ~/.env ]] || ! grep -q '^HEYGEN_EMAIL=' ~/.env; then
  cat <<'EOF'
~/.env not found (or missing HEYGEN_EMAIL). Create it with:

  cat > ~/.env <<'INNER'
  HEYGEN_EMAIL=you@heygen.com
  HEYGEN_P=your-password
  INNER
  chmod 600 ~/.env

(File format is bare KEY=value, no `export` prefix. `set -a; source ~/.env; set +a` exports
them into the agent-browser process.)
EOF
  exit 1
fi
```

Stop and ask the user — never invent credentials, never store them in this file, never echo them to Slack or logs.

## Bootstrap Flow (run this every time)

This is the single entry point. It does: open → pre-flight auth check → auto re-login if expired → env switch if needed → verify.

### 1. Open with saved session

```bash
agent-browser --session-name pacific open <URL> --wait domcontentloaded
```

### 2. Pre-flight auth probe

Hit a real authenticated endpoint on the **absolute API domain** and require a JSON body.
Two traps make the obvious checks unreliable on localhost — avoid both:

- **A relative `fetch('/api/...')` is useless here.** On localhost the app talks to an
  *absolute* API domain (`api2.heygen.com` / `api2.heygendev.com`); there is no `/api` route
  on the Vite dev server (its only dev proxy is mounted at `/api-proxy`, used only on the
  `dev.heygen.com` host). Vite's SPA history-fallback then serves `index.html` with
  **HTTP 200 + `text/html`** for the unmatched path, so a status-only relative probe reports
  `200` regardless of auth — a false positive that silently skips login.
- **DOM nav (`Avatar`/`Projects`/`Home`) is not an auth signal** — the top nav renders for
  anonymous visitors too. An anonymous `/translate` shows "Free plan … 1 minute"; only a real
  account shows e.g. "Enterprise plan … 300 minutes".

The HttpOnly auth cookie is sent on a credentialed cross-origin fetch to the API domain, so
this probe works from localhost:

```bash
# Pick the host for the target env (prod is the default):
API_HOST="https://api2.heygen.com"        # --env=prod (default)
# API_HOST="https://api2.heygendev.com"   # --env=dev

RESULT=$(agent-browser eval "fetch('$API_HOST/v1/account/usage', {credentials:'include'}).then(async r => { const ct=r.headers.get('content-type')||''; return (r.status===200 && ct.includes('application/json')) ? 'AUTHED' : 'NEEDS_LOGIN:'+r.status; })" 2>&1 | tail -1)
```

- `AUTHED` (200 + JSON) → authenticated, skip to step 4
- `NEEDS_LOGIN:401` / `:403` → expired, go to step 3
- anything else (network error, non-JSON) → go to step 3 and confirm via the login modal

Fallback DOM check (only meaningful on `/create-v4/`, which renders the login modal when
unauthenticated):

```bash
agent-browser snapshot -i 2>&1 | grep -qE "Continue with email|Use email|Log in|Sign in" && echo "NEEDS_LOGIN"
```

### 3. Re-login if expired

Jump to **First-Time Login Flow** below. After it completes, the session is persisted under `--session-name pacific` again.

### 4. Set API env (defaults to `prod`)

The default env is **`prod`** for testing. Set it when `--env` is specified, when the bottom-right DevConfig badge shows the wrong env, or whenever you're unsure (a no-op reload is cheap):

```bash
agent-browser eval "localStorage.setItem('dev-config-api-env', '<ENV>'); document.cookie = 'dev-config-api-env=<ENV>; path=/; max-age=31536000'; 'done'"
agent-browser reload
```

Replace `<ENV>` with the resolved env — `prod` when `--env` is omitted, otherwise the value passed. Env is persisted by `--session-name`, so once it matches you can skip this on later runs.

### 5. Verify

```bash
agent-browser snapshot -i 2>&1 | grep -E "Avatar|Projects|Home"
```

If nav buttons are present and (if env was set) the bottom-right DevConfig badge matches, you're done.

**IMPORTANT:** Do NOT use `/login` or `/` to check auth status — these routes render blank in headless mode. Use `/avatar` or `/create-v4/` instead.

## First-Time Login Flow

If the session is expired or doesn't exist, you'll see a login modal. Follow these steps:

### Step 1: Open with session persistence

Navigate to `/create-v4/` — this route reliably shows the login modal when unauthenticated:

```bash
agent-browser --session-name pacific open http://localhost:8081/create-v4/ --wait networkidle
```

If the user provided a specific URL, try that URL first. If it shows a login modal, proceed from there.

### Step 2: Wait for login modal and click "Continue with email"

```bash
agent-browser snapshot -i   # Find the "Continue with email" button ref
agent-browser click @eN      # Click it (replace @eN with actual ref)
```

### Step 3: Switch to password mode

```bash
agent-browser snapshot -i   # Find "Use password instead" button ref
agent-browser click @eN      # Click it
```

### Step 4: Fill credentials and handle Cloudflare

```bash
agent-browser snapshot -i   # Find email input, password input, and Cloudflare iframe refs
agent-browser fill @eEMAIL "$HEYGEN_EMAIL"
agent-browser fill @ePASS "$HEYGEN_P"
agent-browser click @eTURNSTILE   # Click the Cloudflare "Verify you are human" iframe
sleep 3                            # Wait for Cloudflare to resolve
```

### Step 5: Submit login

```bash
agent-browser snapshot -i   # Find "Log in" button ref — confirm it's NOT disabled
agent-browser click @eLOGIN
sleep 5                      # Wait for auth to complete
```

### Step 6: Verify authentication

```bash
agent-browser snapshot -i 2>&1 | grep -E "Avatar|Projects|Home"
```

If nav buttons are present, login succeeded. The session is now saved under `--session-name pacific` and will persist across restarts.

## Viewport

The default viewport is too short. After opening, set a proper size:

```bash
agent-browser set viewport 1280 900
```

## Switching API Environment (dev/prod)

The DevConfig badge in the bottom-right corner shows the current API environment (`[dev]` or `[prod]`). To switch:

```bash
agent-browser eval "localStorage.setItem('dev-config-api-env', 'prod'); document.cookie = 'dev-config-api-env=prod; path=/; max-age=31536000'; 'done'"
agent-browser reload
```

Replace `'prod'` with `'dev'` to switch back. The page will reload with the new environment.

## Overriding feature flags locally

Pacific keeps local flag overrides in `localStorage['local-feature-flags']` as a JSON map of `flagKey → variant`. The override modal at `packages/movio/src/components/feature-flags/HeygenLocalOverridesOverridesModal.tsx` writes to this key on save and reads it on mount; `posthog.featureFlags.overrideFeatureFlags(...)` then applies the overrides to the running session.

Set or update an override (merges with existing overrides — does not clobber other flags):

```bash
agent-browser eval "(()=>{const k='local-feature-flags';const o=JSON.parse(localStorage.getItem(k)||'{}');o['avatar-management-redesign']='test';localStorage.setItem(k,JSON.stringify(o));return 'set: '+JSON.stringify(o);})()"
agent-browser reload
```

Replace `avatar-management-redesign` and `test` with your flag key + target variant. Boolean flags accept `true`/`false` (no quotes); multi-variant flags take a variant string (`'control'` / `'test'` / etc.).

Clear a single override:

```bash
agent-browser eval "(()=>{const k='local-feature-flags';const o=JSON.parse(localStorage.getItem(k)||'{}');delete o['avatar-management-redesign'];localStorage.setItem(k,JSON.stringify(o));return 'now: '+JSON.stringify(o);})()"
agent-browser reload
```

Clear all overrides:

```bash
agent-browser eval "localStorage.removeItem('local-feature-flags'); 'cleared'"
agent-browser reload
```

Inspect current overrides:

```bash
agent-browser eval "localStorage.getItem('local-feature-flags') || 'none'"
```

**Caveat for ENTERPRISE_HOLDOUT_VARIANTS flags.** The override modal effect (see `HeygenLocalOverridesOverridesModal.tsx` line ~126) deletes any local override pinned to the `enterprise_holdout` variant on mount — that variant cannot be force-set locally, only `'control'` / `'test'`. For other variant schemes (`TOGGLE` boolean, `DEFAULT_VARIANTS`, `ENUM`) the override applies as written.

**UI alternative** (only visible on non-prod / `localdev` / `vercelPreview` builds): a small red rotated `Flags` badge appears in the bottom-right corner of any Pacific page. Click it to open the overrides modal and toggle flags interactively. Both the modal and the snippets above write to the same localStorage key, so they are interchangeable.

## Waiting for Pacific Pages to Fully Load

Pacific (especially `/create-v4/`) loads async data (draft, avatar, voice) after the initial DOM render. Screenshots taken too early will show loading spinners or black screens.

**Never use a fixed `sleep` for screenshots.** Instead, use this pattern:

```bash
# 1. Navigate
agent-browser --session-name pacific open <URL> --wait domcontentloaded

# 2. Set viewport
agent-browser set viewport 1280 900

# 3. Poll for a meaningful DOM element (max 15s, check every 2s)
for i in 1 2 3 4 5 6 7; do
  SNAP=$(agent-browser snapshot -i 2>&1)
  if echo "$SNAP" | grep -qE "<expected heading or element>"; then
    break
  fi
  sleep 2
done

# 4. Screenshot AFTER content is confirmed present
agent-browser screenshot /tmp/my-screenshot.png
```

**Key rules:**
- Use `--wait domcontentloaded` (not `networkidle` — it often times out on Pacific)
- Poll `snapshot -i` for a specific heading or element, not a generic wait
- For studio (`/create-v4/`), expect 5-10s for draft data to load
- Always `Read` the screenshot file to verify it visually before uploading to S3
- Use timestamped filenames to avoid CDN cache issues: `my-screenshot-$(date +%s).png`

**Common assertions by panel:**

| Panel | Expected in snapshot |
|-------|---------------------|
| Scene home | `heading "Avatar & Voice"` |
| Voice | `heading "Edit Voice"` |
| Looks | `heading "<AvatarName>"` + `"Add a look"` |
| Motion Style | `heading "Choose Your Motion Style"` |
| Model Settings | `heading "Customize Motion"` |
| Avatar (private) | `tab "My Avatars" [selected` |
| Avatar (public) | `tab "Public Avatars" [selected` |
| Design with AI | `heading "Design Look With AI"` |
| Media | `heading "Media"` |
| Elements | `heading "Elements"` |
| Music | `heading "Music"` |

## Fast Path (Optional)

Alternatives to the manual login flow that skip Cloudflare Turnstile. Both require a one-time human login and go stale when the auth cookie expires — fall back to the **Bootstrap Flow** above when they do.

### A. Reuse your real Chrome profile

Works if you've previously logged into the dev API domain (e.g. `heygendev.com`) in your normal Chrome.

```bash
agent-browser --profile Default --session-name pacific open http://localhost:8081/create-v4/
```

agent-browser copies the profile read-only, so your regular Chrome keeps working. No need to close it on macOS.

### B. Export state from a debug Chrome

One-time setup: launch Chrome with remote debugging, log in to Pacific manually (Turnstile + all), then export the state.

```bash
# One-time (solve Turnstile yourself in this window):
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 &
# ...log in to Pacific in that Chrome window...
agent-browser --auto-connect state save ~/.agent-browser-pacific-auth.json

# Every run after:
agent-browser --session-name pacific state load ~/.agent-browser-pacific-auth.json
agent-browser --session-name pacific open http://localhost:8081/create-v4/
```

Re-export when auth expires.

## Starting / Restarting the Local Dev Server

The zsh `dev` function (defined in `~/dev-server-tools/shell/zsh/dev-server-tools.zsh`, sourced from `~/.zshrc`; source repo: `github.com/heygen-com/dev-server-tools`) is the **preferred** way to start Pacific's local dev server. In a pacific worktree it hashes `$PWD` into a stable, worktree-unique port triple (movio, auth, videos) and launches all three in parallel, so multiple worktrees never collide.

### Cheat sheet

```bash
# From the pacific worktree root (zsh):
dev          # starts movio + auth + videos in parallel; prints all 3 URLs.
             # Builds the DEV bundle — this is what you want: the in-browser API
             # ENV switcher (dev/pre/prod, incl. custom subdomain) then works at
             # runtime, so you can point a dev build at the prod API. This is the
             # combo the Bootstrap Flow's `--env=prod` relies on.
dev prod     # builds the PROD bundle instead. Only when you specifically need to
             # test the prod-built bundle. A prod build can NOT be flipped to the
             # dev API at runtime ("invalid domain"), so do NOT use this for
             # normal agent-browser testing — use plain `dev` + `--env` instead.

# From anywhere inside a pacific worktree:
dev-list     # list all running dev servers (movio port, branch, dir, tmux session)
dev-stop     # stop the dev server for the current worktree's port
             #   (walks up from $PWD reading /tmp/dev-ports/<md5>.port,
             #    then kills the whole pnpm/run-p tree — leaf vite won't respawn)
dev-stop 8641   # explicit port form
dev-open     # open the current worktree's dev URL in the browser
```

**Build env vs runtime API env — don't conflate them.** `dev` / `dev prod` choose the *build* (which domain mapping is bundled). The skill's `--env=prod` (Bootstrap step 4) sets the *runtime* API target via `localStorage['dev-config-api-env']`. For prod-API testing, use **plain `dev` (dev build) + `--env=prod`**, never `dev prod`.

### Port scheme

For a given worktree path, ports are deterministic:

```
movio_port  = (md5(PWD) % 1000) + 8081      # base, bumped on collision
auth_port   = movio_port + 9
videos_port = movio_port + 1000
```

`dev` bumps all three together if any are in use. The **movio port** is what agent-browser should hit.

### Discovering ports without re-running `dev`

If `dev` is already running in another terminal/pane, the worktree's movio port is in `/tmp/dev-ports/<md5(worktree_path)>.port`:

```bash
# zsh / bash, from inside the worktree:
cat /tmp/dev-ports/$(printf '%s' "$PWD" | md5 -q).port
```

If the file is missing → `dev` isn't running for that worktree; start it.

### Sample output

```
→ Branch: my-feature
→ API:    dev
→ movio:  http://localhost:8641
→ auth:   http://localhost:8650
→ videos: http://localhost:9641
```

`→ API:` is the **build** env (`dev` unless you ran `dev prod`) — not the runtime API target. Use the printed **movio** port (or the `.port` file) as the agent-browser URL.

### When HMR stops working

Sometimes Vite's HMR breaks silently — local code changes don't reflect in the browser. When this happens:

1. `dev-stop` from anywhere in the worktree (kills the whole pnpm tree cleanly)
2. Re-run `dev` from the same pacific worktree root
3. It picks the same port (stable hash), so no agent-browser URL change needed

### `dev` vs `pnpm dev`

Both avoid cross-worktree collisions now — `pnpm dev` runs `scripts/dev-with-worktree-ports.mjs`, which slot-shifts the defaults (8081 / 8090 / 5173) by `slot * 10`. **Prefer `dev`** because it:

- registers `/tmp/dev-ports/` state files, so `dev-list` / `dev-stop` / `dev-open` / the tmux button can find and manage the server (plain `pnpm dev` does not);
- gives a **stable** hash-based port per worktree (same every run), vs `pnpm dev`'s first-free slot which can shift between runs;
- filters `@pacific/auth` out of the turbo deps task so auth isn't double-started on the base port.

Use `pnpm dev` only if the `dev` function isn't available.

### Tmux status-bar button

If tmux is wired per `~/dev-server-tools/README.md`, a green `▶ branch:port` button appears bottom-right when `dev` is running for the active pane's worktree. Click it to open the URL. Empty when `dev` isn't running.

## Important Notes

- **Always use `--session-name pacific`** — this saves/restores all cookies (including HttpOnly auth tokens) and localStorage across browser close/reopen.
- **The auth token is an HttpOnly cookie** set by the backend on the API domain. It cannot be extracted or injected via `document.cookie`. The only way to get it is by completing the login flow.
- **Port doesn't matter** — the auth token lives on the API domain, not localhost. Switching ports (8081, 8641, etc.) won't invalidate the session.
- **Snapshots are more reliable than screenshots** — the visual render often shows a loading spinner in headless mode even when the DOM is fully loaded. Use `snapshot -i` to check page state.
- **Cloudflare Turnstile** appears on the login form. Click the iframe ref, wait 3 seconds, then proceed. The checkbox auto-resolves for agent-browser.
- **Do NOT use `/login` or `/`** — these routes render blank in headless mode. Use `/avatar` or `/create-v4/` instead.
