{{- define "focus-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Capped at 52 so the Job the CronJob controller spawns (<name>-<timestamp>)
stays within Kubernetes' 63-character limit. A name over the cap keeps its
first 43 characters and gains a hash of the whole, so two long names that share
a prefix still render distinct. */}}
{{- define "focus-exporter.fullname" -}}
{{- $name := "" -}}
{{- if .Values.fullnameOverride -}}
{{- $name = .Values.fullnameOverride -}}
{{- else -}}
{{- $chartName := default .Chart.Name .Values.nameOverride -}}
{{- if contains $chartName .Release.Name -}}
{{- $name = .Release.Name -}}
{{- else -}}
{{- $name = printf "%s-%s" .Release.Name $chartName -}}
{{- end -}}
{{- end -}}
{{- if gt (len $name) 52 -}}
{{- printf "%s-%s" (trunc 43 $name | trimSuffix "-") (substr 0 8 (sha256sum $name)) -}}
{{- else -}}
{{- $name | trimSuffix "-" -}}
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
