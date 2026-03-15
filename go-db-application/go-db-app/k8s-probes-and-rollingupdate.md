# Kubernetes Probes & RollingUpdate Strategy (with Readiness)

## 1. Kubernetes Probes Overview

Kubernetes probes are mechanisms used by kubelet to determine container health and traffic eligibility.
Each probe has a **distinct responsibility** and **different failure consequences**.

---

## 2. Startup Probe

### Purpose
- Verifies whether the application has **successfully started**
- Designed for **slow-starting applications**

### Key Behavior
- Runs only during startup
- When defined:
  - Liveness probe is ignored until startup succeeds
  - Readiness probe is ignored until startup succeeds

### On Failure
- Container is killed and restarted
- Repeated failures may lead to `CrashLoopBackOff`

### When It Stops
- Stops permanently after first success

### Typical Use
- JVM apps
- Apps with migrations or warm-up logic

---

## 3. Liveness Probe

### Purpose
- Detects whether a running application is **stuck or unhealthy**
- Decides when Kubernetes should **restart a container**

### Key Behavior
- Runs continuously after startup
- Independent of readiness

### On Failure
- Container is restarted
- Repeated failures trigger `CrashLoopBackOff`

### Should Check
- Deadlocks
- Infinite loops
- Internal unrecoverable states

### Should NOT Check
- External dependencies (DB, APIs)

---

## 4. Readiness Probe

### Purpose
- Controls whether a Pod should **receive traffic**
- Governs Service, Route, Ingress, and Gateway routing

### Key Behavior
- Runs continuously during runtime
- Does NOT restart containers

### On Failure
- Pod becomes `NotReady` (e.g., `0/1`)
- Pod is removed from Service endpoints
- Container continues running

### Traffic Implications
- Multi-replica: traffic shifts to healthy pods
- Single replica: traffic stops
- Direct access (Pod IP, port-forward) still works

### Should Check
- DB connectivity
- Cache availability
- Dependency health

---

## 5. Probe Interaction Summary

| Probe      | Restarts Container | Controls Traffic | Lifecycle Stage |
|-----------|-------------------|-----------------|----------------|
| Startup   | Yes               | No              | Startup        |
| Liveness | Yes               | No              | Runtime        |
| Readiness| No                | Yes             | Runtime        |

---

## 6. Default Deployment RollingUpdate Strategy

### Default Configuration
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%
    maxUnavailable: 25%
```

### Meaning
- `maxSurge`: extra Pods allowed above desired replicas
- `maxUnavailable`: Pods allowed to be unavailable during update
- Enables **zero-downtime deployments**

---

## 7. RollingUpdate Behavior with Readiness Probe

### Key Principle
> Kubernetes replaces Pods **only after new Pods become Ready**

### Step-by-Step Flow
1. Old Pod is running and Ready
2. New Pod is created with updated spec
3. New Pod must pass **readiness probe**
4. Only after readiness succeeds:
   - Old Pod is terminated
   - Rollout continues

### If Readiness Fails
- New Pod stays `NotReady`
- Old Pod continues serving traffic
- Deployment rollout **stalls safely**
- No downtime occurs

### For replicas: 1
- Kubernetes temporarily runs **two Pods**
- Old Pod remains until new Pod is Ready

---

## 8. Why Readiness Is Critical for Rolling Updates

Without readiness:
- Old Pod may be terminated early
- Broken Pod may receive traffic
- Users experience downtime

With readiness:
- Broken versions never receive traffic
- Availability is preserved automatically

---

## 9. Practical Rules (Production)

- Always define readiness probes for Deployments
- Never test readiness using port-forward
- Let readiness fail before liveness
- Readiness failures protect availability
- Startup probe protects slow booting apps

---

## 10. One-Line Mental Models

- Startup: "Has the app started?"
- Liveness: "Is the app stuck?"
- Readiness: "Can it serve traffic now?"
- RollingUpdate: "Prove readiness before replacement"

---

End of document.
