{{/*
A ConfigMap whose name is chosen rather than derived. stakater forces the name
to <appName>-<suffix>, so a ConfigMap mounted by another chart, or one whose
name a consumer already hardcodes, cannot be expressed there.

Required: ctx, name, labels.
*/}}
{{- define "costgraph.configMap" -}}
{{- $ctx := required "configMap: ctx is required" .ctx -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ required "configMap: name is required" .name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    {{- toYaml (required "configMap: labels is required" .labels) | nindent 4 }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- if not (kindIs "invalid" .immutable) }}
immutable: {{ .immutable }}
{{- end }}
{{- with .data }}
data:
  {{- range $key, $value := . }}
  {{- $v := $value | toString }}
  {{- if or (not (contains "\n" $v)) (hasPrefix " " $v) (hasPrefix "\t" $v) (hasSuffix "\n\n" $v) }}
  {{ $key }}: {{ $v | quote }}
  {{- else if hasSuffix "\n" $v }}
  {{ $key }}: |
    {{- $v | trimSuffix "\n" | nindent 4 }}
  {{- else }}
  {{ $key }}: |-
    {{- $v | nindent 4 }}
  {{- end }}
  {{- end }}
{{- end }}
{{- with .binaryData }}
binaryData:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
