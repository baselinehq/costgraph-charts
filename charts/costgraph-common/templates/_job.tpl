{{/*
A one-shot Job. stakater renders Jobs, but names them after the application and
has no ttlSecondsAfterFinished, so a hook job that names itself and cleans up
after a delay cannot be expressed there.

Required: ctx, name, image.
*/}}
{{- define "costgraph.job" -}}
{{- $ctx := required "job: ctx is required" .ctx -}}
{{- $name := required "job: name is required" .name -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $name }}
  namespace: {{ $ctx.Release.Namespace }}
  {{- with .labels }}
  labels:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if not (kindIs "invalid" .backoffLimit) }}
  backoffLimit: {{ .backoffLimit }}
  {{- end }}
  {{- if not (kindIs "invalid" .ttlSecondsAfterFinished) }}
  ttlSecondsAfterFinished: {{ .ttlSecondsAfterFinished }}
  {{- end }}
  template:
    {{- with .podLabels }}
    metadata:
      labels:
        {{- toYaml . | nindent 8 }}
    {{- end }}
    spec:
      restartPolicy: {{ .restartPolicy | default "Never" }}
      {{- with .imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .initContainers }}
      initContainers:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .containerName | default $name }}
          image: {{ required "job: image is required" .image | quote }}
          {{- with .imagePullPolicy }}
          imagePullPolicy: {{ . }}
          {{- end }}
          {{- with .containerSecurityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .env }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .volumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      {{- with .nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .volumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}
