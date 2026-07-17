# Aerospike CE Ecosystem — Workspace

This meta-repository brings together six open-source projects for developing and operating Aerospike Community Edition. Each project remains an independent Git repository and is included here as a submodule.

```bash
git clone --recursive https://github.com/aerospike-ce-ecosystem/workspace.git
```

## Quick Start

Clone the workspace recursively so that Git checks out every project at the version recorded by the workspace.

```bash
cd workspace
make init       # Initialize submodules if the clone omitted --recursive
make status     # Show the status of every repository
make pull-all   # Update every repository to the latest main branch
```

## What's Inside

| Project | Description | Release |
|---------|-------------|:-------:|
| **[aerospike-py](https://github.com/aerospike-ce-ecosystem/aerospike-py)** | High-performance async Python client built on Rust/PyO3 | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-py?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-py/releases/latest) |
| **[ACKO](https://github.com/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator)** | Kubernetes Operator — declarative CE cluster management via CRD | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator/releases/latest) |
| **[Cluster Manager](https://github.com/aerospike-ce-ecosystem/aerospike-cluster-manager)** | Web management UI — monitoring, Record browser, Query builder | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-cluster-manager?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-cluster-manager/releases/latest) |
| **[ackoctl](https://github.com/aerospike-ce-ecosystem/ackoctl)** | CLI for Cluster Manager — connections, records, queries, indexes, and K8s CRs | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/ackoctl?color=green)](https://github.com/aerospike-ce-ecosystem/ackoctl/releases/latest) |
| **[Plugins](https://github.com/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins)** | Claude Code plugin — 9 skills, no separate agent | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins/releases/latest) |
| **[Project Hub](https://github.com/aerospike-ce-ecosystem/project-hub)** | Central documentation hub — ADRs, goals, roadmap | — |

## Prerequisites

| Project | Requirements |
|---------|-------------|
| aerospike-py | Rust toolchain, Python 3.10+, [uv](https://docs.astral.sh/uv/), [maturin](https://www.maturin.rs/) |
| ACKO | Go 1.25+, [Kind](https://kind.sigs.k8s.io/), kubectl |
| Cluster Manager | Node.js 22+, [Podman](https://podman.io/) |
| ackoctl | Go 1.25+ |
| Project Hub | Node.js 22+ |

## AI Development

Install the Claude Code plugin to add Aerospike-specific deployment, operations, API, and troubleshooting guidance:

```bash
claude plugin install aerospike-ce-ecosystem
```

**Skills**: `acko-deploy`, `acko-operations`, `acko-config-reference`, `acko-e2e-test`, `ackoctl`, `acko-debugging`, `aerospike-py-api`, `aerospike-py-fastapi`, `bug-reporter`

## Documentation

- [Project Hub](https://aerospike-ce-ecosystem.github.io/project-hub/) — architecture, ADRs, roadmap
- [Release Matrix](https://aerospike-ce-ecosystem.github.io/project-hub/docs/history/releases/release-matrix/) — submodule version compatibility
- [aerospike-py Docs](https://aerospike-ce-ecosystem.github.io/aerospike-py/) — Python client API
- [ACKO Docs](https://aerospike-ce-ecosystem.github.io/aerospike-ce-kubernetes-operator/) — Operator guide

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md) explains where to submit a change, how cross-repository work is ordered, and which commit and release conventions apply. [CHANGELOG.md](CHANGELOG.md) records changes to this meta-repository only.

## Working with Submodules

```bash
# Use SSH URLs when contributing
make init-ssh

# Update every repository to its latest main branch
make pull-all

# Create a feature branch in one repository
cd aerospike-py
git checkout -b feature/my-feature
# ... work ...
```

## License

Every project is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
