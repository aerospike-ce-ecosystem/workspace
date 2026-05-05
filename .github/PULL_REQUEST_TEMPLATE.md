<!--
  asc-workspace meta-repo PR template.
  This repo holds Makefile, CI workflows, and top-level docs only.
  For changes inside a submodule, open the PR in that submodule's repo and
  link it here under "Related PRs".
-->

## What changed

<!-- One or two sentences. Why is this needed? -->

## Area touched

- [ ] Makefile / scripts (developer commands)
- [ ] `.github/workflows/*` or `dependabot.yml` (CI)
- [ ] Top-level docs (README / CLAUDE.md / CONTRIBUTING / CHANGELOG)
- [ ] Submodule pin bump
- [ ] Other (describe below)

## Cross-repo impact

- [ ] No downstream impact
- [ ] Affects `aerospike-py` consumers — linked PR: #
- [ ] Affects `ACKO` consumers — linked PR: #
- [ ] Affects `cluster-manager` consumers — linked PR: #
- [ ] Affects `plugins` skills — linked PR: #
- [ ] Release Matrix updated in `project-hub` — linked PR: #

## Verification

<!-- Tick everything you ran locally. -->

- [ ] `make help` renders (new targets carry a `## description`)
- [ ] `pre-commit run --all-files` is clean
- [ ] If a new Makefile target was added, it was actually executed
- [ ] If touching `.github/workflows/`, it was validated with `gh workflow view`
      or run via `workflow_dispatch` on a fork

## CHANGELOG

- [ ] `CHANGELOG.md` `[Unreleased]` updated, OR
- [ ] Change is a submodule-pin bump (auto-bump workflow handles these — no
      changelog entry needed)
