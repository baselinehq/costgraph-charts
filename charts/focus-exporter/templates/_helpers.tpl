{{- define "focus-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Capped at 52: the CronJob controller names its Jobs <cronjob>-<timestamp>,
which must stay within the 63-character limit. */}}
{{- define "focus-exporter.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 52 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 52 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 52 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "focus-exporter.labels" -}}
app.kubernetes.io/name: {{ include "focus-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}

{{/* Every auxiliary resource keys off one name, so a rename cannot desync a
reference from the resource it points at. */}}
{{- define "focus-exporter.configMapName" -}}{{ include "focus-exporter.fullname" . }}-config{{- end -}}
{{- define "focus-exporter.costgraphSecretName" -}}{{ default (printf "%s-costgraph" (include "focus-exporter.fullname" .)) .Values.costgraph.existingSecret }}{{- end -}}
{{- define "focus-exporter.credentialsSecretName" -}}{{ default (printf "%s-credentials" (include "focus-exporter.fullname" .)) .Values.credentialsExistingSecret }}{{- end -}}
{{- define "focus-exporter.pullSecretName" -}}{{ default (printf "%s-registry" (include "focus-exporter.fullname" .)) .Values.imagePullSecret.existingSecret }}{{- end -}}
{{- define "focus-exporter.serviceAccountName" -}}{{ default (include "focus-exporter.fullname" .) .Values.serviceAccount.name }}{{- end -}}
