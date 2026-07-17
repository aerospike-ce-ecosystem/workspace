# Multi-Cluster + Keycloak OIDC 후속 작업

이 문서는 ADR-0040(Multi-Cluster Topology + Keycloak OIDC)의 첫 구현 이후 남은 작업과 이미 해결한 문제를 정리합니다.

## 컨텍스트

| 항목 | 위치 |
|------|------|
| ADR | [project-hub PR #69](https://github.com/aerospike-ce-ecosystem/project-hub/pull/69) — `project-hub/docs/docs/architecture/adr/2026-05-05-multi-cluster-topology-and-keycloak-oidc.md` |
| 운영자 가이드 | `aerospike-ce-kubernetes-operator/docs/multi-cluster-keycloak.md` |
| 구현 PR | ACKO [#239](https://github.com/aerospike-ce-ecosystem/aerospike-ce-kubernetes-operator/pull/239), cluster-manager [#298](https://github.com/aerospike-ce-ecosystem/aerospike-cluster-manager/pull/298), plugins [#17](https://github.com/aerospike-ce-ecosystem/aerospike-ce-ecosystem-plugins/pull/17) |

## 우선순위

- **P0**: security와 stability에 직접 영향을 줍니다. 다음 minor release 전에 처리합니다.
- **P1**: 운영 편의성과 code quality를 개선합니다. 다음 분기 안에 처리합니다.
- **P2**: 장기 설계가 필요한 항목입니다. 구현하기 전에 별도의 ADR을 작성합니다.

---

## P0 — 보안 · 안정성

### 0. Bitnami → Codecentric (또는 직접 manifest) 마이그레이션

- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: `Makefile install-keycloak` 타겟, `scripts/keycloak/README.md`
- **이유**: Bitnami는 2025-08-28에 `docker.io/bitnami/*` 무료 image 제공을 중단했습니다. 현재는 `bitnamilegacy/*` mirror로 임시 우회하고 있지만 장기적으로 사용할 수 없습니다.
  - `bitnamilegacy` image는 더 이상 update되지 않으며 이후 제거될 수 있습니다(Hub description, `last_updated: 2025-08-20`).
  - Bitnami chart의 default values는 계속 `bitnami/keycloak`을 가리키므로 default configuration이 동작하지 않습니다.
  - Chart를 upgrade해 Keycloak 27.x 같은 새 version을 참조하면 legacy mirror에 해당 tag가 없어 다시 실패할 수 있습니다.
- **현재 완화책**:
  - Chart version을 `--version 25.2.0`으로 고정합니다.
  - Keycloak, PostgreSQL, keycloak-config-cli의 `image.repository`를 모두 `bitnamilegacy/*`로 override합니다.
  - Legacy mirror에 `-r0` tag가 없어 `postgresql.image.tag=17.6.0-debian-12-r4`를 명시합니다.
  - `global.security.allowInsecureImages=true`로 chart의 secure-image guard를 우회합니다.
- **모니터링 신호**: bitnamilegacy/keycloak Hub page의 status와 `last_updated`, image 제거 공지를 확인합니다.
- **장기 옵션 (권장 순)**:
  1. **Codecentric chart**(`https://codecentric.github.io/helm-charts/keycloak`)를 사용합니다. 한 번의 Helm install로 PostgreSQL sidecar와 `quay.io/keycloak/keycloak` image를 함께 배포할 수 있어 migration 부담이 가장 작습니다.
  2. **직접 manifest를 관리합니다.** StatefulSet, Service, ConfigMap, 별도 PostgreSQL을 합쳐도 100줄 미만으로 구성할 수 있습니다.
  3. ~~Keycloak Operator를 사용합니다.~~ E2E에서는 수명이 짧은 단일 instance만 필요하고 production chart는 IdP를 운영하지 않으므로 현재 요구사항에는 지나치게 복잡합니다.
- **결정 가정**: Production chart가 IdP를 직접 운영하지 않는 한 Keycloak Operator는 필요하지 않습니다. 현재 topology에는 첫 번째 option이 가장 적합합니다.

### 0.5. ACKO nested `aerospike-cluster-manager` submodule sync

- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: ACKO repo의 `aerospike-cluster-manager/` (nested submodule, workspace 루트의 `aerospike-cluster-manager/`와 별개)
- **이유**: `make run-local`의 `[3/8]` 단계는 ACKO 내부의 nested submodule로 Cluster Manager backend image를 build합니다. 이 submodule은 특정 commit을 가리키므로 workspace root의 Cluster Manager checkout이나 PR을 자동으로 따라가지 않습니다. 그 결과 OIDC code가 없는 image가 만들어졌고, middleware가 등록되지 않아 chart 설치 후 모든 request가 200을 반환했습니다. 검증 중 발견한 운영상 중요한 주의점입니다.
- **현재 완화책**: 검증 전에 `cd aerospike-ce-kubernetes-operator/aerospike-cluster-manager && git checkout feat/multi-cluster-oidc`를 실행한 뒤 `make run-local`을 다시 실행합니다.
- **장기 해결 (권장 순)**:
  1. **PR merge 순서를 강제합니다.** Cluster Manager PR #298을 먼저 merge하고, ACKO PR #239에서 nested submodule을 새 `main`으로 update한 뒤 ACKO PR을 merge합니다. 이 순서를 운영 절차에 기록합니다.
  2. **Makefile에 `submodule-sync` target을 추가합니다.** 운영자가 `make submodule-sync`를 명시적으로 실행하면 `git submodule update --init --remote aerospike-cluster-manager`를 수행합니다.
  3. **`make run-local`이 stale pointer를 감지해 warning을 표시합니다.** 자동 update는 예기치 않게 build source를 바꿀 수 있으므로 수행하지 않습니다.
- **검증**: 이 완화책을 적용한 뒤 no-auth 401, dev-user 200, wrong-audience 401, invalid token 401의 네 가지 E2E scenario가 모두 contract대로 동작했습니다.

### 0.6. Chart `deployment-web.yaml` mountPath ↔ image structure mismatch — RESOLVED

- **Status**: ✅ Resolved by aerospike-cluster-manager#299 + aerospike-ce-kubernetes-operator#240 (2026-05-05).
- **이유**: Multi-cluster 검증 중 chart의 mount path와 image layout이 다르다는 사실을 확인했습니다. ACKO `Makefile`은 API와 UI가 결합된 `Dockerfile`의 `runtime` target을 `ui.web` image로 build했습니다. 이 image의 UI는 `/app/ui/public/`에 있지만 chart는 `/app/public/`에 mount했습니다. Cluster Manager에는 이미 Web 전용 `Dockerfile.ui`가 있었으므로 chart의 가정은 맞았고, ACKO `Makefile`이 잘못된 Dockerfile을 선택한 것이 원인이었습니다.
- **해결 결과**:
  - Cluster Manager #299는 `Dockerfile.ui`를 chart의 `ui.web` naming에 맞춰 `Dockerfile.web`으로 변경했습니다. Multi-cluster topology와 맞지 않던 all-in-one `Dockerfile`을 제거하고, `compose.yaml`을 두 service로 나눴으며, `cd.yaml` matrix와 image suffix도 `ui`에서 `web`으로 통일했습니다.
  - ACKO #240은 `ui.web.image.repository` default를 `aerospike-cluster-manager-web`으로 바꿨습니다. `Makefile`의 `[3/8]` 단계는 `Dockerfile.api`와 `Dockerfile.web`을 따로 build하고 `[4/8]` 단계는 두 image를 모두 Kind에 load합니다.
- **검증**: Clean Kind cluster에서 chart의 default mount path와 `Dockerfile.web` layout이 일치했습니다. Common SPA에서 production API로 연결하는 flow를 포함해 인증·health·connection 관련 일곱 가지 cross-cluster E2E scenario가 모두 통과했습니다.

### 0.7. Go e2e 워크플로우의 SKIP_KEYCLOAK — RESOLVED

- **Status**: ✅ Resolved by aerospike-ce-kubernetes-operator#241 (2026-05-05).
- **이유**: `setup-test-e2e`가 조건 없이 `install-keycloak`을 호출했습니다. 새 CI runner는 매번 legacy Keycloak, PostgreSQL, keycloak-config-cli image를 pull했고 5분 chart timeout을 넘겨 `context deadline exceeded`로 실패했습니다. ACKO #240의 E2E CI failure도 이 문제에서 비롯됐습니다.
- **해결**: 이미 제공하던 `SKIP_KEYCLOAK=true` Makefile option을 `Running Test e2e` step의 environment에 추가했습니다. Go E2E는 Controller behavior만 검증하므로 Keycloak이 필요하지 않습니다. OIDC와 multi-cluster는 plugins repository의 `e2e_pytest/test_multi_cluster.py`가 별도로 검증합니다.

### 1. `python-jose` → `PyJWT` 마이그레이션

- **Repo**: `aerospike-cluster-manager`
- **위치**: `api/src/aerospike_cluster_manager_api/middleware/oidc_auth.py` 상단 TODO, `api/pyproject.toml`, `api/uv.lock`
- **이유**: `python-jose`는 2년 넘게 maintainer 활동이 거의 없으며 CVE-2024-33663과 CVE-2024-33664가 해결되지 않았습니다. `PyJWT >= 2.9`의 `jwt.PyJWKClient`는 JWKS 조회와 key rotation을 직접 지원합니다.
- **현재 완화책**: `_ALLOWED_ALGS` allowlist와 엄격한 `aud`, `iss`, `exp` 검증으로 알려진 attack path를 차단합니다. 이 검증은 유지하되 dependency 자체를 교체해야 합니다.
- **작업 범위**:
  1. `pyproject.toml`에서 dependency를 교체합니다.
  2. `oidc_auth.py`의 `jose.jwt`를 `jwt`와 `PyJWKClient`로 바꿉니다.
  3. `tests/test_oidc_auth.py`의 18개 scenario를 다시 검증합니다.
  4. 기존 JWKS cache와 `PyJWKClient`의 built-in cache를 비교해 custom cache를 유지할지 결정합니다.
- **예상 규모**: PR 하나, 0.5~1일입니다.

### 2. SSE `access_token` URL 노출의 장기 fix

- **Repo**: `aerospike-cluster-manager` + `aerospike-ce-kubernetes-operator`
- **위치**: `cluster-manager/ui/src/lib/api/events.ts` SECURITY 주석, `acko/docs/multi-cluster-keycloak.md` "MANDATORY: mask access_token in ingress access logs" 섹션
- **이유**: Native `EventSource`는 custom header를 지원하지 않아 token을 query string에 넣습니다. 이 값은 Ingress access log, `Referer` header, browser history에 평문으로 남을 수 있습니다. 첫 구현은 Ingress log에서 `access_token`을 반드시 masking하도록 문서화해 위험을 줄였습니다.
- **장기 option**:
  1. `POST /api/events/subscribe`가 유효 기간 60초의 one-time **signed nonce**를 발급하고, `EventSource`는 query에 nonce만 보냅니다.
  2. `Authorization` header를 사용할 수 있는 **fetch + ReadableStream** 기반 SSE client로 바꾸거나 WebSocket과 heartbeat를 사용합니다.
  3. HTTP/2 server push를 검토합니다.
- **결정 필요**: Security와 protocol contract가 바뀌므로 별도의 ADR이 필요합니다.

### 3. `OIDCAuthMiddleware`에 `resource_access[client].roles` fallback 추가 또는 명시 차단

- **Repo**: `aerospike-cluster-manager`
- **위치**: `api/src/aerospike_cluster_manager_api/middleware/oidc_auth.py:266` (`_extract_realm_roles`)
- **이유**: 현재 middleware는 `realm_access.roles`만 검사합니다. Keycloak에서 client-scoped role만 받은 사용자는 `realm_access.roles`가 비어 있어 403을 받습니다. `realm_access`만 지원하는 것이 의도라면 contract에 명확히 적어야 하고, 그렇지 않다면 `resource_access[clientId].roles` fallback을 구현해야 합니다.
- **권장**: Docstring에 realm role만 지원한다고 명시하고, 운영자 guide에도 `requiredRoles`를 항상 realm role로 발급하라고 안내합니다.

---

## P1 — 운영 편의 · 코드 품질

### 4. ACKO `acko-realm.json` 중복 통합

- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: `scripts/keycloak/acko-realm.json` ↔ `test/utils/testdata/acko-realm.json` (동일 바이트, 현재 cp로 동기화)
- **이유**: 같은 내용을 두 파일에 보관하므로 서로 달라질 수 있습니다. cert-manager helper처럼 source of truth를 하나로 만들어야 합니다.
- **option**:
  1. `test/utils/utils.go`에서 `//go:embed ../../scripts/keycloak/acko-realm.json`을 사용합니다. Go embed가 `..`를 거부하면 build script가 testdata directory로 복사합니다.
  2. `Makefile generate` 단계에서 두 파일을 동기화합니다.
  3. Symlink를 사용합니다. 다만 Windows compatibility가 떨어집니다.
- **권장**: 첫 번째 option으로 source of truth를 하나만 유지합니다.

### 5. ACKO chart `KEYCLOAK_ADMIN_PASSWORD` 환경변수화

- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: `Makefile install-keycloak` 타겟, `auth.adminPassword=admin` 하드코딩
- **이유**: CI와 local environment에서 서로 다른 password를 사용할 수 있어야 합니다. Makefile default를 `KEYCLOAK_ADMIN_PASSWORD ?= admin`으로 바꿉니다.

### 6. ACKO `NOTES.txt`의 내부 jargon 정리

- **Repo**: `aerospike-ce-kubernetes-operator`
- **위치**: `charts/aerospike-ce-kubernetes-operator/templates/NOTES.txt:206` 부근의 "Stream D documentation in project-hub"
- **이유**: Helm install 뒤 사용자가 보는 안내에 내부 작업명인 “Stream D”가 노출됩니다. 이를 공개 문서인 `docs/multi-cluster-keycloak.md` link로 바꿉니다.

### 7. cluster-manager `_extract_token` Authorization 헤더 단일화

- **Repo**: `aerospike-cluster-manager`
- **위치**: `api/src/aerospike_cluster_manager_api/middleware/oidc_auth.py:135`
- **이유**: Starlette의 `request.headers`는 case-insensitive이므로 `request.headers.get("authorization")` 한 번이면 충분합니다. Lowercase와 uppercase를 모두 조회하는 중복 code를 제거합니다.

### 8. cluster-manager `_SENSITIVE_QS_RE`에 `refresh_token` 추가

- **Repo**: `aerospike-cluster-manager`
- **위치**: `api/src/aerospike_cluster_manager_api/main.py:189` (request_logging_middleware)
- **이유**: 일부 client가 `refresh_token`을 query에 넣을 가능성이 있습니다. 현재 masking 대상인 `access_token`, `id_token`, `token`에 `refresh_token`을 추가합니다.

### 9. cluster-manager `splitIssuerUrl` → `splitKeycloakIssuerUrl` rename

- **Repo**: `aerospike-cluster-manager`
- **위치**: `ui/src/lib/auth/keycloak.ts:60`
- **이유**: 이 function은 Keycloak의 `/realms/<x>` path만 처리하고 Auth0나 Okta 같은 다른 OIDC issuer에서는 error를 반환합니다. Name에 Keycloak 제약을 드러내 contract를 분명히 합니다.

### 10. cluster-manager `<ClusterSelector>` health 재검사 트리거

- **Repo**: `aerospike-cluster-manager`
- **위치**: `ui/src/components/ui/navigation/ClusterSelector.tsx:106-122`
- **이유**: 현재 component가 mount될 때 한 번만 health check를 실행합니다. Tab을 오래 열어 두면 status indicator가 오래된 상태로 남으므로 `visibilitychange` listener 또는 60초 interval을 추가합니다.

### 11. plugins `time.sleep(0)` 제거

- **Repo**: `aerospike-ce-ecosystem-plugins`
- **위치**: `skills/acko-e2e-test/e2e_pytest/tests/test_multi_cluster.py` 끝부분 (`test_keycloak_oidc_discovery` 마지막 줄)
- **이유**: 0초 동안 sleep하는 call은 아무 효과가 없으므로 삭제합니다.

### 12. plugins `KEYCLOAK_URL` override 시 `keycloak_pf` short-circuit

- **Repo**: `aerospike-ce-ecosystem-plugins`
- **위치**: `skills/acko-e2e-test/e2e_pytest/conftest.py:294`
- **이유**: External IdP를 사용하면 in-cluster port-forward가 필요하지 않습니다. `KEYCLOAK_URL` environment variable이 있으면 `keycloak_pf` fixture가 즉시 `None`을 yield하도록 합니다.

### 13. plugins 미사용 상수 정리

- **Repo**: `aerospike-ce-ecosystem-plugins`
- **위치**: `skills/acko-e2e-test/e2e_pytest/conftest.py` `KEYCLOAK_OTHER_CLIENT_ID`, `KEYCLOAK_AUDIENCE`
- **이유**: Constant는 정의돼 있지만 test가 같은 값을 literal로 사용합니다. Test에서 constant를 사용하도록 통일하거나 사용하지 않는 definition을 삭제합니다.

### 14. plugins `helm test` 폴백 강화

- **Repo**: `aerospike-ce-ecosystem-plugins`
- **위치**: `skills/acko-e2e-test/e2e_pytest/tests/test_multi_cluster.py::test_helm_test_multicluster_routing`
- **이유**: Helm test Pod는 짧은 시간만 남아 있어 failure를 조사할 때 이미 사라질 수 있습니다. `--ignore-not-found`와 `kubectl get events` fallback으로 추가 diagnostic 정보를 남깁니다.

---

## P2 — 장기 (별도 ADR 후보)

다음 항목은 ADR-0040의 후속 작업에도 기록돼 있습니다.

### A. Defense-in-depth: ingress level oauth2-proxy / Keycloak gatekeeper

각 dev/production cluster의 Ingress 앞에 oauth2-proxy를 배치해 cookie 기반 OIDC 인증을 위임합니다. 현재 FastAPI native JWT 검증은 유지하고 앞단에 추가 security layer를 둡니다.

### B. Prod Keycloak realm/client 자동 프로비저닝

`aerospike-ce-kubernetes-operator/docs/multi-cluster-keycloak.md`는 Terraform Keycloak provider HCL 예제를 제공하지만 reusable IaC module은 아직 없습니다. Terraform module 또는 keycloak-config-cli operator pattern을 별도로 설계합니다.

### C. mTLS (proxy ↔ API)

Service mesh(Istio/Linkerd) 또는 cert-manager가 발급한 client certificate로 proxy와 API 사이에 mTLS를 적용합니다. 첫 단계에서는 private network와 JWT만 사용합니다.

### D. Cross-cluster 메트릭/로그 federation

현재 cluster마다 독립적으로 수집하는 metric과 log를 Prometheus federation과 Loki multi-tenancy로 통합합니다.

### E. Multi-kind e2e (stage 2)

현재 E2E는 하나의 Kind cluster와 두 namespace로 topology를 흉내 냅니다. 이를 세 개 Kind cluster와 external Keycloak으로 구성한 실제 multi-cluster test로 확장합니다.

### F. PostgreSQL connection-profile cross-cluster aggregation

각 Operator cluster API는 자체 PostgreSQL을 사용하므로 dev profile은 dev API에, production profile은 production API에만 보입니다. UI에서 profile을 통합해 보여 주거나 동기화하는 mechanism이 필요합니다.

### G. Per-cluster audience hardening (`acko-api-dev`, `acko-api-prod`)

현재 모든 cluster가 하나의 `acko-api` audience를 사용해 dev token을 production에 replay할 수 있습니다. 짧은 TTL과 role 분리로 위험을 낮추고 있지만, 장기적으로는 environment별 audience로 격리합니다.

---

## 정리

| 카테고리 | 항목 수 | 추정 PR 수 |
|----------|--------|----------|
| P0 보안/안정성 | 3 | 2–3 |
| P1 운영/품질 | 11 | 6–8 (관련 항목 묶음 가능) |
| P2 장기 | 7 | 7 ADR + 후속 |

P1 작업은 repository별로 묶을 수 있습니다. ACKO 세 건과 plugins 세 건은 각각 PR 하나로 처리하고, Cluster Manager 다섯 건은 Backend와 Frontend PR로 나누는 구성이 적절합니다.

P2 항목은 각각 구현 전에 별도의 ADR이 필요합니다.
