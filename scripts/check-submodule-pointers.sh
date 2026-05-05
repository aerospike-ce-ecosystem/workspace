#!/usr/bin/env bash
# scripts/check-submodule-pointers.sh — assert each submodule pin is either
# an ancestor of origin/main or an annotated tag. Prevents accidental drift
# (e.g., pinning to a personal-fork SHA) from landing on main.
#
# Used by .github/workflows/verify.yml.

set -uo pipefail

DRIFT=0

# Parse .gitmodules directly so we work on bash 3.2 (macOS default) too —
# `mapfile` is bash 4+ only.
SUBMODULES="$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')"

for sub in $SUBMODULES; do
  if [[ ! -d "$sub/.git" && ! -f "$sub/.git" ]]; then
    printf "  SKIP   %s — not initialized in this checkout\n" "$sub"
    continue
  fi

  pushd "$sub" >/dev/null
  current="$(git rev-parse HEAD)"
  short="$(git rev-parse --short HEAD)"

  # Refresh main + tags so the check is meaningful in CI.
  git fetch --quiet origin main 2>/dev/null || true
  git fetch --quiet --tags origin 2>/dev/null || true

  if git merge-base --is-ancestor "$current" origin/main 2>/dev/null; then
    printf "  OK     %s @ %s is on origin/main\n" "$sub" "$short"
  elif git describe --exact-match --tags "$current" >/dev/null 2>&1; then
    tag="$(git describe --exact-match --tags "$current")"
    printf "  OK     %s @ %s is tag %s\n" "$sub" "$short" "$tag"
  else
    printf "  DRIFT  %s @ %s is not on origin/main and not a tag\n" "$sub" "$short"
    DRIFT=1
  fi
  popd >/dev/null
done

if [[ "$DRIFT" -ne 0 ]]; then
  echo
  echo "One or more submodule pins drifted off main. Either bump them to a"
  echo "main-merged commit or to an annotated release tag, then push again."
  exit 1
fi
