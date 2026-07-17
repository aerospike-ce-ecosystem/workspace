# Contributing to the Aerospike CE Ecosystem Workspace

This guide covers changes to the workspace itself and work that spans more than one repository. When you edit a submodule, also follow that repository's `CONTRIBUTING.md`.

## First-time setup

```bash
git clone --recursive https://github.com/aerospike-ce-ecosystem/workspace.git
cd workspace
make doctor             # verify required toolchain
make pre-commit-install # install commitlint + workspace hooks
```

`make doctor` checks the required tools and prints installation hints for anything missing. It does not install software.

## Where to put a change

| You're editing… | PR goes to… |
|---|---|
| Rust core or Python wrapper for the client | `aerospike-py` |
| Operator controllers, CRDs, webhooks | `aerospike-ce-kubernetes-operator` (ACKO) |
| Cluster Manager API or UI | `aerospike-cluster-manager` |
| Claude Code skill / agent definitions | `aerospike-ce-ecosystem-plugins` |
| ADR, roadmap, release matrix, public docs | `project-hub` |
| **Cross-repo glue** (Makefile, CI, top-level docs) | **this repo** |

If a change spans several repositories, open and link one PR per repository. Merge them in the dependency order shown below.

## Cross-repo dependency order

```
aerospike-py → ACKO → cluster-manager → plugins
```

When an upstream repository changes a public interface such as the Python API, CRD schema, or REST endpoint, update its consumers in this order. The `.claude/skills/cross-repo-impact/` Skill can identify likely downstream files.

## Commit messages

The `commitlint` pre-commit hook enforces Conventional Commits. Allowed types are `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, and `test`.

## Architecture decisions

Record workspace-wide decisions as ADRs in `project-hub/docs/docs/architecture/adr/`. The root `CLAUDE.md` points to the decisions that most directly affect cross-repository work.

## Releases

Each submodule releases independently with its own SemVer tags. **The workspace itself does not publish releases** and has no `asc-workspace` tag. The [`project-hub` Release Matrix](https://aerospike-ce-ecosystem.github.io/project-hub/docs/history/releases/release-matrix/) tracks compatible versions. When a submodule publishes a breaking release, update the matrix as part of the coordinated change.

The workspace [`CHANGELOG.md`](CHANGELOG.md) records changes to this repository only. It does not list submodule pointer updates; use the `chore(submodules): bump …` commit history for those changes.

## Automated submodule bumps

`.github/workflows/submodule-bump.yml` runs every day. It fast-forwards one submodule per cycle to `origin/main`, following dependency order, and opens a `chore(submodules): bump …` PR. Once the `verify` check passes, the workflow squash-merges the PR automatically.

Repository administrators must complete this setup once:

- **Allow auto-merge** enabled in repo settings
- Branch protection on `main` requires the `verify` status check
- `SUBMODULE_BUMP_TOKEN` secret with `contents: write` + `pull-requests: write`
  Use a PAT or GitHub App token. The default `GITHUB_TOKEN` does not trigger `verify` for PRs it creates, so those PRs cannot satisfy the auto-merge requirement.

To roll back a submodule update, revert its squash commit on `main`. The next daily run will evaluate the pointer again.

## Pull request checklist

- [ ] Conventional Commit subject (commitlint will reject otherwise)
- [ ] `make help` still renders, new targets documented with `## description`
- [ ] If touching CI, ran `pre-commit run --all-files` locally
- [ ] If introducing a workspace-wide convention, ADR added in `project-hub`
- [ ] `CHANGELOG.md` `[Unreleased]` updated for workspace-affecting changes
