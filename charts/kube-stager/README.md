# Kube-Stager Operator Helm Chart

Helm chart for deploying the kube-stager Kubernetes operator.

## Prerequisites

- Kubernetes 1.29+
- Helm 3+
- cert-manager (for webhook certificates)

## Installation

```bash
helm install kube-stager ./charts/kube-stager -n kube-stager-system --create-namespace
```

## Upgrading from v0.3.0

Version 1.0.0 introduces several breaking changes:

1. **Default replicas changed from 1 to 2** - For single-node clusters or development, set `deployment.replicas: 1`
2. **Leader election enabled by default** - Required for HA setups with multiple replicas
3. **PodDisruptionBudget enabled** - Prevents disruption during updates

To maintain v0.3.0 behavior:

```yaml
deployment:
  replicas: 1
  podDisruptionBudget:
    enabled: false
config:
  leaderElection: false
```

## Configuration

### High Availability (HA)

The chart defaults to HA configuration as of v1.0.0:

```yaml
deployment:
  replicas: 2  # Run 2 replicas for redundancy
  podDisruptionBudget:
    enabled: true  # Prevent disruptions during updates
    minAvailable: 1  # Always keep at least 1 replica running

config:
  leaderElection: true  # Enable leader election (required for multiple replicas)
```

Pod anti-affinity is automatically configured to spread replicas across nodes.

### Monitoring

Optional Prometheus integration via ServiceMonitor:

```yaml
monitoring:
  enabled: true  # Requires Prometheus Operator
  serviceMonitor:
    interval: 30s
    scrapeTimeout: 10s
```

**Note:** ServiceMonitor requires Prometheus Operator to be installed in your cluster.

### Operator Configuration

Configure operator behavior via the `config` section:

```yaml
config:
  health:
    healthProbeBindAddress: :8081
  metrics:
    bindAddress: 127.0.0.1:8080
  webhook:
    port: 9443
  leaderElection: true
  sentryDsn: ""  # Optional: Sentry DSN for error tracking

  # Job configuration
  initJobConfig:
    deadlineSeconds: 600  # Job timeout
    ttlSeconds: 600  # Job cleanup time
    backoffLimit: 0  # Retries (0 recommended for init jobs)

  migrationJobConfig:
    deadlineSeconds: 600
    ttlSeconds: 600
    backoffLimit: 3

  backupJobConfig:
    deadlineSeconds: 600
    ttlSeconds: 600
    backoffLimit: 3
```

All values are validated at startup. Invalid configurations will prevent the operator from starting.

### Resource Limits

Default resource limits:

```yaml
deployment:
  resources:
    limits:
      cpu: 500m
      memory: 128Mi
    requests:
      cpu: 10m
      memory: 64Mi

  rbacProxy:
    resources:
      limits:
        cpu: 500m
        memory: 128Mi
      requests:
        cpu: 5m
        memory: 64Mi
```

### Redis TLS Configuration

For Redis databases with TLS, configure via RedisConfig CR:

```yaml
apiVersion: config.operator.kube-stager.io/v1
kind: RedisConfig
spec:
  host: redis.example.com
  port: 6380
  isTlsEnabled: true
  verifyTlsServerCertificate: false  # For self-signed certificates
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `image` | string | `"ghcr.io/szeber/kube-stager"` | Operator image |
| `imageTag` | string | `"v1.0.0"` | Image tag |
| `deployment.replicas` | int | `2` | Number of replicas |
| `deployment.podDisruptionBudget.enabled` | bool | `true` | Enable PodDisruptionBudget |
| `deployment.podDisruptionBudget.minAvailable` | int | `1` | Minimum available pods |
| `config.leaderElection` | bool | `true` | Enable leader election |
| `monitoring.enabled` | bool | `false` | Enable ServiceMonitor |

See [values.yaml](values.yaml) for all configuration options.

## Uninstallation

```bash
helm uninstall kube-stager -n kube-stager-system
```

**Warning:** This will not delete CRDs or custom resources. To remove CRDs:

```bash
kubectl delete crd stagingsites.site.operator.kube-stager.io
kubectl delete crd serviceconfigs.config.operator.kube-stager.io
# ... (delete other CRDs as needed)
```

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## Support

For issues, visit [github.com/szeber/kube-stager](https://github.com/szeber/kube-stager/issues)
