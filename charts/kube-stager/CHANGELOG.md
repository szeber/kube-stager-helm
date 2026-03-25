# Changelog

All notable changes to the kube-stager Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0-rc1] - 2026-03-26

### Added
- Prometheus metrics instrumentation with 15 custom application-specific metrics covering:
  - Resource inventory gauges (staging sites, databases, jobs by state)
  - StagingSite lifecycle counters (state transitions, auto-disable, auto-delete) and provisioning duration histogram
  - Database operation counters and duration histograms (MySQL, MongoDB, Redis)
  - Job completion counters and duration histograms (init, migration, backup)
  - Error counter with controller and finality classification
  - Webhook denied counter with reason labels
  - Build info gauge with version from build-time ldflags
- ServiceMonitor annotations support (aligning with prometheus-static-target chart)

### Changed
- Updated appVersion to 1.0.3-rc1
- Updated imageTag to v1.0.3-rc1
- Updated CRDs

## [1.0.0] - 2025-10-17

### Added
- Optional PodDisruptionBudget configuration (disabled by default)
- Pod anti-affinity rules for better distribution across nodes (when replicas > 1)
- Optional ServiceMonitor for Prometheus Operator (disabled by default)
- Leader election enabled by default for production readiness

### Changed
- **BREAKING**: Leader election now enabled by default
- **BREAKING**: Redis handler now enforces TLS and authentication (set `verifyTlsServerCertificate: false` in RedisConfig for self-signed certs)
- Updated CRDs with controller-gen v0.17.2 (from v0.14.0) - includes enhanced OpenAPI validation and schema improvements
- Updated imageTag from v0.3.0 to v1.0.0-rc2
- Updated appVersion from 0.3.0 to 1.0.0-rc2
- Increased manager memory limit from 128Mi to 256Mi for better production stability
- Removed CPU limits following Kubernetes best practices

### Fixed
- Conditional pod anti-affinity rendering (only applies when replicas > 1)
- PodDisruptionBudget validation to prevent blocking all updates
- Conditional annotation rendering to avoid empty YAML blocks
- Configurable ServiceMonitor TLS verification
- Added multi-replica validation for leader election requirement
- Config file format to match kube-stager v1.0.0 ProjectConfig (added apiVersion/kind/metadata for runtime.Object, added job configs with defaults)

## [0.3.0] and earlier
See git history for changes in previous releases.
