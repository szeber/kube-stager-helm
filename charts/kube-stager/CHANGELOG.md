# Changelog

All notable changes to the kube-stager Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-15

### Added
- Optional PodDisruptionBudget configuration (disabled by default)
- Pod anti-affinity rules for better distribution across nodes (when replicas > 1)
- Optional ServiceMonitor for Prometheus Operator (disabled by default)
- Leader election enabled by default for production readiness

### Changed
- **BREAKING**: Leader election now enabled by default
- Updated CRDs with controller-gen v0.17.2 (from v0.14.0) - includes enhanced OpenAPI validation and schema improvements
- Updated imageTag from v0.3.0 to v1.0.0
- Updated appVersion from 0.3.0 to 1.0.0
- Increased manager memory limit from 128Mi to 256Mi for better production stability
- Removed CPU limits following Kubernetes best practices

### Fixed
- Conditional pod anti-affinity rendering (only applies when replicas > 1)
- PodDisruptionBudget validation to prevent blocking all updates
- Conditional annotation rendering to avoid empty YAML blocks
- Configurable ServiceMonitor TLS verification
- Added multi-replica validation for leader election requirement

## [0.3.0] and earlier
See git history for changes in previous releases.
