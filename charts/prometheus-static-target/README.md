# Kube-Stager Prometheus-Static-Target Operator Helm Chart

## Securing metrics with kube-rbac-proxy

Metrics are served over plain HTTP on port 8080 by default. To require authentication and authorisation, enable the
kube-rbac-proxy sidecar:

```yaml
deployment:
  rbacProxy:
    enabled: true
```

The manager then binds metrics to `127.0.0.1:8080`, and the proxy serves them over HTTPS on port 8443
(`https-metrics`).

- The ServiceMonitor scrapes with Prometheus's service account token, so that service account must be bound to the
  `<release>-metrics-reader` ClusterRole.
- With `rbac.create: true` the chart creates that ClusterRole and the proxy's TokenReview/SubjectAccessReview
  ClusterRole and binding. With `rbac.create: false` you must create all three yourself.
- The proxy's serving certificate is issued by cert-manager, which must be installed.
- The ServiceMonitor uses `bearerTokenFile`. A Prometheus with `arbitraryFSAccessThroughSMs.deny: true` rejects it.
- To enable the proxy on an existing release, upgrade with `--reset-then-reuse-values`, not `--reuse-values`.
