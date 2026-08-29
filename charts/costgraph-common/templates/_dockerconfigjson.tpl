{{/*
An image pull Secret built from a registry credential the chart already holds,
so an install needs no separate `kubectl create secret docker-registry` step.

Required: ctx, name, labels, registry, password.
*/}}
{{- define "costgraph.dockerConfigJsonSecret" -}}
{{- $ctx := required "dockerConfigJsonSecret: ctx is required" .ctx -}}
{{- $registry := required "dockerConfigJsonSecret: registry is required" .registry -}}
{{- $username := .username | default "x" -}}
{{- $password := required "dockerConfigJsonSecret: password is required" .password -}}
{{- $auth := printf "%s:%s" $username $password | b64enc -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ required "dockerConfigJsonSecret: name is required" .name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    {{- toYaml (required "dockerConfigJsonSecret: labels is required" .labels) | nindent 4 }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{ printf `{"auths":{%q:{"username":%q,"password":%q,"auth":%q}}}` $registry $username $password $auth | b64enc | quote }}
{{- end -}}
