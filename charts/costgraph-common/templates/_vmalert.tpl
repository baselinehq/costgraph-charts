{{/*
Renders the Service and Deployment for one vmalert rule set.

vmalert evaluates the recording rules the aggregator reads. A deployment runs
one vmalert per rule set, because the sets write to different retention tiers
and differ only in which rules they load and where they remote-write.

The rules are read from the aggregator image rather than a ConfigMap, so the
image tag is what rolls this workload when the rules change.

Required: ctx, name, labels, selectorLabels, image, rulesImage, rulesPath,
datasourceURL, remoteWriteURL.
*/}}
{{/*
The rules come from the aggregator image rather than a ConfigMap, so the image
tag is what rolls a workload when the rules change and no chart carries a copy
of the rule files.
*/}}
{{- define "costgraph.vmalert.rulesInitContainer" -}}
- name: rules
  image: {{ required "vmalert: rulesImage is required" .rulesImage | quote }}
  {{- with .imagePullPolicy }}
  imagePullPolicy: {{ . }}
  {{- end }}
  {{- with .containerSecurityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  command:
    - /bin/busybox
    - cp
    - -r
    - {{ printf "%s/." (required "vmalert: rulesPath is required" .rulesPath) }}
    - /rules
  volumeMounts:
    - name: rules
      mountPath: /rules
{{- end -}}

{{/*
/tmp is writable so the container can run with a read-only root filesystem.
*/}}
{{- define "costgraph.vmalert.volumes" -}}
- name: rules
  emptyDir: {}
- name: tmp
  emptyDir: {}
{{- end -}}

{{- define "costgraph.vmalert.volumeMounts" -}}
- name: rules
  mountPath: /etc/vmalert/rules
  readOnly: true
- name: tmp
  mountPath: /tmp
{{- end -}}

{{- define "costgraph.vmalert" -}}
{{- $name := required "vmalert: name is required" .name -}}
{{- $ctx := required "vmalert: ctx is required" .ctx -}}
{{- $port := .port | default 8880 -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ $name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    {{- toYaml .labels | nindent 4 }}
spec:
  selector:
    {{- toYaml .selectorLabels | nindent 4 }}
  ports:
    - name: http
      port: {{ $port }}
      targetPort: http
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    {{- toYaml .labels | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- toYaml .selectorLabels | nindent 6 }}
  template:
    metadata:
      labels:
        {{- toYaml .labels | nindent 8 }}
    spec:
      {{- with .imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      initContainers:
        {{- include "costgraph.vmalert.rulesInitContainer" . | nindent 8 }}
      containers:
        - name: vmalert
          image: {{ required "vmalert: image is required" .image | quote }}
          {{- with .imagePullPolicy }}
          imagePullPolicy: {{ . }}
          {{- end }}
          {{- with .containerSecurityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          args:
            - -rule=/etc/vmalert/rules/*.yaml
            - -datasource.url={{ required "vmalert: datasourceURL is required" .datasourceURL }}
            - -remoteWrite.url={{ required "vmalert: remoteWriteURL is required" .remoteWriteURL }}
            - -evaluationInterval={{ .evaluationInterval | default "1m" }}
            # Offsets the query time to absorb ingestion delay; chained rules
            # read the output of earlier ones and would otherwise read nothing.
            - -rule.evalDelay={{ .evalDelay | default "30s" }}
            - -remoteWrite.flushInterval={{ .flushInterval | default "5s" }}
            - -external.label=job={{ .externalJobLabel | default "aggregator" }}
            - -httpListenAddr=:{{ $port }}
          ports:
            - name: http
              containerPort: {{ $port }}
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 10
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 20
            periodSeconds: 20
          {{- with .resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            {{- include "costgraph.vmalert.volumeMounts" . | nindent 12 }}
      volumes:
        {{- include "costgraph.vmalert.volumes" . | nindent 8 }}
      {{- with .nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}
