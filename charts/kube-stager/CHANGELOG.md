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
- Updated imageTag from v0.3.0 to v1.0.0
- Updated appVersion from 0.3.0 to 1.0.0

### Fixed
- None

## [0.3.0] and earlier
See git history for changes in previous releases.
