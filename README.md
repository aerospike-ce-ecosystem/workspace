# Aerospike CE Ecosystem — Workspace

A meta-repository for the open-source integrated tooling ecosystem for Aerospike Community Edition.

```bash
git clone --recursive https://github.com/aerospike-ce-ecosystem/workspace.git
```

## Quick Start

```bash
cd workspace
make init       # Initialize all submodules (if not using --recursive)
make status     # Check repo status
make pull-all   # Update all repos to latest main
```

## What's Inside

| Project | Description | Release |
|---------|-------------|:-------:|
| **[aerospike-py](https://github.com/aerospike-ce-ecosystem/aerospike-py)** | High-performance async Python client built on Rust/PyO3 | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-py?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-py/releases/latest) |
| **[ACKO](https://github.com/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator)** | Kubernetes Operator — declarative CE cluster management via CRD | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator/releases/latest) |
| **[Cluster Manager](https://github.com/aerospike-ce-ecosystem/aerospike-cluster-manager)** | Web management UI — monitoring, Record browser, Query builder | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-cluster-manager?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-cluster-manager/releases/latest) |
| **[Plugins](https://github.com/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins)** | Claude Code plugin — 5 Skills + 1 Agent | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins/releases/latest) |
| **[Project Hub](https://github.com/aerospike-ce-ecosystem/project-hub)** | Central documentation hub — ADRs, goals, roadmap | — |

## Prerequisites

| Project | Requirements |
|---------|-------------|
| aerospike-py | Rust toolchain, Python 3.10+, [uv](https://docs.astral.sh/uv/), [maturin](https://www.maturin.rs/) |
| ACKO | Go 1.25+, [Kind](https://kind.sigs.k8s.io/), kubectl |
| Cluster Manager | Node.js 22+, [Podman](https://podman.io/) |
| Project Hub | Node.js 22+ |

## AI Development

Install the Claude Code plugin to get AI-assisted development support:

```bash
claude plugin install aerospike-ce-ecosystem
```

**Skills**: `acko-deploy`, `acko-operations`, `acko-config-reference`, `aerospike-py-api`, `aerospike-py-fastapi`
**Agent**: `acko-cluster-debugger`

## Documentation

- [Project Hub](https://aerospike-ce-ecosystem.github.io/project-hub/) — architecture, ADRs, roadmap
- [Release Matrix](https://aerospike-ce-ecosystem.github.io/project-hub/history/releases/release-matrix) — submodule version compatibility
- [aerospike-py Docs](https://aerospike-ce-ecosystem.github.io/aerospike-py/) — Python client API
- [ACKO Docs](https://aerospike-ce-ecosystem.github.io/aerospike-ce-kubernetes-operator/) — Operator guide

## Contributing

Cross-repo workflow, dependency order, commit conventions, and the daily
auto-bump policy are documented in [CONTRIBUTING.md](CONTRIBUTING.md).
Workspace-only changes are tracked in [CHANGELOG.md](CHANGELOG.md).

## Working with Submodules

```bash
# Switch to SSH (contributor)
make init-ssh

# Update all repos to latest
make pull-all

# Work on a feature branch in a specific repo
cd aerospike-py
git checkout -b feature/my-feature
# ... work ...
```

## License

All projects are licensed under [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
