{{/*
The full label set. Callers pass the component and any extra labels, because a
library chart cannot know which of the caller's workloads it is rendering.
*/}}
{{- define "costgraph.labels" -}}
{{- $ctx := required "labels: ctx is required" .ctx -}}
helm.sh/chart: {{ printf "%s-%s" $ctx.Chart.Name $ctx.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "costgraph.selectorLabels" (dict "ctx" $ctx "name" $ctx.Chart.Name "component" .component) }}
{{- with $ctx.Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $ctx.Release.Service }}
{{- with .extra }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Only the trio that lands in spec.selector.matchLabels, which is immutable on a
Deployment and StatefulSet: anything that changes between upgrades (chart
version, app version) must stay out of it.
*/}}
{{- define "costgraph.selectorLabels" -}}
{{- $ctx := required "selectorLabels: ctx is required" .ctx -}}
app.kubernetes.io/name: {{ required "selectorLabels: name is required" .name }}
app.kubernetes.io/instance: {{ $ctx.Release.Name }}
{{- with .component }}
app.kubernetes.io/component: {{ . }}
{{- end }}
{{- end -}}

{{/*
Joins a repository and a tag. A tag beginning with sha256: is a digest, which
joins with @ rather than :.
*/}}
{{- define "costgraph.imageRef" -}}
{{- if hasPrefix "sha256:" (required "imageRef: tag is required" .tag) -}}
{{ required "imageRef: repository is required" .repository }}@{{ .tag }}
{{- else -}}
{{ required "imageRef: repository is required" .repository }}:{{ .tag }}
{{- end -}}
{{- end -}}

{{- define "costgraph.componentName" -}}
{{- printf "%s-%s" (required "componentName: prefix is required" .prefix) (required "componentName: component is required" .component) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
