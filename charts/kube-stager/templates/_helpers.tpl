{{/*
Validate leader election is enabled when running multiple replicas
*/}}
{{- if and (gt (int .Values.deployment.replicas) 1) (not .Values.config.leaderElection) }}
{{- fail "Leader election must be enabled when replicas > 1 to prevent split-brain scenarios. Set config.leaderElection=true or reduce replicas to 1." }}
{{- end }}
