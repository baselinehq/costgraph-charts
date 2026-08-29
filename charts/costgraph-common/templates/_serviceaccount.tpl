{{/*
A ServiceAccount whose name is chosen rather than derived, for workloads that
share one identity or that must keep a name an existing IAM trust policy or
RoleBinding already refers to.

Required: ctx, name, labels.
*/}}
{{- define "costgraph.serviceAccount" -}}
{{- $ctx := required "serviceAccount: ctx is required" .ctx -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ required "serviceAccount: name is required" .name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    {{- toYaml (required "serviceAccount: labels is required" .labels) | nindent 4 }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ if kindIs "bool" .automount }}{{ .automount }}{{ else }}true{{ end }}
{{- end -}}
