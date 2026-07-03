---
name: worktrees
description: Use when starting parallel or isolated feature work on an org repo — a Phoenix/Ash app (jobs, crewmanager, martide/elixir) or an Astro site (blog, training) — or before executing a plan that shouldn't touch your current branch. Sets up a git worktree with its own build, and its own database + port where the stack needs them, so it never collides with siblings. Also use to run, verify, or tear down an existing worktree.
---

# worktrees

A git worktree gives you a second checkout on its own branch — that part is free. What is **not** free: each worktree needs its own build artifacts, and if the stack has shared runtime state, two worktrees fight over it.

The fix is a **slug** — one short identifier per worktree that names its branch and derives any per-worktree resource (database, port). Set it up once and the worktree stays isolated for its whole life.

**Core principle:** detect isolation → detect the stack → give the worktree its own build (plus DB + port for Phoenix) before touching it.

Two stacks, different collision surfaces:

- **Phoenix/Ash** (`mix.exs`): all worktrees share one Postgres server and the `:4000` port. Isolate both via a gitignored `config/dev.secret.exs`.
- **Astro** (`package.json` + `astro`): caches (`node_modules`, `.astro`, `.wrangler`, `dist`) are per-checkout and gitignored — already isolated. Only the dev-server port is shared, and Astro auto-increments past a busy one. Most standalone sites (blog, training, glossary, …) have **no database**, so the track is mostly "seed the build." But a D1-backed Astro app (the monorepo publics — `jobs/public`, `maritimebell/frontend` — which bind `d1_databases` in `wrangler.jsonc`) reads a local `.wrangler` D1 that starts **empty**; it must be migrated + backfilled or pages error / show no data (A1).

A **monorepo** holds both in one checkout (e.g. `maritimebell`: `backend/` Phoenix + `frontend/` Astro). One worktree spans both — run each track against its own dir. Step 1 detects this.

Known repos:

| Repo | Stack | App dir(s) | Key identifiers |
|---|---|---|---|
| `jobs` | Monorepo | `portal/` (Phoenix) + `public/` (Astro) | `Martidejobs.*`, `martidejobs_dev` |
| `crewmanager` | Phoenix | `.` (root) | `Crewmanager.*`, `crewmanager_dev` |
| `elixir` | Phoenix | `.` (root) | `Martide.*`, `dev_martide` |
| `blog`, `training`, `glossary`, `maintenance`, `manning`, `software` | Astro | `.` (root) | Astro 6 + Cloudflare; `npm run dev` |
| `maritimebell` | Monorepo | `backend/` (Phoenix) + `frontend/` (Astro) | run both tracks, one per dir |

Most repos don't gitignore `.worktrees/` — Step 2 adds it where missing.

## Step 0 — Detect existing isolation (both stacks)

You may already be in a worktree.

```bash
[ "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" ] && echo "IN WORKTREE" || echo "MAIN CHECKOUT"
git branch --show-current
```

**IN WORKTREE** → skip worktree creation; jump to your stack's setup (it still needs isolation/build).
**MAIN CHECKOUT** → ask consent before creating one: "Set up an isolated worktree? It keeps your current branch untouched."

## Step 1 — Detect the stack (both stacks)

Resolve the Elixir and Astro app dirs — a repo may have one, the other, or (monorepo) both:

```bash
ELIXIR_DIR=; for d in . portal backend; do [ -f "$d/mix.exs" ] && ELIXIR_DIR=$d && break; done
ASTRO_DIR=;  for d in . frontend public; do [ -f "$d/package.json" ] && grep -q '"astro"' "$d/package.json" && ASTRO_DIR=$d && break; done
echo "ELIXIR_DIR=${ELIXIR_DIR:-none}  ASTRO_DIR=${ASTRO_DIR:-none}"
```

- **`ELIXIR_DIR` only** → Phoenix/Ash track (with `APP_DIR=$ELIXIR_DIR`).
- **`ASTRO_DIR` only** → Astro track (run npm from `$ASTRO_DIR`).
- **both set (monorepo)** → run **both** tracks, each in its own dir — see [Monorepos](#monorepos).

All share Step 2.

## Step 2 — Create the worktree (both stacks)

Pick a **slug**: lowercase, alnum + `-`, ≤ 20 chars, unique among live worktrees (derive it from the branch or ticket, e.g. `jobs-311`).

Worktrees live in `.worktrees/` at the repo root. Ensure it's gitignored first, then create:

```bash
grep -qE '^/?\.worktrees/?' .gitignore || { printf '\n# Git worktrees\n/.worktrees/\n' >> .gitignore && git add .gitignore && git commit -m "chore: gitignore .worktrees/"; }
git worktree add ".worktrees/<slug>" -b "<slug>"
```

Never nest worktrees, and never place one in a directory that isn't gitignored. Then go to your stack's track below.

---

# Monorepos

A monorepo (both `ELIXIR_DIR` and `ASTRO_DIR` set — e.g. `maritimebell` with `backend/` + `frontend/`) is **one worktree containing both apps**. Create the single worktree in Step 2, then set up whichever side(s) you'll touch:

- Working on the backend → run the **Phoenix/Ash track** with `APP_DIR=backend` (DB + port isolation, `deps/_build` clone).
- Working on the frontend → run the **Astro track** in `frontend/` (node_modules clone).
- Touching both → run both; they're independent (Postgres/port isolation for the backend, cache clone for the frontend) and don't interfere.

The tracks below already read `$ELIXIR_DIR` / `$ASTRO_DIR`, so no monorepo-specific commands — just point each at its dir.

---

# Phoenix/Ash track

Run every `mix` command from the **app dir** (`$ELIXIR_DIR` from Step 1 — `portal/` for jobs, `backend/` for the maritimebell monorepo, root otherwise), and pass absolute paths to file tools.

## P1 — Discover this repo's names

```bash
APP_DIR=$ELIXIR_DIR; for d in portal backend; do [ -f "$d/mix.exs" ] && APP_DIR=$d; done; APP_DIR=${APP_DIR:-.}
grep -nE "Repo,|Endpoint,|database:|MIX_TEST_PARTITION|port:" "$APP_DIR/config/dev.exs" "$APP_DIR/config/test.exs"
```

Note four values: the **Repo module** (`<App>.Repo`), the **Endpoint module** (`<App>Web.Endpoint`), the **dev DB name**, and confirm the **test DB** uses `MIX_TEST_PARTITION` (all three repos do).

## P2 — Isolate DB + port

First ensure `config/dev.secret.exs` is gitignored — jobs and elixir ignore it, but **crewmanager does not**, and committing your local override would leak it. Add the rule where missing:

```bash
git check-ignore -q "$APP_DIR/config/dev.secret.exs" || { printf '\n# Local dev secrets / worktree overrides\n/config/dev.secret.exs\n' >> "$APP_DIR/.gitignore" && git add "$APP_DIR/.gitignore" && git commit -q -m "chore: gitignore config/dev.secret.exs"; }
```

Then write `$APP_DIR/config/dev.secret.exs` (imported at the end of `dev.exs`, so it wins). Substitute the discovered modules and a free port — walk up in tens from 4010, avoiding ports sibling worktrees already claimed:

```elixir
import Config

config :<otp_app>, <App>.Repo,
  database: "<dev_db>_<slug>"

config :<otp_app>, <App>Web.Endpoint,
  http: [port: <port>],
  # https reuses priv/cert self-signed certs, absent in a fresh worktree.
  # Disable it (most work doesn't need TLS); or copy priv/cert/ over and set a port.
  https: false
```

If `dev.secret.exs` already exists (Stripe keys etc.), **merge** these blocks in — don't overwrite it.

**If `dev.exs` doesn't import it** (crewmanager), add the seam once and commit it — harmless, imports only when the gitignored file exists:

```bash
printf '\nif File.exists?("config/dev.secret.exs") do\n  import_config "dev.secret.exs"\nend\n' >> "$APP_DIR/config/dev.exs"
```

The **dev DB** is now `<dev_db>_<slug>` for every `mix` command here — no env needed. The **test DB** isolates via `MIX_TEST_PARTITION` (`test.exs` has no secret-file seam). Shell env does **not** persist between commands here, so pass it inline every time:

```bash
MIX_TEST_PARTITION=<slug> mix test
```

(direnv users: an `.envrc` with `export MIX_TEST_PARTITION=<slug>` automates it — `direnv allow` the fresh worktree.)

## P3 — Seed build artifacts, then verify baseline

A fresh worktree's `deps/`, `_build/`, and `node_modules/` start empty — building cold is the slow part. **Clone them from the main checkout** so `mix setup` is incremental. On APFS, `cp -c` clones copy-on-write — near-instant:

```bash
MAIN=$(git worktree list --porcelain | awk 'NR==1{print $2}')
for d in "$APP_DIR/deps" "$APP_DIR/_build" "$APP_DIR/assets/node_modules"; do
  [ -e "$MAIN/$d" ] && { cp -Rc "$MAIN/$d" "$(dirname "$d")/" 2>/dev/null || cp -R "$MAIN/$d" "$(dirname "$d")/"; }
done
```

Then from the app dir:

```bash
mix setup                              # deps.get relinks, DB setup creates the slug DB,
                                       # compile is incremental against the cloned _build
MIX_TEST_PARTITION=<slug> mix test     # creates + verifies the slug test DB
```

Copying stale `_build` is safe: `mix compile` recompiles changed files, and `dev.secret.exs`'s overrides apply at boot, not from the cached build. Report the baseline (slug, dev/test DB, port, test count) before implementing. Don't build on a red baseline — a fresh-worktree failure is usually a stopped Postgres/OpenSearch, not your branch.

## P4 — Working in the worktree

- **Server:** `mix phx.server` → binds `:<port>`, uses `<dev_db>_<slug>`.
- **Tests:** always `MIX_TEST_PARTITION=<slug> mix test`.
- **Before committing:** `MIX_TEST_PARTITION=<slug> mix precommit` (or the repo's gate).
- **Never commit `config/dev.secret.exs`** — keep it gitignored.

## P5 — Teardown

```bash
# from the app dir, WHILE dev.secret.exs still exists (it redirects both drops)
mix ecto.drop                                          # drops <dev_db>_<slug>
MIX_ENV=test MIX_TEST_PARTITION=<slug> mix ecto.drop   # drops <test_db><slug>

# then from the MAIN checkout
git worktree remove ".worktrees/<slug>"
git branch -d <slug>                                   # if fully merged
```

Drop the databases **before** removing the worktree — once `dev.secret.exs` is gone, `mix ecto.drop` targets the shared default DB. `git worktree remove` refuses a dirty tree; don't force past it without checking what's uncommitted.

### Phoenix collision map

| Resource | Default | Isolation |
|---|---|---|
| Dev DB | `<dev_db>` | `dev.secret.exs` → `<dev_db>_<slug>` |
| Test DB | `<test_db><partition>` | `MIX_TEST_PARTITION=<slug>` |
| Dev HTTP port | `4000` | `dev.secret.exs` → `<port>` |
| `deps/`, `_build/`, `node_modules/` | per-checkout, empty | clone from main (P3), then `mix setup` |
| **Postgres server** (`:5432`) | one instance | **shared** — slug DBs live inside it; it must be running |
| Extra services | repo-specific | **shared, not slug-isolated.** `jobs` uses **OpenSearch** on `:9200` (`docker compose up -d opensearch`); its search tests are tagged `:opensearch` and excluded by default, so collisions rarely bite. Check `docker compose ps` if setup/tests fail. |

---

# Astro track

Astro build caches are per-checkout and gitignored, so a worktree is isolated once it has its own `node_modules` — and, for a D1-backed app, a migrated local D1. Run npm from `$ASTRO_DIR` (the repo root, or `frontend/` in the maritimebell monorepo).

## A1 — Seed node_modules, then verify baseline

A cold `npm install` is the slow part. **Clone `node_modules` (and Astro's `.astro` cache) from main**, then reconcile against this branch's lockfile. On APFS, `cp -c` clones copy-on-write:

```bash
cd "$ASTRO_DIR"      # repo root, or frontend/ in a monorepo
MAIN=$(git worktree list --porcelain | awk 'NR==1{print $2}')
for d in node_modules .astro; do
  [ -e "$MAIN/$ASTRO_DIR/$d" ] && { cp -Rc "$MAIN/$ASTRO_DIR/$d" . 2>/dev/null || cp -R "$MAIN/$ASTRO_DIR/$d" .; }
done
npm install          # reconciles the clone against package-lock.json — fast when node_modules is present
                     # (use `npm install`, NOT `npm ci` — ci wipes node_modules and defeats the clone)
```

**If the app binds Cloudflare D1** (its `.wrangler` D1 is per-worktree and starts empty — pages that query `env.DB` will hit missing-table errors or show no data otherwise):

```bash
if grep -qs d1_databases wrangler*.jsonc; then
  npm run d1:migrate:local      # jobs/public; else: wrangler d1 migrations apply <db> --local
  # then backfill the read-model from Phoenix — see the app's README
  # (jobs/public/README.md: run Martidejobs.D1.BackfillJob from the portal to populate local D1)
fi
```

Verify the baseline before implementing:

```bash
npm run check        # astro check — types + template diagnostics, fast
# npm test           # full gate (build + check + typecheck; training also runs Playwright) — slower
# npm run dev        # for a D1-backed app, only serves real data AFTER the migrate + backfill above
```

Report the baseline (slug, path, check result) before implementing. Don't build on a red baseline.

## A2 — Working in the worktree

- **Dev server:** `npm run dev`. Astro's default port is **4321**; if a sibling worktree already holds it, Astro auto-increments to the next free port and prints the URL — parallel `npm run dev` sessions coexist without config. To pin explicitly on a plain-`astro dev` repo (training), pass `npm run dev -- --port <n>`. `blog` wraps Astro in TinaCMS (`tinacms dev -c "astro dev"`), which doesn't forward `--port` cleanly — rely on auto-increment there.
- **Build / preview:** `npm run build`, `npm run preview`.
- **Before committing:** `npm test` (the repo's full gate) plus `npm run lint` if present.

## A3 — Teardown

No shared database to drop and no config seam to unwind — the caches (and any local `.wrangler` D1) are per-worktree and vanish with it:

```bash
# from the MAIN checkout
git worktree remove ".worktrees/<slug>"
git branch -d <slug>                       # if fully merged
```

`git worktree remove` refuses a dirty tree; check what's uncommitted before forcing.

### Astro collision map

| Resource | Default | Isolation |
|---|---|---|
| Dev-server port | `4321` | Astro auto-increments past a busy port; pin with `-- --port <n>` on plain-`astro dev` repos |
| `node_modules`, `.astro`, `.wrangler`, `dist` | per-checkout | gitignored → already isolated; clone from main (A1) only to speed setup |
| Database | — | Standalone sites read no DB (blog/training/glossary/software/manning). **D1-backed apps** (`jobs/public`, `maritimebell/frontend` — bind `d1_databases`) use a per-worktree local `.wrangler` D1: not shared, so no cross-worktree collision, but it starts **empty** — migrate + backfill it (A1). |
