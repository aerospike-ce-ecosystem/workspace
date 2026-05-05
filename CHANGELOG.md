# Changelog

All notable changes to **this workspace** (the meta-repo) are documented in this
file. Submodule changes are tracked in their own repos and aggregated in the
[Release Matrix](https://aerospike-ce-ecosystem.github.io/project-hub/docs/history/releases/release-matrix/).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Workspace itself does not carry a semver tag — entries are dated.

## [Unreleased]

### Added
- `make doctor` target and `scripts/bootstrap.sh` — toolchain prerequisite checker
  (uv, podman, kind, rust, go, node, pre-commit, gh).
- `make dev` — bring up the cluster-manager dev compose stack
  (3-node Aerospike CE + Postgres + API + UI, detached).
- `make start-kind` — delegate to cluster-manager's `kind-up` for local Kubernetes.
- `make clean` — clean build artifacts across all submodules + Docusaurus cache.
- `make format-all` — auto-format py + ACKO sources (cluster-manager has no
  format-only target; it uses `lint`).
- `make test-all` — run `test-py`, `test-acko`, `test-cm` sequentially.
- `CONTRIBUTING.md` — cross-repo workflow, dependency order, Conventional Commits,
  release policy.
- `.github/` — PR / issue templates, `verify.yml` workspace smoke check,
  `submodule-bump.yml` daily auto-bump with squash auto-merge, `dependabot.yml`
  for GitHub Actions updates.
- `.gitignore` entries for `aerocm/`, `node_modules/`, `dist/`, `.cache/` at the
  workspace root.

### Removed
- `aerocm/` directory — local-only experiment that was never tracked
  (88 MB of node_modules + build output). Now ignored at the workspace root in
  case it gets regenerated.

### Changed
- README links to the Release Matrix and CONTRIBUTING.

[Unreleased]: https://github.com/aerospike-ce-ecosystem/workspace/commits/main
