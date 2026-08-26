{{- define "costgraph-selfhosted.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "costgraph-selfhosted.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "costgraph-selfhosted.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "costgraph-selfhosted.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "costgraph-selfhosted.selectorLabels" -}}
app.kubernetes.io/name: {{ include "costgraph-selfhosted.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "costgraph-selfhosted.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | required "image.tag is required: images are published per commit, so the chart's appVersion is not a tag that exists" }}
{{- end -}}

{{- define "costgraph-selfhosted.dashboardImage" -}}
{{ .Values.dashboard.image.repository }}:{{ .Values.dashboard.image.tag | required "dashboard.image.tag is required: images are published per commit, so the chart's appVersion is not a tag that exists" }}
{{- end -}}

{{- define "costgraph-selfhosted.secretName" -}}
{{- if .Values.controlPlane.existingSecret -}}
{{- .Values.controlPlane.existingSecret -}}
{{- else -}}
{{- include "costgraph-selfhosted.fullname" . -}}
{{- end -}}
{{- end -}}

{{- define "costgraph-selfhosted.bundledPostgresName" -}}
{{- printf "%s-postgres" (include "costgraph-selfhosted.fullname" .) -}}
{{- end -}}

{{- define "costgraph-selfhosted.postgresSecretName" -}}
{{- if .Values.postgres.existingSecret -}}
{{- .Values.postgres.existingSecret -}}
{{- else if and .Values.postgres.bundled.enabled (not .Values.postgres.url) -}}
{{- include "costgraph-selfhosted.bundledPostgresName" . -}}
{{- else -}}
{{- include "costgraph-selfhosted.fullname" . -}}
{{- end -}}
{{- end -}}

{{- define "costgraph-selfhosted.redisURL" -}}
{{- if .Values.redis.url -}}
{{- .Values.redis.url -}}
{{- else if .Values.redis.bundled.enabled -}}
{{- printf "redis://%s-redis:6379" (include "costgraph-selfhosted.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "costgraph-selfhosted.metricsStoreURL" -}}
{{- if .Values.metricsStore.url -}}
{{- .Values.metricsStore.url -}}
{{- else if .Values.metricsStore.bundled.enabled -}}
{{- printf "http://%s-victoria-metrics:8428" (include "costgraph-selfhosted.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "costgraph-selfhosted.dashboardConfig" -}}
{{- $api := .Values.dashboard.apiBaseURL -}}
{{- if not $api -}}
{{- $api = printf "%s/api/v1" (trimSuffix "/" .Values.appBaseURL) -}}
{{- end -}}
{{- $cognito := dict -}}
{{- if and (.Values.cognito).userPoolId (.Values.cognito).userPoolClientId -}}
{{- $cognito = dict "userPoolId" (.Values.cognito).userPoolId "userPoolClientId" (.Values.cognito).userPoolClientId -}}
{{- end -}}
{{- if and .Values.dashboard.cognitoOAuthDomain $cognito -}}
{{- $_ := set $cognito "oauthDomain" .Values.dashboard.cognitoOAuthDomain -}}
{{- end -}}
{{- $posthog := dict "enabled" .Values.analytics.enabled -}}
{{- if .Values.analytics.enabled -}}
{{- $_ := set $posthog "token" .Values.analytics.posthogKey -}}
{{- $_ := set $posthog "host" .Values.analytics.posthogHost -}}
{{- end -}}
{{- $cfg := dict "apiBaseUrl" $api "posthog" $posthog -}}
{{- if $cognito -}}
{{- $_ := set $cfg "cognito" $cognito -}}
{{- end -}}
{{- if .Values.dashboard.graphAiBaseURL -}}
{{- $_ := set $cfg "graphAiBaseUrl" .Values.dashboard.graphAiBaseURL -}}
{{- end -}}
{{- toPrettyJson $cfg -}}
{{- end -}}

{{- define "costgraph-selfhosted.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets -}}
{{- toYaml .Values.imagePullSecrets -}}
{{- else if .Values.controlPlane.apiKey -}}
- name: {{ include "costgraph-selfhosted.fullname" . }}-registry
{{- end -}}
{{- end -}}
