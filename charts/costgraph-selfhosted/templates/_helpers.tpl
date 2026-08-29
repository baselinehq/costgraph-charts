{{- define "costgraph-selfhosted.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fixed rather than release-derived. Components rendered by stakater's chart name
themselves from a plain value and cannot resolve this helper, so every object in
the chart uses a name they can also reference. One release per namespace, which
is how this chart is deployed, so the release prefix bought nothing.
*/}}
{{- define "costgraph-selfhosted.fullname" -}}
{{- "costgraph-selfhosted" -}}
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
{{- include "costgraph-selfhosted.imageRef" (dict "repository" .Values.global.image.repository "tag" (required "image.tag is required: the chart version is not an image tag" .Values.global.image.tag)) -}}
{{- end -}}

{{/*
Joins a repository and a tag. A tag beginning with sha256: is a digest, which
joins with @ rather than :.
*/}}
{{- define "costgraph-selfhosted.imageRef" -}}
{{- if hasPrefix "sha256:" .tag -}}
{{ .repository }}@{{ .tag }}
{{- else -}}
{{ .repository }}:{{ .tag }}
{{- end -}}
{{- end -}}

{{/*
The secret holding credentials. An existingSecret you supply always wins.
*/}}
{{- define "costgraph-selfhosted.secretName" -}}
{{- if .Values.global.controlPlane.existingSecret -}}
{{- .Values.global.controlPlane.existingSecret -}}
{{- else -}}
{{- include "costgraph-selfhosted.fullname" . -}}
{{- end -}}
{{- end -}}

{{- define "costgraph-selfhosted.postgresSecretName" -}}
{{- if .Values.global.postgres.existingSecret -}}
{{- .Values.global.postgres.existingSecret -}}
{{- else -}}
{{- include "costgraph-selfhosted.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
An explicit url always wins; a bundled dependency supplies one when none is
set, so an evaluation install needs no addresses.
*/}}
{{- define "costgraph-selfhosted.redisURL" -}}
{{- if .Values.global.redis.url -}}
{{- .Values.global.redis.url -}}
{{- else if .Values.global.redis.bundled.enabled -}}
{{- printf "redis://%s-redis:6379" (include "costgraph-selfhosted.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "costgraph-selfhosted.metricsStoreURL" -}}
{{- if .Values.global.metricsStore.url -}}
{{- .Values.global.metricsStore.url -}}
{{- else if .Values.global.metricsStore.bundled.enabled -}}
{{- printf "http://%s-victoria-metrics:8428" (include "costgraph-selfhosted.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Resolved the same way the Secret resolves it, so the URL matches the password
in use rather than a new one on every render.
*/}}
{{- define "costgraph-selfhosted.bundledPostgresPassword" -}}
{{- if not (hasKey .Values "_bundledPostgresPassword") -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (printf "%s-postgres" (include "costgraph-selfhosted.fullname" .)) -}}
{{- $password := "" -}}
{{- if $existing -}}
{{- $password = index $existing.data "password" | b64dec -}}
{{- else if .Values.global.postgres.bundled.password -}}
{{- $password = .Values.global.postgres.bundled.password -}}
{{- else -}}
{{- $password = randAlphaNum 32 -}}
{{- end -}}
{{- $_ := set .Values "_bundledPostgresPassword" $password -}}
{{- end -}}
{{- get .Values "_bundledPostgresPassword" -}}
{{- end -}}

{{- define "costgraph-selfhosted.bundledPostgresURL" -}}
{{- $pg := .Values.global.postgres.bundled -}}
{{- printf "postgres://%s:%s@%s-postgres:5432/%s?sslmode=disable" $pg.username (include "costgraph-selfhosted.bundledPostgresPassword" . | urlquery) (include "costgraph-selfhosted.fullname" .) $pg.database -}}
{{- end -}}

{{/*
The dashboard's /config.json. URLs must be absolute http(s) or they are
ignored.
*/}}
{{- define "costgraph-selfhosted.dashboardConfig" -}}
{{- $api := .Values.dashboard.apiBaseURL -}}
{{- if not $api -}}
{{- $api = printf "%s/api/v1" (trimSuffix "/" .Values.global.appBaseURL) -}}
{{- end -}}
{{/* Omitted rather than left empty when unset, which is the normal case. */}}
{{- $cognito := dict -}}
{{- if and (.Values.cognito).userPoolId (.Values.cognito).userPoolClientId -}}
{{- $cognito = dict "userPoolId" (.Values.cognito).userPoolId "userPoolClientId" (.Values.cognito).userPoolClientId -}}
{{- end -}}
{{/* Only alongside a pool: on its own the block is incomplete. */}}
{{- if and .Values.dashboard.cognitoOAuthDomain $cognito -}}
{{- $_ := set $cognito "oauthDomain" .Values.dashboard.cognitoOAuthDomain -}}
{{- end -}}
{{- $cfg := dict "apiBaseUrl" $api "posthog" (dict "enabled" .Values.global.analytics.enabled) -}}
{{- if $cognito -}}
{{- $_ := set $cfg "cognito" $cognito -}}
{{- end -}}
{{- if .Values.dashboard.graphAiBaseURL -}}
{{- $_ := set $cfg "graphAiBaseUrl" .Values.dashboard.graphAiBaseURL -}}
{{- end -}}
{{- toPrettyJson $cfg -}}
{{- end -}}

{{/*
The pull secrets to attach. A caller-supplied list always wins; otherwise the
chart's own generated secret is used, and nothing is attached when the key is
not in values.
*/}}
{{- define "costgraph-selfhosted.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets -}}
{{- toYaml .Values.global.imagePullSecrets -}}
{{- else if .Values.global.controlPlane.apiKey -}}
- name: {{ include "costgraph-selfhosted.fullname" . }}-registry
{{- end -}}
{{- end -}}
