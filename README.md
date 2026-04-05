# Aerospike CE Ecosystem — Workspace

Aerospike Community Edition을 위한 오픈소스 통합 도구 에코시스템의 메타 리포지토리.

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
| **[aerospike-py](https://github.com/aerospike-ce-ecosystem/aerospike-py)** | Rust/PyO3 기반 고성능 async Python 클라이언트 | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-py?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-py/releases/latest) |
| **[ACKO](https://github.com/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator)** | Kubernetes Operator — CRD 기반 선언적 CE 클러스터 관리 | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator/releases/latest) |
| **[Cluster Manager](https://github.com/aerospike-ce-ecosystem/aerospike-cluster-manager)** | 웹 관리 UI — 모니터링, Record 브라우저, Query 빌더 | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-cluster-manager?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-cluster-manager/releases/latest) |
| **[Plugins](https://github.com/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins)** | Claude Code 플러그인 — 5 Skills + 1 Agent | [![release](https://img.shields.io/github/v/release/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins?color=green)](https://github.com/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins/releases/latest) |
| **[Project Hub](https://github.com/aerospike-ce-ecosystem/project-hub)** | 중앙 문서 허브 — ADR, 목표, 로드맵 | — |

## Prerequisites

| Project | Requirements |
|---------|-------------|
| aerospike-py | Rust toolchain, Python 3.10+, [uv](https://docs.astral.sh/uv/), [maturin](https://www.maturin.rs/) |
| ACKO | Go 1.25+, [Kind](https://kind.sigs.k8s.io/), kubectl |
| Cluster Manager | Node.js 22+, [Podman](https://podman.io/) |
| Project Hub | Node.js 22+ |

## AI Development

Claude Code 플러그인을 설치하면 AI 개발 지원을 받을 수 있습니다:

```bash
claude plugin install aerospike-ce-ecosystem
```

**Skills**: `acko-deploy`, `acko-operations`, `acko-config-reference`, `aerospike-py-api`, `aerospike-py-fastapi`
**Agent**: `acko-cluster-debugger`

## Documentation

- [Project Hub](https://aerospike-ce-ecosystem.github.io/project-hub/) — 아키텍처, ADR, 로드맵
- [aerospike-py Docs](https://aerospike-ce-ecosystem.github.io/aerospike-py/) — Python 클라이언트 API
- [ACKO Docs](https://aerospike-ce-ecosystem.github.io/aerospike-ce-kubernetes-operator/) — Operator 가이드

## Working with Submodules

```bash
# SSH로 전환 (contributor)
make init-ssh

# 모든 repo 최신으로 업데이트
make pull-all

# 특정 repo에서 feature branch 작업
cd aerospike-py
git checkout -b feature/my-feature
# ... work ...
```

## License

All projects are licensed under [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
