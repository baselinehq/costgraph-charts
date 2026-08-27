{{/*
An ExternalSecret whose name is chosen rather than derived. stakater names its
secrets after the application, so a secret shared between workloads, or one
named for the data it carries, cannot be expressed there.

Required: ctx, name, secretStoreName, data. data maps a secret key to the
remote key it is read from.
*/}}
{{- define "costgraph.externalSecret" -}}
{{- $ctx := required "externalSecret: ctx is required" .ctx -}}
{{- $name := required "externalSecret: name is required" .name -}}
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: {{ $name }}
  namespace: {{ $ctx.Release.Namespace }}
  {{- with .labels }}
  labels:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  refreshInterval: {{ .refreshInterval | default "1h" }}
  secretStoreRef:
    kind: {{ .secretStoreKind | default "ClusterSecretStore" }}
    name: {{ required "externalSecret: secretStoreName is required" .secretStoreName | quote }}
  target:
    name: {{ .targetName | default $name }}
  data:
    {{- range $secretKey, $remoteKey := required "externalSecret: data is required" .data }}
    - secretKey: {{ $secretKey }}
      remoteRef:
        key: {{ $remoteKey | quote }}
    {{- end }}
{{- end -}}
