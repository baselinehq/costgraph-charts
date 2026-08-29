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
