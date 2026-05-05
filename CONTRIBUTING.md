# Contributing to asc-workspace

Thanks for considering a contribution. This file describes how to work *across* the
five Aerospike CE Ecosystem repos that this workspace bundles. For changes inside a
specific repo, see that repo's `CONTRIBUTING.md` (when present) — this guide only
covers workspace-level conventions.

## First-time setup

```bash
git clone --recursive https://github.com/aerospike-ce-ecosystem/workspace.git
cd workspace
make doctor             # verify required toolchain
make pre-commit-install # install commitlint + workspace hooks
```

`make doctor` reports missing tools (uv, podman, kind, rust, go, node, gh, …) with
copy-pastable install hints. It does not install anything itself — you decide.

## Where to put a change

| You're editing… | PR goes to… |
|---|---|
| Rust core or Python wrapper for the client | `aerospike-py` |
| Operator controllers, CRDs, webhooks | `aerospike-ce-kubernetes-operator` (ACKO) |
| Cluster Manager API or UI | `aerospike-cluster-manager` |
| Claude Code skill / agent definitions | `aerospike-ce-ecosystem-plugins` |
| ADR, roadmap, release matrix, public docs | `project-hub` |
| **Cross-repo glue** (Makefile, CI, top-level docs) | **this repo** |

If a single change spans multiple repos, open one PR per repo and link them in the
descriptions. Merge order follows the dependency chain below.

## Cross-repo dependency order

```
aerospike-py → ACKO → cluster-manager → plugins
```

When the upstream repo changes its public surface (Python API, CRD schema, REST
endpoints), the downstream repos must be updated in the same order. The
`.claude/skills/cross-repo-impact/` skill helps trace which downstream files need
attention; invoke it from Claude Code when planning a multi-repo change.

## Commit messages

This workspace enforces [Conventional Commits](https://www.conventionalcommits.org/)
via the `commitlint` pre-commit hook. Allowed types:

- `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`

Examples:

```
chore(submodules): bump aerospike-py to v0.9.3
feat(makefile): add doctor target for prerequisite checks
docs(contributing): document cross-repo PR workflow
```

## Architecture decisions

Workspace-wide decisions (e.g., "use Podman over Docker", "PyO3 over CFFI") live as
ADRs in `project-hub/docs/docs/architecture/adr/`. Add a new ADR when you make a
choice future contributors need to understand. The CLAUDE.md at the repo root lists
the most load-bearing ADRs.

## Releases

Each submodule releases independently with its own semver tags. **This workspace
does not release** — there is no `asc-workspace` tag. Compatibility between
submodule versions is tracked in
[`project-hub` › Release Matrix](https://aerospike-ce-ecosystem.github.io/project-hub/history/releases/release-matrix).
When a submodule cuts a release that breaks compatibility, update the matrix in the
same PR.

The workspace's own [`CHANGELOG.md`](CHANGELOG.md) records changes to *this* repo
(Makefile targets, CI workflows, top-level docs). Submodule-pin bumps are not logged
there — the commit history (`chore(submodules): bump …`) is the source of truth.

## Automated submodule bumps

`.github/workflows/submodule-bump.yml` runs daily. It walks each submodule, fast-
forwards it to `origin/main`, opens a PR titled `chore(submodules): bump …`, and
auto-merges (squash) once `verify.yml` is green. Repo settings required for this to
work:

- **Allow auto-merge** enabled in repo settings
- Branch protection on `main` requires the `verify` status check
- A token with `contents: write` and `pull-requests: write` on the workflow

If you need to roll back a bump, revert the squash commit on `main` — the next
daily run will re-evaluate and either skip or re-bump as appropriate.

## Pull request checklist

The `.github/PULL_REQUEST_TEMPLATE.md` will prompt you, but in short:

- [ ] Conventional Commit subject
- [ ] `make help` still renders, new targets documented with `## description`
- [ ] If touching CI, ran `pre-commit run --all-files` locally
- [ ] If introducing a workspace-wide convention, ADR added in `project-hub`
- [ ] CHANGELOG.md `[Unreleased]` updated for workspace-affecting changes

## Code of conduct

Be respectful, be specific, prefer reproducible repros. Security-sensitive issues
should be reported via the channel listed in each project's `SECURITY.md`, not in
public issues.
