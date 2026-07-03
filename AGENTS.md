# ports

Elixir application.

## Managing agent skills

Shared skills come from the private **[`martide/skills`](https://github.com/martide/skills)** repo, managed by the [`skills`](https://github.com/vercel-labs/skills) CLI. This repo's `skills-lock.json` records what's installed and pins each skill by hash.

**Add a skill** — use the **bare SSH URL** (the source repo is private; SSH auth uses your keys):

```bash
npx skills add git@github.com:martide/skills.git                # every skill in the repo
npx skills add git@github.com:martide/skills.git -s worktrees    # just one, by name
```

Do **not** append a subpath like `…/skills/worktrees` — git reads the whole string as the repo name and the clone fails. The CLI clones the repo and discovers every `SKILL.md` inside it.

**Layout (keep the default):** real files vendor into `.agents/skills/<name>/`; `.claude/skills/<name>` is a relative symlink back to them (the shared location Codex, Gemini CLI, Copilot, etc. also read). Do **not** pass `--copy` — it breaks the symlink convention. Commit all three together: the updated `skills-lock.json`, the `.agents/skills/<name>/` files, and the `.claude/skills/<name>` symlink.

**Restore after cloning** this repo — installs everything pinned in the lockfile (the `npm ci` equivalent):

```bash
npx skills experimental_install
```

**Update** an installed skill to its latest source (omit the name to update all):

```bash
npx skills update worktrees
```

**Never hand-edit a vendored skill** under `.agents/skills/` — the next sync overwrites it. Edit the source in `martide/skills`, push, then `skills update`.
