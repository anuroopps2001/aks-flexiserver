✅ Strategy 2 — Portable (AKS + OpenShift)
Dockerfile
RUN chown -R 0:0 /app && chmod -R g+rwX /app
# no USER
AKS YAML
runAsNonRoot: true
runAsUser: 1000
OpenShift YAML
runAsNonRoot: true
# ❌ no runAsUser

✔ works everywhere
✔ industry-style
⚠ requires awareness


🔥 Best recommendation for YOU

Since you're learning both AKS + OpenShift:

👉 Use this:

Dockerfile
RUN chown -R 0:0 /app && chmod -R g+rwX /app
AKS
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
OpenShift
securityContext:
  runAsNonRoot: true





🧠 Interview-level answer

If asked:

“What happens if you only use runAsNonRoot?”

Answer:

The pod will fail if the container image defaults to root, because Kubernetes cannot enforce a non-root user without an explicit UID.
