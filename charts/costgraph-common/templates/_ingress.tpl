{{/*
An Ingress whose backends are chosen per path. stakater can only route to its
own Service by port name, so a single host fanning out to several Services on
numeric ports cannot be expressed there.

Required: ctx, name, labels, hosts. A servicePort may be a number or a port
name; both spellings of the backend port are produced from the value's type.
*/}}
{{- define "costgraph.ingress" -}}
{{- $ctx := required "ingress: ctx is required" .ctx -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ required "ingress: name is required" .name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    {{- toYaml (required "ingress: labels is required" .labels) | nindent 4 }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with .className }}
  ingressClassName: {{ . }}
  {{- end }}
  {{- with .defaultBackend }}
  defaultBackend:
    service:
      name: {{ .serviceName }}
      port:
        {{- include "costgraph.ingressBackendPort" (dict "port" .servicePort) | nindent 8 }}
  {{- end }}
  {{- with .tls }}
  tls:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  rules:
    {{- range required "ingress: hosts is required" .hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType | default "Prefix" }}
            backend:
              service:
                name: {{ .serviceName }}
                port:
                  {{- include "costgraph.ingressBackendPort" (dict "port" .servicePort) | nindent 18 }}
          {{- end }}
    {{- end }}
{{- end -}}

{{- define "costgraph.ingressBackendPort" -}}
{{- $port := required "ingressBackendPort: port is required" .port -}}
{{- if or (kindIs "float64" $port) (kindIs "int" $port) (kindIs "int64" $port) -}}
number: {{ $port }}
{{- else -}}
name: {{ $port | quote }}
{{- end -}}
{{- end -}}
