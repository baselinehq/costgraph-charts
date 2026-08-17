{{/*
Expand the name of the chart.
*/}}
{{- define "costgraph-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "costgraph-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "costgraph-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "costgraph-operator.labels" -}}
helm.sh/chart: {{ include "costgraph-operator.chart" . }}
{{ include "costgraph-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "costgraph-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "costgraph-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "costgraph-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "costgraph-operator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Namespace helper
*/}}
{{- define "costgraph-operator.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}
*/}}

{{/*
Resolve the name of the Secret holding the API key.
Uses an existing secret when global.existingSecret is set; otherwise uses
the Secret created by this chart.
*/}}
{{- define "costgraph-operator.apiKeySecretName" -}}
{{- if .Values.global.existingSecret -}}
{{- .Values.global.existingSecret -}}
{{- else -}}
{{- printf "%s-credentials" (include "costgraph-operator.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/*
Resolve the key within the API-key Secret.
When referencing a chart-managed secret the key is always "apiKey".
existingSecretKey is only honoured when an existing secret is provided.
*/}}
{{- define "costgraph-operator.apiKeySecretKey" -}}
{{- if .Values.global.existingSecret -}}
{{- default "apiKey" .Values.global.existingSecretKey -}}
{{- else -}}
apiKey
{{- end -}}
{{- end }}

{{/*

------------------------------------------------------------------------------
costgraph-operator-kubernetes helpers
------------------------------------------------------------------------------
*/}}
{{- define "costgraph-operator.kubernetesName" -}}
{{- printf "%s-kubernetes" (include "costgraph-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "costgraph-operator.kubernetesLabels" -}}
helm.sh/chart: {{ include "costgraph-operator.chart" . }}
{{ include "costgraph-operator.kubernetesSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "costgraph-operator.kubernetesSelectorLabels" -}}
app.kubernetes.io/name: {{ include "costgraph-operator.kubernetesName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: operator-kubernetes
{{- end }}

{{/*
------------------------------------------------------------------------------
costgraph-operator-prometheus helpers
------------------------------------------------------------------------------
*/}}
{{- define "costgraph-operator.prometheusName" -}}
{{- printf "%s-prometheus" (include "costgraph-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "costgraph-operator.prometheusLabels" -}}
helm.sh/chart: {{ include "costgraph-operator.chart" . }}
{{ include "costgraph-operator.prometheusSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "costgraph-operator.prometheusSelectorLabels" -}}
app.kubernetes.io/name: {{ include "costgraph-operator.prometheusName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: operator-prometheus
{{- end }}

{{/*
------------------------------------------------------------------------------
costgraph-operator-flowtrace helpers
------------------------------------------------------------------------------
*/}}
{{- define "costgraph-operator.flowtraceName" -}}
{{- printf "%s-flowtrace" (include "costgraph-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "costgraph-operator.flowtraceLabels" -}}
helm.sh/chart: {{ include "costgraph-operator.chart" . }}
{{ include "costgraph-operator.flowtraceSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "costgraph-operator.flowtraceSelectorLabels" -}}
app.kubernetes.io/name: {{ include "costgraph-operator.flowtraceName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: flowtrace
{{- end }}

{{/*
API groups that ship with Kubernetes itself. Helm's built-in capability set
contains exactly these, so seeing nothing outside this list means
.Capabilities.APIVersions was never populated from a cluster.
*/}}
{{- define "costgraph-operator.kubernetesAPIGroups" -}}
- admissionregistration.k8s.io
- apiextensions.k8s.io
- apiregistration.k8s.io
- apps
- authentication.k8s.io
- authorization.k8s.io
- autoscaling
- batch
- certificates.k8s.io
- coordination.k8s.io
- discovery.k8s.io
- events.k8s.io
- extensions
- flowcontrol.apiserver.k8s.io
- internal.apiserver.k8s.io
- networking.k8s.io
- node.k8s.io
- policy
- rbac.authorization.k8s.io
- resource.k8s.io
- scheduling.k8s.io
- storage.k8s.io
- storagemigration.k8s.io
{{- end }}

{{/*
Every API group the cluster serves, minus core, minus the groups the built-in
rules already cover resource by resource, minus rbac.excludeAPIGroups.
Returned as a YAML array.
*/}}
{{- define "costgraph-operator.grantedAPIGroups" -}}
{{- $excluded := concat .Values.rbac.excludeAPIGroups .Values.rbac.builtinAPIGroups -}}
{{- $groups := list -}}
{{- range .Capabilities.APIVersions -}}
{{- $group := splitList "/" . | first -}}
{{/* Capabilities carries both "group/version" and "group/version/Kind", so a
     core kind arrives as "v1/Pod" and its leading segment is a version, not a
     group. Core is enumerated by the rules that use this helper. */}}
{{- if not (regexMatch "^v[0-9]+((alpha|beta)[0-9]+)?$" $group) -}}
{{- if not (has $group $excluded) -}}
{{- $groups = append $groups $group -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $groups | uniq | sortAlpha | toYaml -}}
{{- end }}

{{/*
Abort when the chart is rendered without cluster discovery.

Helm populates .Capabilities.APIVersions from the cluster only when the
renderer can reach one. `helm install` and `helm upgrade` can. Plain
`helm template`, client-side `--dry-run`, Kustomize chart inflation and Argo CD
before v2.10 fall back to Helm's built-in set, which contains no custom
resource groups at all. The operator would install cleanly and silently
collect nothing outside core Kubernetes, so fail loudly instead.

Helm merges any --api-versions it is given with its built-in set, so the test
is whether a group appeared that Kubernetes itself does not ship.
*/}}
{{- define "costgraph-operator.assertClusterDiscovery" -}}
{{- if .Values.rbac.requireClusterDiscovery -}}
{{- $builtin := include "costgraph-operator.kubernetesAPIGroups" . | fromYamlArray -}}
{{- $found := false -}}
{{- range .Capabilities.APIVersions -}}
{{- $group := splitList "/" . | first -}}
{{- if not (regexMatch "^v[0-9]+((alpha|beta)[0-9]+)?$" $group) -}}
{{- if not (has $group $builtin) -}}
{{- $found = true -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if not $found -}}
{{- fail "costgraph-operator: no custom resource API groups were discovered, so this chart was rendered without cluster access and would collect nothing beyond core Kubernetes. Render with `helm install`/`helm upgrade`, or pass --api-versions (Argo CD does this from v2.10; older versions do not). If this cluster genuinely has no CRDs, set rbac.requireClusterDiscovery=false." -}}
{{- end -}}
{{- end -}}
{{- end }}
