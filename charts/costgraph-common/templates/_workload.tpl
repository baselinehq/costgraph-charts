{{/*
One pod spec shared by the Deployment, StatefulSet and DaemonSet forms.

serviceAccountName is emitted only when set: a pre-install hook Job runs before
the ServiceAccount exists, and stakater's application chart always writes the
field, which is why this pod spec exists at all.

automountServiceAccountToken uses hasKey so an explicit false is distinct from
an absent key, which leaves the cluster default in place.
*/}}
{{- define "costgraph.workload.podSpec" -}}
{{- $name := .name -}}
{{- with .serviceAccountName }}
serviceAccountName: {{ . }}
{{- end }}
{{- if hasKey . "automountServiceAccountToken" }}
automountServiceAccountToken: {{ .automountServiceAccountToken }}
{{- end }}
{{- with .imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .priorityClassName }}
priorityClassName: {{ . }}
{{- end }}
{{- if .hostNetwork }}
hostNetwork: true
{{- end }}
{{- if .hostPID }}
hostPID: true
{{- end }}
{{- with .dnsPolicy }}
dnsPolicy: {{ . }}
{{- end }}
{{- if not (kindIs "invalid" .terminationGracePeriodSeconds) }}
terminationGracePeriodSeconds: {{ .terminationGracePeriodSeconds }}
{{- end }}
{{- with .initContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers:
  - name: {{ .containerName | default (splitList "-" $name | last) }}
    image: {{ required "workload: image is required" .image | quote }}
    {{- with .imagePullPolicy }}
    imagePullPolicy: {{ . }}
    {{- end }}
    {{- with .containerSecurityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .command }}
    command:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .args }}
    args:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .env }}
    env:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .envFrom }}
    envFrom:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .ports }}
    ports:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .startupProbe }}
    startupProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .readinessProbe }}
    readinessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .livenessProbe }}
    livenessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .lifecycle }}
    lifecycle:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .volumeMounts }}
    volumeMounts:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- with .volumes }}
volumes:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
A Deployment, StatefulSet or DaemonSet over one pod spec.

Required: ctx, name, labels, selectorLabels, image, and serviceName when kind
is StatefulSet.
*/}}
{{- define "costgraph.workload" -}}
{{- $ctx := required "workload: ctx is required" .ctx -}}
{{- $name := required "workload: name is required" .name -}}
{{- $kind := .kind | default "Deployment" -}}
apiVersion: apps/v1
kind: {{ $kind }}
metadata:
  name: {{ $name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    {{- toYaml (required "workload: labels is required" .labels) | nindent 4 }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if ne $kind "DaemonSet" }}
  replicas: {{ if kindIs "invalid" .replicas }}1{{ else }}{{ .replicas }}{{ end }}
  {{- end }}
  {{- if eq $kind "StatefulSet" }}
  serviceName: {{ required "workload: serviceName is required for a StatefulSet" .serviceName }}
  {{- end }}
  {{- with .strategy }}
  {{- if eq $kind "Deployment" }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- else }}
  updateStrategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- end }}
  selector:
    matchLabels:
      {{- toYaml (required "workload: selectorLabels is required" .selectorLabels) | nindent 6 }}
  template:
    metadata:
      labels:
        {{- toYaml (mergeOverwrite (deepCopy (.podLabels | default dict)) (deepCopy .selectorLabels)) | nindent 8 }}
      {{- with .podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- include "costgraph.workload.podSpec" . | trim | nindent 6 }}
  {{- if eq $kind "StatefulSet" }}
  {{- with .volumeClaimTemplates }}
  volumeClaimTemplates:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- end }}
{{- end -}}
