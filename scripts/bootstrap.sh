#!/usr/bin/env bash
# scripts/bootstrap.sh — verify the toolchain needed to work in asc-workspace.
#
# This script DOES NOT install anything. It only inspects PATH and reports
# missing tools with a copy-pastable install hint. Run via `make doctor`.
#
# Exit code:
#   0 — all required tools present
#   1 — at least one required tool missing

set -u

# ---- Helpers ----------------------------------------------------------------
RED=$'\033[0;31m'
GRN=$'\033[0;32m'
YLW=$'\033[0;33m'
DIM=$'\033[2m'
RST=$'\033[0m'

OS="$(uname -s)"
MISSING=0

ok()    { printf "  ${GRN}✓${RST} %-14s ${DIM}%s${RST}\n" "$1" "$2"; }
warn()  { printf "  ${YLW}!${RST} %-14s ${DIM}%s${RST}\n" "$1" "$2"; }
miss()  { printf "  ${RED}✗${RST} %-14s ${DIM}%s${RST}\n" "$1" "$2"; MISSING=$((MISSING+1)); }

hint() {
  # $1 = tool name, $2 = brew formula, $3 = apt package, $4 = url fallback
  if [[ "$OS" == "Darwin" ]]; then
    printf "    install: ${DIM}brew install %s${RST}\n" "$2"
  elif [[ "$OS" == "Linux" ]]; then
    printf "    install: ${DIM}sudo apt install %s${RST}  (or distro equivalent)\n" "$3"
  fi
  [[ -n "${4:-}" ]] && printf "    docs:    ${DIM}%s${RST}\n" "$4"
}

version_of() {
  # Best-effort version probe — handles tools that reject --version (go, kubectl, helm).
  local cmd="$1" out
  out="$("$cmd" --version 2>&1 | head -n1)"
  case "$out" in
    *"unknown flag"*|*"flag provided"*|*"unrecognized"*|"")
      out="$("$cmd" version --short 2>/dev/null | head -n1)"
      [[ -z "$out" ]] && out="$("$cmd" version --client=true --short 2>/dev/null | head -n1)"
      [[ -z "$out" ]] && out="$("$cmd" version 2>/dev/null | head -n1)"
      ;;
  esac
  printf "%s" "$out"
}

check() {
  # $1 = command, $2 = pretty name, $3 = brew, $4 = apt, $5 = url, $6 = "optional"
  local cmd="$1" name="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local ver
    ver="$(version_of "$cmd")"
    ok "$name" "${ver:-installed}"
  else
    if [[ "${6:-required}" == "optional" ]]; then
      warn "$name" "not installed (optional)"
    else
      miss "$name" "not installed"
    fi
    hint "$cmd" "$3" "$4" "$5"
  fi
}

# ---- Output -----------------------------------------------------------------
echo
echo "asc-workspace toolchain check (${OS})"
echo

echo "Core:"
check git           git           git           git           "https://git-scm.com/"
check make          make          make          build-essential ""
check pre-commit    pre-commit    pre-commit    pre-commit    "https://pre-commit.com/"
check gh            "GitHub CLI"  gh            gh            "https://cli.github.com/"

echo
echo "aerospike-py (Rust + Python):"
check rustc         rustc         rust          rustc         "https://rustup.rs/"
check cargo         cargo         rust          cargo         "https://rustup.rs/"
check python3       python        python@3.12   python3       ""
check uv            uv            uv            uv            "https://docs.astral.sh/uv/"
check maturin       maturin       maturin       maturin       "https://www.maturin.rs/" optional

echo
echo "ACKO (Kubernetes operator, Go):"
check go            go            go            golang        "https://go.dev/dl/"
check kubectl       kubectl       kubectl       kubectl       "https://kubernetes.io/docs/tasks/tools/"
check kind          Kind          kind          kind          "https://kind.sigs.k8s.io/"
check helm          Helm          helm          helm          "https://helm.sh/docs/intro/install/" optional

echo
echo "cluster-manager + project-hub (Node + Podman):"
check node          Node.js       node          nodejs        "https://nodejs.org/"
check npm           npm           node          npm           ""
check podman        Podman        podman        podman        "https://podman.io/getting-started/installation"

echo
if [[ "$MISSING" -eq 0 ]]; then
  printf "${GRN}All required tools present.${RST}\n"
  exit 0
else
  printf "${RED}%d required tool(s) missing.${RST}  Install the items marked ✗ above and re-run.\n" "$MISSING"
  exit 1
fi
