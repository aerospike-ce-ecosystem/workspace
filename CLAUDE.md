# Aerospike CE Ecosystem — Workspace

5개 프로젝트를 submodule로 통합하는 메타 리포지토리.
`git clone --recursive`로 전체 개발 환경을 한 번에 구성.

---

## 왜 이 에코시스템이 존재하는가

Aerospike Community Edition(CE)에는 다음 도구가 부재:

- **공식 Kubernetes Operator 부재** — Enterprise AKO는 있지만 CE용 Operator 없음
- **모던 Python 클라이언트 부재** — 기존 C 바인딩(CFFI) 기반, async/타입 힌트 미흡
- **통합 관리 UI 부재** — CE 클러스터 웹 관리 도구 없음
- **AI 개발 도구 부재** — Aerospike 특화 AI 어시스턴트 없음

이 에코시스템이 4가지 공백을 모두 채움.

---

## Repository Map

| Repo | Path | Tech Stack | Purpose |
|------|------|-----------|---------|
| **aerospike-py** | `aerospike-py/` | Rust/PyO3 + Tokio, Python 3.10-3.14 | 고성능 async Python 클라이언트 (2.4x faster than C client) |
| **ACKO** | `aerospike-ce-kubernetes-operator/` | Go 1.25, kubebuilder v4, controller-runtime v0.23 | K8s CE 클러스터 Operator (CRD 기반 선언적 관리) |
| **Cluster Manager** | `aerospike-cluster-manager/` | FastAPI + Next.js 16, React 19, Tailwind CSS 4 | 웹 관리 UI (모니터링, Record 브라우저, Query 빌더, K8s 관리) |
| **Plugins** | `aerospike-ce-ecosystem-plugins/` | Claude Code plugin spec | 5 Skills + 1 Agent (AI 개발 지원) |
| **Project Hub** | `project-hub/` | Docusaurus v3.9 | 중앙 문서 허브 — ADR 40+건, 목표, 로드맵, 릴리스 매트릭스 |

각 repo에 자체 CLAUDE.md가 있으므로 해당 repo 작업 시 반드시 참조할 것.

---

## Architecture (3 Layers)

```
Layer 1 — Agent + Plugin     : aerospike-ce-ecosystem-plugins (Claude Code)
Layer 2 — Tools              : aerospike-py, ACKO, aerospike-cluster-manager
Layer 3 — Infrastructure     : Aerospike CE on K8s (via ACKO) or bare metal
```

사용자는 Layer 1(AI)이나 Layer 2(도구)를 통해 Layer 3(인프라)를 관리.
각 프로젝트는 독립 사용 가능 (Loose Coupling). 연동은 선택적(opt-in).

---

## Dependency & Merge Order

```
aerospike-py → ACKO → cluster-manager → plugins
```

| Repo | 의존 관계 |
|------|----------|
| **aerospike-py** | standalone — 외부 의존 없음 |
| **ACKO** | cluster-manager를 submodule로 포함 (UI 배포용) |
| **cluster-manager** | aerospike-py를 백엔드에서 사용, ACKO API와 연동하여 K8s 클러스터 관리 |
| **plugins** | 모든 repo의 API/CRD를 skill 콘텐츠로 참조 |

### Cross-Repo 영향 범위

- aerospike-py API 변경 → cluster-manager 백엔드 + plugins skill 동시 업데이트
- ACKO CRD 변경 → cluster-manager K8s UI + plugins skill 동시 업데이트
- 릴리스 시 Release Compatibility Matrix 업데이트 필수 (`project-hub/docs/docs/history/releases/`)

---

## CE Constraints (ACKO Webhook 강제)

| 제약 | 상세 |
|------|------|
| 최대 노드 수 | 8 |
| 최대 Namespace 수 | 2 |
| XDR | 사용 불가 |
| TLS | 사용 불가 |
| Security (enterprise auth) | 사용 불가 |
| 이미지 | CE 전용 (`aerospike/aerospike-server-enterprise` 불가) |

CE 제약은 ACKO Webhook이 CRD 생성 시점에 검증.
Enterprise 기능 사용 시도 시 명확한 에러 메시지 제공.

---

## Key Documentation

| 문서 | 경로 / URL |
|------|-----------|
| **Project Hub (배포)** | https://aerospike-ce-ecosystem.github.io/project-hub/ |
| **ADR (40+ 건)** | `project-hub/docs/docs/architecture/adr/` |
| **프로젝트 목표** | `project-hub/docs/docs/goals/project-goals.md` |
| **설계 철학** | `project-hub/docs/docs/goals/project-design.md` |
| **Q2 2026 로드맵** | `project-hub/docs/docs/roadmap/current.md` |
| **aerospike-py 문서** | https://aerospike-ce-ecosystem.github.io/aerospike-py/ |
| **ACKO 문서** | https://aerospike-ce-ecosystem.github.io/aerospike-ce-kubernetes-operator/ |

### 주요 ADR

| ADR | 결정 |
|-----|------|
| PyO3 over CFFI | Rust/PyO3로 메모리 안전성 + GIL-free async |
| Kubebuilder v4 | CRD codegen + envtest 지원 |
| Podman over Docker | Rootless, daemonless 컨테이너 런타임 |
| NamedTuple over Dict | IDE 자동완성 + 타입 안전성 |
| Pod Readiness Gates | Zero-downtime rolling update |
| Reconciliation Circuit Breaker | API server 과부하 방지 |
| IssueOps CI | AI 에이전트 기반 자동 구현 워크플로우 |

---

## Development Commands

이 workspace의 Makefile로 cross-repo 작업 수행:

| Command | 설명 |
|---------|------|
| `make init` | 모든 submodule 초기화 (recursive) |
| `make init-ssh` | submodule URL을 SSH로 전환 후 초기화 |
| `make pull-all` | 모든 submodule main branch로 최신 pull |
| `make status` | 각 submodule git status 확인 |
| `make branches` | 각 submodule 현재 branch 확인 |
| `make log-all` | 각 submodule 최근 3 commit |
| `make build-py` | aerospike-py 빌드 (Rust + Python) |
| `make test-py` | aerospike-py 유닛 테스트 |
| `make build-acko` | ACKO operator 빌드 |
| `make test-acko` | ACKO 테스트 |
| `make test-cm` | cluster-manager 테스트 |
| `make lint-all` | 전체 repo lint |
| `make start-aerospike` | 로컬 Aerospike CE 컨테이너 시작 |
| `make start-kind` | Kind 클러스터 생성 (ACKO E2E용) |

---

## AI Development Skills

### Plugin 설치

```bash
claude plugin install aerospike-ce-ecosystem
```

### 사용 가능한 Skills

| Skill | 트리거 | 용도 |
|-------|--------|------|
| `acko-deploy` | "deploy Aerospike on Kubernetes" | CE K8s 배포 (8개 시나리오 YAML 포함) |
| `acko-operations` | "scale Aerospike cluster" | Day-2 운영 (스케일, 업그레이드, 동적 설정, 트러블슈팅) |
| `acko-config-reference` | (background) | CE 8.1 설정 파라미터, CRD 매핑, Webhook 검증 |
| `aerospike-py-api` | "use aerospike-py" | Python 클라이언트 전체 API 레퍼런스 |
| `aerospike-py-fastapi` | "FastAPI + Aerospike" | FastAPI 프로덕션 패턴 |

### Agent

| Agent | 용도 |
|-------|------|
| `acko-cluster-debugger` | K8s 클러스터 체계적 디버깅 (6단계 진단 절차) |

---

## Conventions

- **컨테이너 런타임**: Podman (Docker 대신) — ADR 2026-02-01
- **언어**: 한국어 기본, 기술 용어는 영어 유지
- **커밋**: Conventional Commits (`feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`)
- **브랜치**: `feature/`, `fix/`, `hotfix/`, `refactor/`
- **의사결정**: 모든 아키텍처 결정을 project-hub에 ADR로 기록
- **시크릿**: `.env`, credentials 직접 커밋 금지 — 환경변수 참조
- **작업 범위**: 현재 작업 범위 내에서만 파일 수정

---

## 중첩 Submodule 참고

ACKO 내부에 cluster-manager submodule이 있음 (`aerospike-ce-kubernetes-operator/aerospike-cluster-manager/`).
workspace 루트의 `aerospike-cluster-manager/`와는 독립적인 checkout (서로 다른 commit 가능).
`git clone --recursive`로 자동 해결됨.
