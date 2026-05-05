# Contributing to asc-workspace

Conventions specific to this meta-repo. For changes inside a submodule, follow
that repo's own `CONTRIBUTING.md`.

## First-time setup

```bash
git clone --recursive https://github.com/aerospike-ce-ecosystem/workspace.git
cd workspace
make doctor             # verify required toolchain
make pre-commit-install # install commitlint + workspace hooks
```

`make doctor` reports missing tools with copy-pastable install hints. It does
not install anything itself.

## Where to put a change

| You're editing… | PR goes to… |
|---|---|
| Rust core or Python wrapper for the client | `aerospike-py` |
| Operator controllers, CRDs, webhooks | `aerospike-ce-kubernetes-operator` (ACKO) |
| Cluster Manager API or UI | `aerospike-cluster-manager` |
| Claude Code skill / agent definitions | `aerospike-ce-ecosystem-plugins` |
| ADR, roadmap, release matrix, public docs | `project-hub` |
| **Cross-repo glue** (Makefile, CI, top-level docs) | **this repo** |

If a single change spans multiple repos, open one PR per repo, link them, and
merge in dependency order (below).

## Cross-repo dependency order

```
aerospike-py → ACKO → cluster-manager → plugins
```

When the upstream repo changes its public surface (Python API, CRD schema, REST
endpoints), downstream repos must be updated in this order. The
`.claude/skills/cross-repo-impact/` skill traces affected files for you.

## Commit messages

Conventional Commits is enforced by the `commitlint` pre-commit hook. Allowed
types: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`.

## Architecture decisions

Workspace-wide decisions live as ADRs in
`project-hub/docs/docs/architecture/adr/`. The repo-root `CLAUDE.md` lists the
load-bearing ones.

## Releases

Each submodule releases independently with its own semver tags. **This
workspace does not release** — there is no `asc-workspace` tag.
Cross-version compatibility is tracked in
[`project-hub` › Release Matrix](https://aerospike-ce-ecosystem.github.io/project-hub/docs/history/releases/release-matrix/).
When a submodule cuts a breaking release, update the matrix in the same PR.

The workspace's [`CHANGELOG.md`](CHANGELOG.md) records changes to *this* repo
only. Submodule-pin bumps are not logged there — the `chore(submodules): bump …`
commit history is the source of truth.

## Automated submodule bumps

`.github/workflows/submodule-bump.yml` runs daily, fast-forwards each submodule
to `origin/main` (one per cycle, in dependency order), opens a PR titled
`chore(submodules): bump …`, and auto-merges (squash) once `verify` is green.

One-time setup required:

- **Allow auto-merge** enabled in repo settings
- Branch protection on `main` requires the `verify` status check
- `SUBMODULE_BUMP_TOKEN` secret with `contents: write` + `pull-requests: write`
  (a PAT or GitHub App token; the default `GITHUB_TOKEN` does not trigger
  `verify` on PRs it opens, which would block auto-merge)

To roll back a bump, revert the squash commit on `main` — the next daily run
will re-evaluate.

## Pull request checklist

- [ ] Conventional Commit subject (commitlint will reject otherwise)
- [ ] `make help` still renders, new targets documented with `## description`
- [ ] If touching CI, ran `pre-commit run --all-files` locally
- [ ] If introducing a workspace-wide convention, ADR added in `project-hub`
- [ ] `CHANGELOG.md` `[Unreleased]` updated for workspace-affecting changes
