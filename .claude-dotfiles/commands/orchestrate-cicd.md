# Orchestrate - CI/CD Pipeline Workflow

Sequential agent workflow for CI/CD pipeline orchestration. Comprehensive development pipeline from build to deployment with security scanning, testing, and rollback capabilities.

## Usage

`/orchestrate-cicd [workflow-type] [task-description]`

## CI/CD Context

- **CI Platforms**: GitHub Actions, GitLab CI, Jenkins, CircleCI, Azure DevOps
- **Container Runtime**: Docker, Podman, containerd
- **Orchestration**: Kubernetes, Docker Swarm, ECS, Cloud Run
- **Security**: Trivy, Snyk, OWASP Dependency-Check, Cosign for image signing
- **Artifact Management**: SBOM generation (Syft, CycloneDX), artifact signing
- **Deployment Strategies**: Blue-Green, Canary, Rolling Updates, Feature Flags
- **Monitoring**: Prometheus, Grafana, Datadog, New Relic, OpenTelemetry

---

## Workflow Types

### pipeline
Complete CI/CD pipeline from build to deployment:
```
build-agent -> test-agent -> security-scan-agent -> deploy-agent -> monitoring-agent
```

**Use Cases**:
- Full application deployment pipeline
- Microservice deployment with dependencies
- Multi-environment deployment (dev → staging → prod)
- Container image build and push

**Example**: `/orchestrate-cicd pipeline "Deploy Node.js API to Kubernetes with canary deployment"`

---

### security
Security-focused pipeline with comprehensive scanning:
```
dependency-scan-agent -> sast-agent -> container-scan-agent -> sbom-agent -> signing-agent
```

**Use Cases**:
- Security audit before production deployment
- Compliance scanning (OWASP, CIS benchmarks)
- Container image vulnerability assessment
- Supply chain security validation with SBOM

**Example**: `/orchestrate-cicd security "Scan container image for vulnerabilities and generate signed SBOM"`

---

### deployment
Deployment workflow with validation and monitoring:
```
deploy-agent -> smoke-test-agent -> monitoring-agent -> notification-agent
```

**Use Cases**:
- Production deployment with health checks
- Canary deployment with gradual rollout
- Blue-green deployment switch
- Feature flag deployment

**Example**: `/orchestrate-cicd deployment "Deploy to production with canary strategy and Prometheus monitoring"`

---

### rollback
Rapid rollback workflow for failed deployments:
```
incident-detection-agent -> rollback-agent -> verification-agent -> postmortem-agent
```

**Use Cases**:
- Automated rollback on health check failure
- Manual rollback trigger for production issues
- Database migration rollback
- Configuration rollback

**Example**: `/orchestrate-cicd rollback "Rollback failed deployment to previous stable version"`

---

### build
Build-focused workflow with artifact management:
```
build-agent -> test-agent -> artifact-scan-agent -> artifact-publish-agent
```

**Use Cases**:
- Container image build with multi-stage optimization
- NPM/Maven/PyPI package publishing
- Binary artifact generation and signing
- SBOM generation and attestation

**Example**: `/orchestrate-cicd build "Build and publish Docker image with signed SBOM"`

---

### test
Comprehensive testing pipeline:
```
unit-test-agent -> integration-test-agent -> e2e-test-agent -> performance-test-agent
```

**Use Cases**:
- Full test suite execution across all levels
- Load testing before production deployment
- Smoke testing in staging environment
- Contract testing for microservices

**Example**: `/orchestrate-cicd test "Run full test suite including performance tests"`

---

## Execution Pattern

For each agent in the workflow:

1. **Invoke agent** with CI/CD platform-specific context
2. **Collect output** as structured handoff document
3. **Pass to next agent** in chain with pipeline state
4. **Aggregate results** into final deployment report
5. **Trigger notifications** on success or failure

---

## CI/CD Context Template

Before invoking any agent, gather and provide:

```markdown
## CI/CD Platform
- Platform: [GitHub Actions / GitLab CI / Jenkins / CircleCI]
- Repository: [org/repo]
- Branch: [main / develop / feature/xyz]
- Commit SHA: [full SHA]
- Pipeline ID: [run ID or build number]

## Application Context
- Application: [app-name]
- Language/Runtime: [Node.js 20 / Python 3.12 / Go 1.22]
- Framework: [Express / FastAPI / Gin]
- Dependencies: package.json / requirements.txt / go.mod

## Build Context
- Build Tool: [Docker / Buildpacks / Gradle / Maven]
- Base Image: [node:20-alpine / python:3.12-slim]
- Multi-stage: [Yes/No]
- Target Platform: [linux/amd64,linux/arm64]

## Deployment Context
- Environment: [dev / staging / production]
- Platform: [Kubernetes / ECS / Cloud Run / VM]
- Region: [us-east-1 / eu-west-1]
- Cluster: [prod-cluster]
- Namespace: [production]
- Strategy: [Rolling / Blue-Green / Canary]

## Security Context
- Scanners: [Trivy / Snyk / Grype]
- SBOM Format: [CycloneDX / SPDX]
- Signing Tool: [Cosign / Sigstore]
- Policy Enforcement: [OPA / Kyverno]

## Monitoring Context
- APM: [Datadog / New Relic / OpenTelemetry]
- Metrics: [Prometheus / CloudWatch]
- Logs: [ELK / Loki / CloudWatch Logs]
- Tracing: [Jaeger / Zipkin / X-Ray]

## Relevant Files
- CI/CD Config: .github/workflows/deploy.yml
- Dockerfile: Dockerfile
- K8s Manifests: k8s/deployment.yaml
- Helm Chart: charts/app/values.yaml
```

---

## Handoff Document Format

Between agents, create handoff document with CI/CD specifics:

```markdown
## HANDOFF: [previous-agent] -> [next-agent]

### Pipeline Stage
[Build / Test / Security Scan / Deploy / Monitor]

### Status
✅ Success | ⚠️ Warning | ❌ Failed

### Artifacts Produced
| Artifact | Location | SHA256 | Signed |
|----------|----------|--------|--------|
| Container Image | registry.io/app:v1.2.3 | abc123... | ✅ |
| SBOM | sbom.json | def456... | ✅ |
| Test Report | test-results.xml | ghi789... | ❌ |

### Container Images
- Image: registry.io/myapp:v1.2.3
- Size: 245 MB
- Layers: 12
- Base Image: node:20-alpine
- Vulnerabilities: 0 Critical, 2 High, 5 Medium

### Security Scan Results
- CVE Count: 7 total (0 Critical, 2 High, 5 Medium)
- SBOM Generated: ✅ CycloneDX format
- Image Signed: ✅ Cosign with keyless signing
- Policy Violations: None

### Test Results
- Unit Tests: 245/245 passed (100%)
- Integration Tests: 58/60 passed (96.7%)
- E2E Tests: 12/12 passed (100%)
- Coverage: 87.3%
- Failed Tests: [list if any]

### Deployment Status
- Environment: production
- Strategy: Canary (25% → 50% → 100%)
- Current Phase: 25% traffic
- Health Checks: ✅ Passing
- Rollback Ready: ✅

### Metrics
- Build Time: 3m 45s
- Test Time: 8m 12s
- Deploy Time: 2m 30s
- Total Pipeline Time: 14m 27s

### Environment Variables
[List of required env vars or secrets]

### Configuration Changes
[ConfigMaps, Secrets, or infrastructure changes]

### Dependencies Updated
- Node.js: 20.10.0 → 20.11.0
- Express: 4.18.2 → 4.19.0
- Critical security updates: 2 packages

### Open Issues
[Blockers or warnings for next agent]

### Recommendations for Next Agent
[Suggested next steps with CI/CD context]

### Rollback Information
- Previous Version: v1.2.2
- Rollback Strategy: Helm rollback
- Estimated Rollback Time: 30 seconds
```

---

## Example: Pipeline Workflow

```
/orchestrate-cicd pipeline "Deploy Node.js API to Kubernetes with canary deployment"
```

Executes:

### 1. Build Agent
**Input**: Source code + Dockerfile + build context
**Actions**:
- Checks out code at specific commit SHA
- Runs security scanning on dependencies (npm audit)
- Builds Docker image with multi-stage optimization
- Runs container image scanning (Trivy)
- Tags image with semantic version and commit SHA
- Pushes to container registry
- Generates build attestation

**Output**: `HANDOFF: build-agent -> test-agent`
```markdown
## Build Summary
- Image: registry.io/api:v1.2.3
- Size: 245 MB (reduced from 420 MB with multi-stage)
- Build Time: 3m 45s
- Base Image: node:20-alpine
- Dependencies: 127 packages
- Security: 0 Critical, 2 High vulnerabilities found

## Artifacts
- Container Image: registry.io/api:v1.2.3 (pushed)
- Build Log: build.log (uploaded)
- Dependency List: npm-list.txt

## Security Findings (Pre-build)
- npm audit: 2 High severity vulnerabilities
- Outdated packages: 5 (non-breaking updates available)
- License compliance: All packages MIT/Apache-2.0

## Optimizations Applied
- Multi-stage build reduced image size by 42%
- Production dependencies only (devDependencies excluded)
- Layer caching optimized (rebuild time: 45s)
```

---

### 2. Test Agent
**Input**: Built container image + test specifications
**Actions**:
- Pulls container image locally
- Runs unit tests inside container
- Executes integration tests with test database
- Runs API contract tests
- Performs smoke tests on container endpoints
- Generates test coverage report
- Archives test results and logs

**Output**: `HANDOFF: test-agent -> security-scan-agent`
```markdown
## Test Results
✅ Unit Tests: 245/245 passed (100%)
✅ Integration Tests: 58/60 passed (96.7%)
✅ API Contract Tests: 12/12 passed (100%)
✅ Smoke Tests: 8/8 passed (100%)

## Failed Tests
- test_database_connection_pool_exhaustion (integration)
- test_rate_limiting_edge_case (integration)

## Coverage Report
- Line Coverage: 87.3%
- Branch Coverage: 82.1%
- Function Coverage: 91.4%
- Uncovered: src/legacy/deprecated.js (scheduled for removal)

## Performance Baseline
- Average API Response Time: 45ms
- P95 Response Time: 120ms
- Memory Usage: 180 MB
- Startup Time: 2.3s

## Recommendations
- Fix 2 failing integration tests before production
- Add tests for error handling in auth module (coverage gap)
```

---

### 3. Security Scan Agent
**Input**: Container image + SBOM requirements
**Actions**:
- Scans container image with Trivy
- Generates Software Bill of Materials (SBOM) with Syft
- Validates SBOM completeness
- Performs static analysis on code (SAST)
- Checks for secrets in image layers
- Signs container image with Cosign
- Signs SBOM with attestation
- Enforces security policies (OPA)

**Output**: `HANDOFF: security-scan-agent -> deploy-agent`
```markdown
## Container Vulnerability Scan (Trivy)
- Critical: 0
- High: 2 (CVE-2024-1234, CVE-2024-5678)
- Medium: 5
- Low: 12
- Total: 19

## High Severity CVEs
1. CVE-2024-1234 (openssl 3.0.7)
   - CVSS: 7.5
   - Fix: Upgrade to 3.0.13
   - Status: Patchable

2. CVE-2024-5678 (curl 8.0.1)
   - CVSS: 7.2
   - Fix: Upgrade to 8.6.0
   - Status: Patchable

## SBOM Generated
- Format: CycloneDX 1.5 JSON
- Components: 127 direct + 834 transitive
- License Compliance: ✅ All approved
- Location: registry.io/api:v1.2.3.sbom
- Signed: ✅ Cosign keyless (Sigstore)

## Image Signing
- Tool: Cosign v2.2
- Method: Keyless signing via Sigstore
- Transparency Log: ✅ Recorded in Rekor
- Signature Verification: cosign verify --certificate-oidc-issuer=...

## SAST Results (Semgrep)
- Critical Issues: 0
- High Issues: 1 (SQL injection risk - false positive)
- Medium Issues: 3 (weak crypto algorithm usage)

## Secrets Scanning
- No secrets found in image layers ✅
- No API keys or tokens exposed ✅

## Policy Compliance
✅ Only approved base images used
✅ No root user in container
✅ Read-only root filesystem configured
✅ No privileged containers
⚠️  2 High CVEs present (acceptable per policy)

## Recommendations
- Upgrade openssl to 3.0.13 (CVE fix)
- Upgrade curl to 8.6.0 (CVE fix)
- Replace MD5 usage with SHA-256
- Rebuild image after dependency updates
```

---

### 4. Deploy Agent
**Input**: Signed container image + deployment configuration
**Actions**:
- Verifies image signature before deployment
- Validates SBOM attestation
- Applies Kubernetes manifests to target namespace
- Configures canary deployment (25% traffic)
- Updates service mesh routing rules
- Injects monitoring sidecars (if applicable)
- Creates deployment annotation with metadata
- Waits for rollout status
- Monitors health checks and readiness probes

**Output**: `HANDOFF: deploy-agent -> monitoring-agent`
```markdown
## Deployment Status
- Environment: production
- Cluster: prod-us-east-1
- Namespace: api-production
- Strategy: Canary Deployment

## Canary Rollout Plan
1. Phase 1: 25% traffic (5 minutes) ✅ CURRENT
2. Phase 2: 50% traffic (10 minutes) - PENDING
3. Phase 3: 100% traffic (15 minutes) - PENDING

## Image Verification
✅ Image signature verified (Cosign)
✅ SBOM attestation validated
✅ Policy compliance checked (Kyverno)

## Kubernetes Resources Applied
- Deployment: api-production (updated)
- Service: api-service (unchanged)
- Ingress: api-ingress (updated with canary annotations)
- ConfigMap: api-config-v1.2.3 (new)
- Secret: api-secrets (unchanged, using existing)

## Replica Status
- Previous Version (v1.2.2): 3 replicas (75% traffic)
- New Version (v1.2.3): 1 replica (25% traffic)
- Total Capacity: 4 replicas

## Health Checks
✅ Liveness Probe: /health - 200 OK
✅ Readiness Probe: /ready - 200 OK
✅ Startup Probe: Completed in 2.3s

## Service Mesh Configuration
- Istio VirtualService: Updated with weighted routing
- Traffic Split: 75% v1.2.2, 25% v1.2.3
- Circuit Breaker: Configured (max connections: 100)
- Retry Policy: 3 attempts, 1s timeout

## Environment Variables Injected
- NODE_ENV: production
- LOG_LEVEL: info
- DATABASE_URL: (from secret)
- REDIS_URL: (from secret)
- DD_AGENT_HOST: (from downward API)

## Rollback Configuration
- Revision: 47
- Previous Stable Version: v1.2.2 (revision 46)
- Rollback Command: kubectl rollout undo deployment/api-production -n api-production

## Canary Metrics to Monitor
- Error Rate: Should remain < 1%
- Latency P95: Should remain < 200ms
- Success Rate: Should remain > 99%
- Memory Usage: Should remain < 512 MB
```

---

### 5. Monitoring Agent
**Input**: Deployed application + monitoring configuration
**Actions**:
- Monitors canary deployment metrics (Prometheus)
- Compares new version vs baseline (v1.2.2)
- Tracks error rates, latency, and throughput
- Analyzes distributed traces (Jaeger)
- Monitors resource utilization (CPU, memory)
- Checks log aggregation for errors
- Evaluates SLO compliance
- Triggers alerts if thresholds exceeded
- Provides recommendation for next phase or rollback

**Output**: Final Report
```markdown
## Monitoring Report - Canary Phase 1 (25% Traffic)
Duration: 5 minutes
Period: 2025-03-11 14:30:00 - 14:35:00 UTC

## Version Comparison
| Metric | v1.2.2 (Baseline) | v1.2.3 (Canary) | Delta | Status |
|--------|-------------------|-----------------|-------|--------|
| Error Rate | 0.12% | 0.08% | -0.04% | ✅ Improved |
| Avg Latency | 48ms | 45ms | -3ms | ✅ Improved |
| P95 Latency | 125ms | 118ms | -7ms | ✅ Improved |
| P99 Latency | 245ms | 238ms | -7ms | ✅ Improved |
| Throughput | 1250 req/s | 1270 req/s | +20 req/s | ✅ Improved |
| CPU Usage | 45% | 42% | -3% | ✅ Improved |
| Memory Usage | 178 MB | 180 MB | +2 MB | ✅ Acceptable |

## Error Analysis
- Total Errors: 12 (v1.2.3) vs 18 (v1.2.2)
- 4xx Errors: 10 (client errors, not version-specific)
- 5xx Errors: 2 (down from 4 in baseline)
- Most Common Error: 404 Not Found (6 occurrences)

## SLO Compliance
✅ Availability: 99.992% (target: 99.9%)
✅ Latency: P95 < 200ms (target: 200ms)
✅ Error Rate: 0.08% (target: < 1%)

## Resource Utilization
- CPU: 42% avg, 68% peak (limit: 500m)
- Memory: 180 MB avg, 195 MB peak (limit: 512 MB)
- Network I/O: 15 Mbps in, 25 Mbps out

## Log Analysis (ELK)
- Total Log Entries: 45,234
- Error Logs: 8 (0.02%)
- Warning Logs: 23 (0.05%)
- No critical errors detected ✅

## Distributed Tracing (Jaeger)
- Traces Analyzed: 3,456
- Average Trace Duration: 52ms
- Slowest Trace: 420ms (database query timeout - expected)
- No anomalous traces detected

## Recommendation
🟢 PROCEED TO NEXT PHASE

Canary deployment is performing better than baseline across all metrics.
No anomalies detected. Safe to increase traffic to 50%.

Proceed with Phase 2: 50% traffic for 10 minutes
Estimated completion: 14:45 UTC
```

---

## Final Report Format

```
ORCHESTRATION REPORT - CI/CD PIPELINE
=====================================
Workflow: pipeline
Task: Deploy Node.js API to Kubernetes with canary deployment
Platform: GitHub Actions
Repository: myorg/api
Commit: abc123def456 (v1.2.3)
Agents: build-agent -> test-agent -> security-scan-agent -> deploy-agent -> monitoring-agent

SUMMARY
-------
Successfully deployed Node.js API v1.2.3 to production using canary strategy.
Build completed in 3m 45s, all critical tests passed (96.7% pass rate), security
scan found 2 High CVEs (patchable), canary deployment at 25% traffic showing
improved performance vs baseline. Recommended to proceed to Phase 2 (50%).

AGENT OUTPUTS
-------------
Build Agent: Successfully built and pushed container image (245 MB) with
             multi-stage optimization. Image signed with Cosign.

Test Agent: 323/325 tests passed (99.4%). 2 non-critical integration test
            failures identified. Code coverage 87.3%. Performance baseline
            established.

Security Scan Agent: Found 19 vulnerabilities (0 Critical, 2 High, 5 Medium,
                     12 Low). Generated and signed SBOM. Policy compliance: PASS.
                     2 High CVEs require patching in next iteration.

Deploy Agent: Canary deployment initiated successfully. Phase 1 (25% traffic)
              deployed to 1 replica. Health checks passing. Service mesh
              configured with weighted routing.

Monitoring Agent: Canary showing 6% improvement in latency, 33% reduction in
                  errors vs baseline. All SLOs met. Recommendation: PROCEED.

ARTIFACTS PRODUCED
------------------
✅ Container Image: registry.io/api:v1.2.3 (signed)
✅ SBOM: registry.io/api:v1.2.3.sbom (CycloneDX, signed)
✅ Test Report: test-results-abc123.xml
✅ Security Report: trivy-report-abc123.json
✅ Build Log: build-log-abc123.txt
✅ Deployment Manifest: k8s-manifests-abc123.yaml

CONTAINER IMAGE
---------------
Registry: registry.io/api:v1.2.3
Size: 245 MB
Digest: sha256:abc123def456...
Signed: ✅ Cosign (keyless via Sigstore)
Vulnerabilities: 0 Critical, 2 High, 5 Medium, 12 Low

SBOM
----
Format: CycloneDX 1.5 JSON
Components: 961 total (127 direct, 834 transitive)
Signed: ✅ Cosign attestation
Location: registry.io/api:v1.2.3.sbom
License Compliance: ✅ All approved licenses

TEST RESULTS
------------
Total Tests: 325
Passed: 323 (99.4%)
Failed: 2 (integration tests, non-critical)
Coverage: 87.3% (line), 82.1% (branch)
Performance: P95 latency 120ms

SECURITY STATUS
---------------
CVE Severity Breakdown:
- Critical: 0
- High: 2 (CVE-2024-1234, CVE-2024-5678)
- Medium: 5
- Low: 12

Policy Compliance: ✅ PASS
Image Signing: ✅ Verified
SBOM Generation: ✅ Complete
Secrets Scanning: ✅ No secrets found

Action Required: Upgrade openssl and curl in next build

DEPLOYMENT STATUS
-----------------
Environment: production
Cluster: prod-us-east-1
Namespace: api-production
Strategy: Canary (25% → 50% → 100%)
Current Phase: Phase 1 (25% traffic) ✅ STABLE

Replicas:
- v1.2.2 (baseline): 3 replicas (75% traffic)
- v1.2.3 (canary): 1 replica (25% traffic)

Health: ✅ All probes passing
Rollback Ready: ✅ One-command rollback available

CANARY METRICS (5-minute observation)
--------------------------------------
| Metric | Baseline | Canary | Change | Status |
|--------|----------|--------|--------|--------|
| Error Rate | 0.12% | 0.08% | -33% | ✅ Improved |
| P95 Latency | 125ms | 118ms | -5.6% | ✅ Improved |
| Throughput | 1250/s | 1270/s | +1.6% | ✅ Improved |
| CPU Usage | 45% | 42% | -6.7% | ✅ Improved |

SLO Compliance: ✅ ALL TARGETS MET

RECOMMENDATION
--------------
🟢 PROCEED WITH PHASE 2

Canary deployment is stable and performing better than baseline across all
key metrics. No anomalies detected in logs or traces. Safe to proceed.

Next Steps:
1. Increase traffic to 50% (Phase 2)
2. Monitor for 10 minutes
3. If stable, proceed to 100% (Phase 3)
4. After 100% for 15 minutes, remove old version

Estimated Time to Full Rollout: 30 minutes
Rollback Availability: Immediate (< 30s)

PENDING ACTIONS
---------------
1. Fix 2 failing integration tests (non-blocking)
2. Upgrade openssl to 3.0.13 (security fix) - schedule in next sprint
3. Upgrade curl to 8.6.0 (security fix) - schedule in next sprint
4. Replace MD5 usage with SHA-256 (security improvement)
5. Add test coverage for auth module error handling

PIPELINE METRICS
----------------
Total Duration: 18m 45s
- Build: 3m 45s
- Test: 8m 12s
- Security Scan: 2m 18s
- Deploy: 2m 30s
- Monitoring: 2m 00s

COST ESTIMATION
---------------
- Build Compute: $0.08 (GitHub Actions)
- Test Compute: $0.15 (GitHub Actions)
- Container Registry Storage: $0.02/month
- Deployment: No additional cost (existing cluster)

NOTIFICATION SENT
-----------------
✅ Slack: #deployments channel
✅ Email: devops-team@company.com
✅ PagerDuty: Informational event (no alert)
✅ Datadog Event: Deployment marker added

ROLLBACK INFORMATION
--------------------
Rollback Command:
  kubectl rollout undo deployment/api-production -n api-production

Previous Stable Version: v1.2.2 (revision 46)
Estimated Rollback Time: 30 seconds
Rollback Testing: Automated rollback tested in staging ✅
```

---

## Parallel Execution

For independent checks, run agents in parallel:

```markdown
### Parallel Security Phase
Run simultaneously:
- container-scan-agent (Trivy scanning)
- dependency-scan-agent (Snyk/npm audit)
- sast-agent (Semgrep static analysis)
- secrets-scan-agent (Gitleaks)

### Merge Results
Combine all security findings into comprehensive report
Generate unified SBOM with all components
Produce aggregated security score
```

---

## Arguments

$ARGUMENTS:
- `pipeline <description>` - Full CI/CD pipeline from build to deployment
- `security <description>` - Security-focused scanning and attestation
- `deployment <description>` - Deployment with validation and monitoring
- `rollback <description>` - Rapid rollback workflow
- `build <description>` - Build and artifact management
- `test <description>` - Comprehensive testing pipeline
- `custom <agents> <description>` - Custom agent sequence

---

## CI/CD Platform-Specific Guidance

### GitHub Actions
```yaml
# Example workflow structure
name: CI/CD Pipeline
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and scan
        run: |
          # Build agent actions

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Run tests
        run: |
          # Test agent actions

  security:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Security scans
        run: |
          # Security agent actions

  deploy:
    needs: security
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy canary
        run: |
          # Deploy agent actions
```

### GitLab CI
```yaml
# Example .gitlab-ci.yml structure
stages:
  - build
  - test
  - security
  - deploy
  - monitor

build:
  stage: build
  script:
    - # Build agent actions

test:
  stage: test
  needs: [build]
  script:
    - # Test agent actions

security_scan:
  stage: security
  needs: [test]
  script:
    - # Security agent actions

deploy_canary:
  stage: deploy
  needs: [security_scan]
  environment:
    name: production
  script:
    - # Deploy agent actions
```

---

## Best Practices (2025)

### Security & Supply Chain
1. **SBOM Generation**: Always generate and sign SBOMs (CycloneDX or SPDX)
2. **Image Signing**: Use Cosign with keyless signing (Sigstore)
3. **Attestation**: Create build attestations with SLSA provenance
4. **Policy Enforcement**: Use admission controllers (Kyverno, OPA) to enforce policies
5. **Vulnerability Scanning**: Multi-tool approach (Trivy + Snyk + Grype)
6. **Secrets Management**: Never embed secrets in images; use external secret stores
7. **Least Privilege**: Run containers as non-root with read-only filesystems

### Build Optimization
1. **Multi-stage Builds**: Reduce image size and attack surface
2. **Layer Caching**: Optimize Dockerfile for faster rebuilds
3. **Distroless/Minimal Base**: Use minimal base images (Alpine, Distroless)
4. **Multi-arch Builds**: Build for amd64 and arm64 architectures
5. **BuildKit**: Use BuildKit features for faster, more efficient builds

### Deployment Strategies
1. **Canary Deployments**: Gradual rollout with automated monitoring
2. **Blue-Green**: Zero-downtime deployments with instant rollback
3. **Feature Flags**: Decouple deployment from feature activation
4. **Progressive Delivery**: Combine canary + feature flags + monitoring
5. **Rollback Automation**: Automatic rollback on SLO violations

### Monitoring & Observability
1. **SLO-based Monitoring**: Define and track Service Level Objectives
2. **Distributed Tracing**: Implement OpenTelemetry for request tracing
3. **Metrics Collection**: Use Prometheus for metrics, Grafana for visualization
4. **Log Aggregation**: Centralized logging with structured logs
5. **Error Budgets**: Track error budgets and alert on burn rate

### Testing
1. **Shift-Left Testing**: Test early and often in pipeline
2. **Contract Testing**: Validate API contracts between services
3. **Chaos Engineering**: Test resilience with controlled failures
4. **Performance Testing**: Load test before production deployment
5. **Smoke Testing**: Quick validation after each deployment stage

---

## Custom Workflow Example

```
/orchestrate-cicd custom "build-agent,security-scan-agent,deploy-agent,smoke-test-agent,monitoring-agent" "Fast-track hotfix deployment with security validation"
```

This custom workflow skips comprehensive testing for hotfix scenarios but maintains security scanning and post-deployment validation.

---

## Agent-Specific Guidance

### For build-agent:
- Use multi-stage Dockerfiles for size optimization
- Enable BuildKit for improved caching and parallelization
- Tag images with semantic version + commit SHA
- Scan dependencies before build (npm audit, pip check)
- Generate build metadata (labels, annotations)

### For test-agent:
- Run tests inside container to ensure consistency
- Use test containers for integration tests with real dependencies
- Implement test parallelization for faster execution
- Generate machine-readable test reports (JUnit XML)
- Establish performance baselines for regression detection

### For security-scan-agent:
- Use multiple scanners for comprehensive coverage
- Generate SBOM in standard format (CycloneDX 1.5+)
- Sign both image and SBOM with Cosign
- Create SLSA provenance attestations
- Enforce policy gates before deployment

### For deploy-agent:
- Verify image signatures before deployment
- Use declarative deployment (GitOps with ArgoCD/Flux)
- Implement progressive delivery strategies
- Configure health checks and readiness probes
- Inject monitoring sidecars/agents

### For monitoring-agent:
- Compare canary metrics vs baseline
- Track SLO compliance in real-time
- Monitor for anomalies using statistical methods
- Aggregate logs and traces for error analysis
- Provide clear go/no-go recommendation for next phase

### For rollback-agent:
- Maintain rollback readiness at all times
- Automate rollback on health check failures
- Preserve logs and metrics from failed deployment
- Document rollback reasons for post-mortem
- Test rollback procedures in staging regularly

---

## Tips

1. **Always sign artifacts** - Container images, SBOMs, and binaries should all be signed
2. **Generate SBOMs** - Critical for supply chain security and compliance
3. **Use canary deployments** for production - Catch issues before full rollout
4. **Monitor actively** during deployments - Don't just deploy and hope
5. **Automate rollbacks** - Define clear criteria for automatic rollback
6. **Test rollback procedures** - Practice rollbacks in staging regularly
7. **Keep pipelines fast** - Optimize for developer feedback loops (< 15 minutes)
8. **Use caching aggressively** - Cache dependencies, layers, and test results
9. **Fail fast** - Stop pipeline on critical issues (CVEs, test failures)
10. **Document everything** - Generate reports at each stage for audit trails

---

## Deployment Strategy Matrix

| Strategy | Use Case | Downtime | Rollback Speed | Complexity | Cost |
|----------|----------|----------|----------------|------------|------|
| Rolling Update | General purpose | None | Fast (30s) | Low | Low |
| Blue-Green | Zero-downtime requirement | None | Instant | Medium | High (2x resources) |
| Canary | Risk mitigation | None | Fast (1min) | Medium | Low |
| Feature Flags | Gradual feature rollout | None | Instant | High | Medium |
| Recreate | Stateful apps, development | Yes | Medium (2-5min) | Low | Low |
| A/B Testing | Experimentation | None | Fast | High | Medium |

---

## Security Checklist

Before production deployment:

- [ ] Container image scanned for vulnerabilities
- [ ] All Critical and High CVEs addressed or documented
- [ ] SBOM generated in standard format (CycloneDX/SPDX)
- [ ] Image signed with Cosign or equivalent
- [ ] SBOM signed with attestation
- [ ] SLSA provenance generated and attached
- [ ] No secrets embedded in image
- [ ] Container runs as non-root user
- [ ] Root filesystem set to read-only
- [ ] Security policies enforced (Kyverno/OPA)
- [ ] Dependencies scanned (npm audit, Snyk)
- [ ] Static analysis performed (SAST)
- [ ] License compliance verified
- [ ] Network policies configured
- [ ] Resource limits set

---

## Monitoring Checklist

Post-deployment validation:

- [ ] Health checks passing (liveness, readiness)
- [ ] Error rate within acceptable range (< 1%)
- [ ] Latency within SLO (P95 < target)
- [ ] Throughput at expected levels
- [ ] CPU usage within limits
- [ ] Memory usage within limits
- [ ] No critical errors in logs
- [ ] Distributed traces show normal patterns
- [ ] Database connections stable
- [ ] External API integrations working
- [ ] Queue depths normal
- [ ] Cache hit rates acceptable

---

## Rollback Decision Criteria

Automatic rollback triggers:

1. **Health Check Failures**: > 3 consecutive failures
2. **Error Rate Spike**: > 5% error rate for > 2 minutes
3. **Latency Degradation**: P95 latency > 2x baseline
4. **Resource Exhaustion**: Memory/CPU at 95%+ for > 5 minutes
5. **Crash Loop**: > 3 restarts in 5 minutes
6. **Dependency Failures**: Downstream service unavailable
7. **SLO Violation**: Error budget consumed > 50% in 10 minutes

Manual rollback indicators:

1. **Customer Reports**: Multiple customer complaints about errors
2. **Business Impact**: Revenue or conversion rate drop
3. **Data Integrity Issues**: Incorrect data processing detected
4. **Security Incident**: Active security vulnerability being exploited
5. **Compliance Violation**: Regulatory requirement breach

---

## Integration with Existing Tools

### Slack Notifications
```markdown
Deployment started: v1.2.3 to production
Status: Phase 1 (25% canary) ✅
Metrics: Error rate -33%, Latency -5.6%
Next: Phase 2 in 5 minutes
Rollback: /deploy rollback v1.2.3
```

### Datadog Events
```json
{
  "title": "Deployment: api v1.2.3",
  "text": "Canary deployment phase 1 complete",
  "tags": ["deployment", "canary", "production"],
  "alert_type": "info"
}
```

### PagerDuty Integration
```markdown
Trigger incident on:
- Automatic rollback executed
- Canary metrics exceed threshold
- Deployment timeout (> 30 minutes)
```

---

## Troubleshooting

### Common Issues

**Build Failures**:
- Check dependency versions in package manifests
- Verify base image availability
- Review build logs for compilation errors
- Check disk space on build agent

**Test Failures**:
- Review test logs for specific failures
- Check test environment configuration
- Verify test data availability
- Look for flaky tests (intermittent failures)

**Security Scan Failures**:
- Review CVE severity and exploitability
- Check if CVE is false positive
- Verify if patch is available
- Document exceptions if acceptable risk

**Deployment Failures**:
- Verify image signature and attestation
- Check Kubernetes cluster health
- Review resource quotas and limits
- Verify secrets and ConfigMaps exist
- Check network policies and ingress

**Canary Issues**:
- Compare baseline vs canary metrics carefully
- Check for traffic imbalance
- Verify monitoring configuration
- Look for external factors (load, time of day)

---

## Cost Optimization

1. **Build Caching**: Reduce build times and compute costs
2. **Spot Instances**: Use spot/preemptible instances for CI/CD
3. **Multi-arch Builds**: Build once, deploy to ARM for cost savings
4. **Image Optimization**: Smaller images = faster pulls, less storage
5. **Test Parallelization**: Reduce wall-clock time
6. **Scheduled Pipelines**: Run non-critical pipelines during off-peak
7. **Artifact Cleanup**: Implement retention policies for old artifacts

---

## Compliance & Audit

For regulated industries:

1. **Audit Trail**: Maintain complete pipeline execution logs
2. **Change Management**: Document all production changes
3. **Approval Gates**: Require manual approval for production
4. **SBOM Archival**: Store SBOMs for all deployed versions
5. **Vulnerability Reporting**: Track and report on CVE remediation
6. **Access Control**: Implement RBAC for pipeline execution
7. **Attestation**: Cryptographically prove build integrity

---

## Future Enhancements

Emerging trends to incorporate:

1. **AI-Powered Canary Analysis**: ML models for anomaly detection
2. **eBPF-based Monitoring**: Kernel-level observability
3. **WebAssembly**: Multi-language builds with WASM targets
4. **GitOps v2**: Enhanced declarative deployments
5. **Supply Chain Levels for Software Artifacts (SLSA) v1.0**: Build provenance
6. **Service Mesh Integration**: Automated traffic splitting with Istio/Linkerd
7. **Policy-as-Code Evolution**: Advanced OPA/Rego policies
