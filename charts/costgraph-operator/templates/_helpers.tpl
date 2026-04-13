{{/*
Expand the name of the chart.
*/}}
{{- define "costgraph-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "costgraph-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "costgraph-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "costgraph-operator.labels" -}}
helm.sh/chart: {{ include "costgraph-operator.chart" . }}
{{ include "costgraph-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "costgraph-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "costgraph-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "costgraph-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "costgraph-operator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Namespace helper
*/}}
{{- define "costgraph-operator.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}
*/}}

{{/*
Resolve the name of the Secret holding the API key.
Uses an existing secret when global.existingSecret is set; otherwise uses
the Secret created by this chart.
*/}}
{{- define "costgraph-operator.apiKeySecretName" -}}
{{- if .Values.global.existingSecret -}}
{{- .Values.global.existingSecret -}}
{{- else -}}
{{- printf "%s-credentials" (include "costgraph-operator.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/*
Resolve the key within the API-key Secret.
When referencing a chart-managed secret the key is always "apiKey".
existingSecretKey is only honoured when an existing secret is provided.
*/}}
{{- define "costgraph-operator.apiKeySecretKey" -}}
{{- if .Values.global.existingSecret -}}
{{- default "apiKey" .Values.global.existingSecretKey -}}
{{- else -}}
apiKey
{{- end -}}
{{- end }}

{{/*

------------------------------------------------------------------------------
costgraph-operator-kubernetes helpers
------------------------------------------------------------------------------
*/}}
{{- define "costgraph-operator.kubernetesName" -}}
{{- printf "%s-kubernetes" (include "costgraph-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "costgraph-operator.kubernetesLabels" -}}
helm.sh/chart: {{ include "costgraph-operator.chart" . }}
{{ include "costgraph-operator.kubernetesSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "costgraph-operator.kubernetesSelectorLabels" -}}
app.kubernetes.io/name: {{ include "costgraph-operator.kubernetesName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: operator-kubernetes
{{- end }}

{{/*
------------------------------------------------------------------------------
costgraph-operator-prometheus helpers
------------------------------------------------------------------------------
*/}}
{{- define "costgraph-operator.prometheusName" -}}
{{- printf "%s-prometheus" (include "costgraph-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "costgraph-operator.prometheusLabels" -}}
helm.sh/chart: {{ include "costgraph-operator.chart" . }}
{{ include "costgraph-operator.prometheusSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "costgraph-operator.prometheusSelectorLabels" -}}
app.kubernetes.io/name: {{ include "costgraph-operator.prometheusName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: operator-prometheus
{{- end }}
