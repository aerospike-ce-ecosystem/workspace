# Multi-Cluster + Keycloak OIDC — 미해결 작업 (Follow-ups)

ADR-0040 (Multi-Cluster Topology + Keycloak OIDC) 1단계 머지 이후 남는 작업 모음.

## 컨텍스트

| 항목 | 위치 |
|------|------|
| ADR | [project-hub PR #69](https://github.com/aerospike-ce-ecosystem/project-hub/pull/69) — `project-hub/docs/docs/architecture/adr/2026-05-05-multi-cluster-topology-and-keycloak-oidc.md` |
| 운영자 가이드 | `aerospike-ce-kubernetes-operator/docs/multi-cluster-keycloak.md` |
| 구현 PR | ACKO [#239](https://github.com/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator/pull/239), cluster-manager [#298](https://github.com/aerospike-ce-ecosystem/aerospike-cluster-manager/pull/298), plugins [#17](https://github.com/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins/pull/17) |

## 우선순위

- **P0**: 보안/안정성. 1단계 머지 후 다음 마이너 릴리스 전에 처리.
- **P1**: 운영 편의 / 코드 품질. 다음 분기 내.
- **P2**: 장기 / 별도 ADR 필요.

---

## P0 — 보안 · 안정성

### 0. Bitnami → Codecentric (또는 직접 manifest) 마이그레이션
- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: `Makefile install-keycloak` 타겟, `scripts/keycloak/README.md`
- **이유**: Bitnami가 2025-08-28부로 `docker.io/bitnami/*` 무료 이미지 제거. 현재 `bitnamilegacy/*` mirror로 임시 override 중. 그러나
  - `bitnamilegacy`는 "no longer updated, may be removed in the future" (Hub description, last_updated 2025-08-20)
  - bitnami chart 자체의 default values는 여전히 `bitnami/keycloak`을 가리키므로 chart 자체도 사실상 broken-default
  - chart upgrade 시 새 keycloak 버전 (예 27.x) 가리키면 legacy mirror에 그 tag가 없어 또 fail
- **현재 mitigation**:
  - `--version 25.2.0` chart version pin
  - `image.repository=bitnamilegacy/*` 모든 컴포넌트 override (keycloak, postgresql, keycloak-config-cli)
  - `postgresql.image.tag=17.6.0-debian-12-r4` 명시 (legacy에 -r0 없음)
  - `global.security.allowInsecureImages=true`로 chart secure-image guard 우회
- **모니터링 신호**: bitnamilegacy/keycloak Hub 페이지의 status / last_updated. 제거 announcement.
- **장기 옵션 (권장 순)**:
  1. **Codecentric chart** (`https://codecentric.github.io/helm-charts/keycloak`) — chart 1번 helm install, postgres sidecar 자동, image=`quay.io/keycloak/keycloak`. 마이그레이션 부담 최소.
  2. **직접 manifest** — statefulset + service + configmap + 별도 PG. 100줄 미만. 가장 단순.
  3. ~~Keycloak Operator~~ — over-engineering for our use-case (e2e ephemeral 1-instance, prod chart는 IdP 책임 안 짐). 채택 안 함.
- **결정 가정**: prod에서 chart가 IdP 책임을 지지 않는 한 Operator는 불필요. 우리 토폴로지에서는 1)이 best fit.

### 0.5. ACKO nested `aerospike-cluster-manager` submodule sync
- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: ACKO repo의 `aerospike-cluster-manager/` (nested submodule, workspace 루트의 `aerospike-cluster-manager/`와 별개)
- **이유**: `make run-local`의 step `[3/8]`이 ACKO 안의 nested submodule을 사용해 cluster-manager backend image를 빌드한다. 이 submodule pointer는 cluster-manager의 특정 commit에 박혀있고, workspace 측의 `cluster-manager` PR을 작업해도 자동으로 따라가지 않는다. **결과**: image build에 OIDC 코드가 누락되어 chart install 후 모든 요청이 200 OK (middleware 등록 안 됨). 검증 과정에서 발견됨 — 매우 큰 운영 함정.
- **현재 mitigation**: 검증 시 수동으로 `cd aerospike-ce-kubernetes-operator/aerospike-cluster-manager && git checkout feat/multi-cluster-oidc` 한 후 `make run-local` 재실행.
- **장기 해결 (권장 순)**:
  1. **PR 머지 순서 강제**: cluster-manager PR #298 머지 → ACKO repo의 nested submodule을 새 main으로 update하는 commit을 ACKO PR #239에 추가 → ACKO PR #239 머지. 운영 절차로 명시.
  2. **Makefile `submodule-sync` target 추가**: `make submodule-sync` → `git submodule update --init --remote aerospike-cluster-manager`. 운영자가 명시적으로 호출.
  3. **`make run-local`이 nested submodule pointer가 stale인지 검증 + warning** — 자동 update는 위험하므로 경고만.
- **검증 완료**: 이 fix를 적용한 후 4-way E2E (no-auth → 401, dev-user → 200, wrong-aud → 401, gibberish → 401) 모두 contract대로 동작 확인.

### 0.6. Chart `deployment-web.yaml` mountPath ↔ runtime image structure mismatch
- **Repo**: `aerospike-ce-kubernetes-operator` + `aerospike-cluster-manager`
- **위치**:
  - chart: `templates/ui/deployment-web.yaml` — ConfigMap mount at `/app/public/{cluster-registry,web-oidc-config}.json`
  - cluster-manager Dockerfile: `runtime` stage가 ui를 `/app/ui/public/`에 nest (api+ui 통합 image, entrypoint.sh가 둘 다 띄움). 별도 `web` target stage 없음.
- **이유**: multi-cluster 검증 중 발견. chart의 mountPath는 별도 web-only image (`WORKDIR=/app + public/`)를 가정했지만, 현재 cluster-manager Dockerfile은 그 stage를 제공하지 않아 운영자가 `runtime` image를 그대로 ui.web으로 사용. 결과: ConfigMap이 `/app/public/`에 mount되긴 하지만 Next.js standalone server는 `/app/ui/public/`만 보므로 SPA가 부팅 시 `/cluster-registry.json` fetch에서 not-found page를 받음. ClusterSelector가 빈 상태로 떠 multi-cluster 라우팅 실패.
- **현재 mitigation**: 검증 중 `kubectl apply` patch로 mountPath를 `/app/ui/public/`로 일시 변경 — 5-way cross-cluster E2E 통과 확인 (common.web → prod.api 직접 호출, OIDC middleware가 audience + signature 검증).
- **장기 해결 (권장 순)**:
  1. **cluster-manager Dockerfile에 web-only `web` stage 추가** (WORKDIR=/app, public 그대로) — chart의 가정과 일치. 정공.
  2. **chart의 deployment-web mountPath를 `/app/ui/public/`로 변경** — runtime image 구조 강제. 단 follow-up #1 (web image 분리)을 막음.
  3. **chart에 mountPath override values key 추가** — 운영자가 사용 image 구조에 맞게 set.
- **권장**: (1). 별도 `web` Dockerfile stage가 없으면 web-only deploy가 사실상 불가능 — multi-cluster 토폴로지의 전제 조건.

### 1. `python-jose` → `PyJWT` 마이그레이션
- **Repo**: `aerospike-cluster-manager`
- **위치**: `api/src/aerospike_cluster_manager_api/middleware/oidc_auth.py` 상단 TODO, `api/pyproject.toml`, `api/uv.lock`
- **이유**: `python-jose`는 사실상 maintainer 공백 (2년+). CVE-2024-33663, CVE-2024-33664 미수정. `PyJWT >= 2.9`는 `jwt.PyJWKClient`가 JWKS+회전을 native 지원.
- **현재 mitigation**: `_ALLOWED_ALGS` 화이트리스트 + 엄격한 `aud`/`iss`/`exp` 검증으로 알려진 공격 경로 차단. 그러나 라이브러리 자체 교체가 정공.
- **작업 단위**: (a) `pyproject.toml` 의존성 교체, (b) `oidc_auth.py`의 `jose.jwt` → `jwt`(`PyJWKClient` 사용), (c) `tests/test_oidc_auth.py` 18 시나리오 재검증, (d) JWKS 캐시 로직을 `PyJWKClient` 내장과 비교해 자체 캐시 유지 여부 결정.
- **추정**: 1 PR, 0.5–1일.

### 2. SSE `access_token` URL 노출의 장기 fix
- **Repo**: `aerospike-cluster-manager` + `aerospike-ce-kubernetes-operator`
- **위치**: `cluster-manager/ui/src/lib/api/events.ts` SECURITY 주석, `acko/docs/multi-cluster-keycloak.md` "MANDATORY: mask access_token in ingress access logs" 섹션
- **이유**: `EventSource`는 헤더 미지원 → 토큰을 query string에 첨부. ingress access log / Referer / 브라우저 history에 평문 노출. 1단계는 ingress access log mask 의무 docs로 완화.
- **장기 옵션**: (a) per-stream **signed nonce** — `POST /api/events/subscribe` 가 1회용 nonce 발급, EventSource는 nonce만 query에 첨부, 만료 짧음(60s); (b) **fetch + ReadableStream** 기반 SSE 클라이언트(브라우저 native 아니지만 `Authorization` 헤더 가능) 또는 WebSocket+heartbeat 전환; (c) HTTP/2 server push.
- **별도 ADR 필요**.

### 3. `OIDCAuthMiddleware`에 `resource_access[client].roles` fallback 추가 또는 명시 차단
- **Repo**: `aerospike-cluster-manager`
- **위치**: `api/src/aerospike_cluster_manager_api/middleware/oidc_auth.py:266` (`_extract_realm_roles`)
- **이유**: 현재 `realm_access.roles`만 검사. Keycloak에서 client-scoped roles만 부여한 사용자는 토큰에 `realm_access.roles`가 비어 403. PR review에서 reviewer가 fallback 의도를 의심함 — docstring에 "realm_access only" 명시하거나 `resource_access[clientId].roles` fallback 구현.
- **권장**: docstring 명시 + `requiredRoles`는 항상 realm role로 발급하도록 운영자 가이드에 한 줄.

---

## P1 — 운영 편의 · 코드 품질

### 4. ACKO `acko-realm.json` 중복 통합
- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: `scripts/keycloak/acko-realm.json` ↔ `test/utils/testdata/acko-realm.json` (동일 바이트, 현재 cp로 동기화)
- **이유**: 두 파일 drift 위험. cert-manager helper와 동일 패턴.
- **옵션**: (a) `test/utils/utils.go`에서 `//go:embed ../../scripts/keycloak/acko-realm.json` 상대 경로 (Go embed가 `..` 거부하면 build script로 testdata 디렉토리에 복사), (b) `Makefile generate` 단계에서 sync, (c) symlink (Windows 비호환).
- **권장**: (a) — 단일 source-of-truth.

### 5. ACKO chart `KEYCLOAK_ADMIN_PASSWORD` 환경변수화
- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: `Makefile install-keycloak` 타겟, `auth.adminPassword=admin` 하드코딩
- **이유**: CI/local 양쪽에서 override 필요할 수 있음. `KEYCLOAK_ADMIN_PASSWORD ?= admin`로 변경.

### 6. ACKO `NOTES.txt`의 내부 jargon 정리
- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: `charts/aerospike-ce-kubernetes-operator/templates/NOTES.txt:206` 부근의 "Stream D documentation in project-hub"
- **이유**: 사용자에게 노출되는 문구에 내부 stream 이름. `docs/multi-cluster-keycloak.md` 공개 링크로 교체.

### 7. cluster-manager `_extract_token` Authorization 헤더 단일화
- **Repo**: `aerospike-cluster-manager`
- **위치**: `api/src/aerospike_cluster_manager_api/middleware/oidc_auth.py:135`
- **이유**: Starlette `request.headers`는 case-insensitive이므로 `request.headers.get("authorization")` 한 번이면 충분. 현재 lower/upper 둘 다 시도 — 잉여 코드.

### 8. cluster-manager `_SENSITIVE_QS_RE`에 `refresh_token` 추가
- **Repo**: `aerospike-cluster-manager`
- **위치**: `api/src/aerospike_cluster_manager_api/main.py:189` (request_logging_middleware)
- **이유**: 일부 client가 refresh_token을 query에 첨부할 가능성. 현재 `access_token`/`id_token`/`token`만 마스킹.

### 9. cluster-manager `splitIssuerUrl` → `splitKeycloakIssuerUrl` rename
- **Repo**: `aerospike-cluster-manager`
- **위치**: `ui/src/lib/auth/keycloak.ts:60`
- **이유**: 함수가 Keycloak `/realms/<x>` 경로 패턴만 처리. Auth0/Okta 같은 다른 OIDC issuer 형태는 throw. 이름이 contract를 정확히 반영하지 않음.

### 10. cluster-manager `<ClusterSelector>` health 재검사 트리거
- **Repo**: `aerospike-cluster-manager`
- **위치**: `ui/src/components/ui/navigation/ClusterSelector.tsx:106-122`
- **이유**: 현재 mount 시 1회만 ping. 비활성 탭으로 두면 stale dot. `visibilitychange` listener 또는 60s interval 추가.

### 11. plugins `time.sleep(0)` 제거
- **Repo**: `aerospike-ce-ecosystem-plugins`
- **위치**: `skills/acko-e2e-test/e2e_pytest/tests/test_multi_cluster.py` 끝부분 (`test_keycloak_oidc_discovery` 마지막 줄)
- **이유**: 0초 sleep은 no-op. 삭제.

### 12. plugins `KEYCLOAK_URL` override 시 `keycloak_pf` short-circuit
- **Repo**: `aerospike-ce-ecosystem-plugins`
- **위치**: `skills/acko-e2e-test/e2e_pytest/conftest.py:294`
- **이유**: 외부 IdP 사용 시 in-cluster port-forward는 불필요. `keycloak_pf` fixture가 `KEYCLOAK_URL` 환경변수 존재 시 즉시 yield None.

### 13. plugins 미사용 상수 정리
- **Repo**: `aerospike-ce-ecosystem-plugins`
- **위치**: `skills/acko-e2e-test/e2e_pytest/conftest.py` `KEYCLOAK_OTHER_CLIENT_ID`, `KEYCLOAK_AUDIENCE`
- **이유**: 정의됐지만 test 파일에서 literal 사용. 상수로 통일하거나 삭제.

### 14. plugins `helm test` 폴백 강화
- **Repo**: `aerospike-ce-ecosystem-plugins`
- **위치**: `skills/acko-e2e-test/e2e_pytest/tests/test_multi_cluster.py::test_helm_test_multicluster_routing`
- **이유**: helm test pod이 짧게 retain되므로 `--ignore-not-found` + `kubectl get events` 폴백으로 triage 정보 제공.

---

## P2 — 장기 (별도 ADR 후보)

ADR-0040 § 후속 작업에 이미 기록된 항목.

### A. Defense-in-depth: ingress level oauth2-proxy / Keycloak gatekeeper
각 dev/prod cluster ingress 앞에 oauth2-proxy 배치해 cookie 기반 OIDC 위임. 현재 FastAPI native JWT는 그대로 두고 그 앞단에 추가 layer.

### B. Prod Keycloak realm/client 자동 프로비저닝
Terraform Keycloak provider HCL을 `aerospike-ce-kubernetes-operator/docs/multi-cluster-keycloak.md`에 예제로 들었지만, IaC 모듈화는 별도 작업. 또는 keycloak-config-cli operator 패턴.

### C. mTLS (proxy ↔ API)
service mesh (Istio/Linkerd) 또는 cert-manager 기반 client cert. 1단계는 사설망 + JWT만으로 운영.

### D. Cross-cluster 메트릭/로그 federation
Prometheus federation, Loki multi-tenant. 현재 각 cluster별 독립.

### E. Multi-kind e2e (stage 2)
현재 e2e는 단일 kind cluster + 2 namespace 시뮬레이션. 실제 멀티 kind 토폴로지 (3 cluster + 외부 Keycloak)로 확장.

### F. PostgreSQL connection-profile cross-cluster aggregation
현재 각 operator cluster API는 자체 PostgreSQL. dev profile은 dev API에만, prod profile은 prod API에만 보임. UI에서 cross-cluster 통합 표시 / 동기화 메커니즘 필요.

### G. Per-cluster audience hardening (`acko-api-dev`, `acko-api-prod`)
현재 single audience `acko-api`. dev 토큰을 prod에 replay 가능 (짧은 TTL + role 분리로 mitigation). 환경별 audience로 격리.

---

## 정리

| 카테고리 | 항목 수 | 추정 PR 수 |
|----------|--------|----------|
| P0 보안/안정성 | 3 | 2–3 |
| P1 운영/품질 | 11 | 6–8 (관련 항목 묶음 가능) |
| P2 장기 | 7 | 7 ADR + 후속 |

P1 11개는 stream별로 묶으면 ACKO 3개, cluster-manager 5개, plugins 3개. ACKO와 plugins는 1 PR, cluster-manager는 backend/frontend 분리해 2 PR이 깔끔.

P2는 각자 별도 ADR 작성이 선행.
