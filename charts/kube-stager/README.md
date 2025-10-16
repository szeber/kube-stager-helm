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

Version 1.0.0 introduces breaking changes:

- **Leader election enabled by default** - This is safe for both single and multi-replica deployments
  - **Required permissions**: The operator needs access to ConfigMaps and Leases in the deployment namespace
  - **Impact on single replica**: No functional change, minimal performance overhead (~5-10MB memory)
  - **Impact on multi-replica**: Enables proper leader election, prevents split-brain scenarios
  - The leader election mechanism ensures only one replica actively reconciles resources

- **Configuration format changed** - Replaced controller-runtime's v1alpha1 config with custom ProjectConfig
  - Job configuration (initJobConfig, migrationJobConfig, backupJobConfig) is now explicitly included in the config
  - These fields have sensible defaults and can be customized via values.yaml
  - The config file no longer uses Kubernetes CR format (apiVersion/kind removed from file-based config)

- **Redis TLS and authentication now enforced** - The Redis handler now properly uses TLS and authentication settings
  - TLS certificate verification is enabled by default
  - **Action required**: If using Redis with self-signed certificates, update your RedisConfig:
    ```yaml
    apiVersion: config.operator.kube-stager.io/v1
    kind: RedisConfig
    spec:
      isTlsEnabled: true
      verifyTlsServerCertificate: false  # For self-signed certificates
    ```
  - Previously these settings were ignored and Redis connections were made without TLS/auth

### Upgrade Steps

**IMPORTANT:** Helm does not automatically update CRDs. You must update them manually first.

```bash
# 1. Backup existing resources (recommended)
kubectl get stagingsites.site.operator.kube-stager.io -A -o yaml > backup-stagingsites.yaml
kubectl get serviceconfigs.config.operator.kube-stager.io -A -o yaml > backup-serviceconfigs.yaml

# 2. Update CRDs BEFORE upgrading the Helm release
kubectl replace -f charts/kube-stager/crds/crds.yaml

# 3. Upgrade the Helm release
helm upgrade kube-stager ./charts/kube-stager -n kube-stager-system

# 4. Verify the operator is running
kubectl rollout status deployment/kube-stager-controller-manager -n kube-stager-system
kubectl logs -n kube-stager-system deploy/kube-stager-controller-manager -c manager | grep "successfully acquired lease"
```

### Rollback Procedure

If you need to rollback:

```bash
# Rollback Helm release
helm rollback kube-stager -n kube-stager-system

# Restore old CRDs (if you have a backup)
kubectl replace -f backup-crds.yaml
```

### Maintaining v0.3.0 Behavior

To disable leader election (not recommended for multi-replica):

```yaml
config:
  leaderElection: false
```

## Configuration

### High Availability (HA)

For production deployments, enable HA configuration:

```yaml
deployment:
  replicas: 2  # Run 2 replicas for redundancy
  podDisruptionBudget:
    enabled: true  # Prevent disruptions during updates
    minAvailable: 1  # Always keep at least 1 replica running

config:
  leaderElection: true  # Enabled by default (safe for both single and multi-replica)
```

Pod anti-affinity is automatically configured when replicas > 1 to spread pods across nodes.

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

#### PrometheusRule Examples

The chart does not install alerting rules automatically. Here are recommended alerts you can create manually:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kube-stager-alerts
  namespace: kube-stager-system
spec:
  groups:
  - name: kube-stager
    interval: 30s
    rules:
    # Alert if operator is down
    - alert: KubeStagerDown
      expr: up{job="kube-stager-controller-manager-metrics"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Kube-stager operator is down"
        description: "The kube-stager operator has been down for more than 5 minutes"

    # Alert on high reconciliation errors
    - alert: KubeStagerHighErrorRate
      expr: rate(controller_runtime_reconcile_errors_total[5m]) > 0.1
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "High error rate in kube-stager reconciliation"
        description: "Error rate is {{ $value | humanizePercentage }} over the last 5 minutes"

    # Alert on webhook failures
    - alert: KubeStagerWebhookFailures
      expr: rate(controller_runtime_webhook_requests_total{code!~"2.."}[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Kube-stager webhook is failing"
        description: "Webhook failure rate is {{ $value | humanizePercentage }}"

    # Alert if no leader elected (multi-replica only)
    - alert: KubeStagerNoLeader
      expr: sum(leader_election_master_status) == 0
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "No leader elected for kube-stager"
        description: "No controller instance has been elected as leader for 2 minutes"
```

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
      memory: 256Mi
      # CPU limits removed following Kubernetes best practices to prevent throttling
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

**Note**: CPU limits are removed from the manager container following Kubernetes community best practices. CPU throttling can cause cascading failures in operators (missed reconciliations, webhook timeouts). The operator can now burst to handle reconciliation spikes without artificial constraints.

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
| `deployment.replicas` | int | `1` | Number of replicas |
| `deployment.podDisruptionBudget.enabled` | bool | `false` | Enable PodDisruptionBudget |
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
