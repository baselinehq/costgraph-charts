{{/*
A Service whose name and selector are chosen rather than derived. stakater names
its Service after the application and selects its own pods, so a Service
fronting another chart's workload, or a headless peer Service alongside the
normal one, cannot be expressed there.

Required: ctx, name, labels, selectorLabels, ports.
*/}}
{{- define "costgraph.service" -}}
{{- $ctx := required "service: ctx is required" .ctx -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ required "service: name is required" .name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    {{- toYaml (required "service: labels is required" .labels) | nindent 4 }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .type | default "ClusterIP" }}
  {{- with .clusterIP }}
  clusterIP: {{ . | quote }}
  {{- end }}
  {{- if not (kindIs "invalid" .publishNotReadyAddresses) }}
  publishNotReadyAddresses: {{ .publishNotReadyAddresses }}
  {{- end }}
  selector:
    {{- toYaml (required "service: selectorLabels is required" .selectorLabels) | nindent 4 }}
  ports:
    {{- range required "service: ports is required" .ports }}
    - name: {{ .name }}
      port: {{ .port }}
      targetPort: {{ .targetPort }}
      protocol: {{ .protocol | default "TCP" }}
    {{- end }}
{{- end -}}
