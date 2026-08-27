{{/*
Fail the render, not the pod. Every one of these is something onboarding hands
you, and a missing value otherwise surfaces as a CrashLoopBackOff whose cause
is buried in container logs.
*/}}
{{- define "costgraph-selfhosted.validate" -}}

{{- if and (not .Values.controlPlane.apiKey) (not .Values.controlPlane.existingSecret) -}}
{{- fail "controlPlane.apiKey (or controlPlane.existingSecret) is required: it is the key CostGraph issued you during onboarding. Without it this deployment cannot start." -}}
{{- end -}}

{{- if and .Values.controlPlane.existingSecret (not .Values.imagePullSecrets) -}}
{{- fail "imagePullSecrets is required when controlPlane.existingSecret is set: the chart builds the registry pull secret from controlPlane.apiKey, and cannot read the key out of a Secret you manage. Create the pull secret yourself and name it here. See the imagePullSecrets comment in values.yaml for the command." -}}
{{- end -}}

{{- if not .Values.controlPlane.configPublicKey -}}
{{- fail "controlPlane.configPublicKey is required: it is the public key this deployment verifies its configuration with, shipped with the chart. Restore it from the chart's default values." -}}
{{- end -}}

{{- if not .Values.appBaseURL -}}
{{- fail "appBaseURL is required: it is the origin your users reach the dashboard on, and it shapes the links in invite mail CostGraph sends on your behalf." -}}
{{- end -}}

{{- if not (or (hasPrefix "https://" .Values.appBaseURL) (hasPrefix "http://" .Values.appBaseURL)) -}}
{{- fail (printf "appBaseURL must start with https:// or http://, got %q. It is a full origin, such as https://costgraph.internal.example.com" .Values.appBaseURL) -}}
{{- end -}}

{{- if and (not .Values.postgres.url) (not .Values.postgres.existingSecret) (not .Values.postgres.bundled.enabled) -}}
{{- fail "postgres.url (or postgres.existingSecret) is required. For production, point it at a Postgres 14+ you operate — a database holding cost history should outlive a Helm release. To evaluate, set postgres.bundled.enabled=true to run one in-cluster (single replica, no backups)." -}}
{{- end -}}

{{- if and (not .Values.redis.url) (not .Values.redis.existingSecret) (not .Values.redis.bundled.enabled) -}}
{{- fail "redis.url is required (or redis.existingSecret, or redis.bundled.enabled=true)." -}}
{{- end -}}

{{- if and (not .Values.metricsStore.url) (not (.Values.metricsStore).existingSecret) (not .Values.metricsStore.bundled.enabled) -}}
{{- fail "metricsStore.url is required (or metricsStore.bundled.enabled=true). Without it the metrics your clusters send have nowhere to go, and no costs are produced." -}}
{{- end -}}

{{- if and .Values.ingress.enabled (not .Values.ingress.hosts) -}}
{{- fail "ingress.enabled is true but ingress.hosts is empty." -}}
{{- end -}}

{{- end -}}
