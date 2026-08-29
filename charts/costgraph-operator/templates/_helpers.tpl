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
{{- .Release.Namespace }}
{{- end }}

{{/*
Resolve the name of the Secret holding the API key.
Uses an existing secret when global.existingSecret is set; otherwise uses
the Secret created by this chart.

The body reads only .Release and .Values.global so that stakater's application
subchart, which templates its env values in its own scope, resolves the same
name as this chart's own templates. Deriving it from fullname instead would
resolve against the subchart and silently reference a Secret that does not
exist.
*/}}
{{- define "costgraph-operator.apiKeySecretName" -}}
{{- .Values.global.existingSecret | default "costgraph-operator-credentials" | trunc 63 | trimSuffix "-" -}}
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
Per-component helpers

Every component in this chart is named by its own applicationName rather than
by the release, so that the objects stakater's application chart renders and
the ones rendered here are named the same way.
------------------------------------------------------------------------------
*/}}
{{- define "costgraph-operator.componentLabels" -}}
helm.sh/chart: {{ include "costgraph-operator.chart" .ctx }}
{{ include "costgraph-operator.componentSelectorLabels" . }}
{{- with .ctx.Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
{{- end }}

{{- define "costgraph-operator.componentSelectorLabels" -}}
app.kubernetes.io/name: {{ required "componentSelectorLabels: name is required" .name }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/component: {{ required "componentSelectorLabels: component is required" .component }}
{{- end }}

{{/*
Turn stakater's env map into the list a PodSpec takes.

The map form is what the application chart accepts, so keeping it here is what
lets every component in this chart be configured the same way. String values
are templated, again matching stakater, so a value can reach back into the
release.
*/}}
{{- define "costgraph-operator.env" -}}
{{- $ctx := required "env: ctx is required" .ctx -}}
{{- range $name, $spec := .env }}
- name: {{ $name }}
{{- if kindIs "map" $spec }}
{{- if hasKey $spec "valueFrom" }}
  valueFrom:
    {{- toYaml $spec.valueFrom | nindent 4 }}
{{- else }}
  value: {{ tpl (toString $spec.value) $ctx | quote }}
{{- end }}
{{- else }}
  value: {{ tpl (toString $spec) $ctx | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Read rules for the built-in Kubernetes resources CostGraph collects.

The single source for both the ClusterRole rules and the set of groups the
discovered custom-resource grant must not re-widen. core/v1 is deliberately
absent: it is enumerated separately because it holds Secrets, ConfigMaps and
ServiceAccounts, which must never be granted.
*/}}
{{- define "costgraph-operator.builtinRules" -}}
- apiGroups: ["apps"]
  resources: ["daemonsets", "deployments", "replicasets", "statefulsets"]
- apiGroups: ["autoscaling"]
  resources: ["horizontalpodautoscalers"]
- apiGroups: ["batch"]
  resources: ["cronjobs", "jobs"]
- apiGroups: ["discovery.k8s.io"]
  resources: ["endpointslices"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingressclasses", "ingresses", "networkpolicies"]
- apiGroups: ["policy"]
  resources: ["poddisruptionbudgets"]
- apiGroups: ["storage.k8s.io"]
  resources: ["csidrivers", "csinodes", "storageclasses", "volumeattachments", "volumeattributesclasses"]
{{- end }}

{{/*
The API groups covered by builtinRules, derived so the two cannot drift.
*/}}
{{- define "costgraph-operator.builtinAPIGroups" -}}
{{- $groups := list -}}
{{- range include "costgraph-operator.builtinRules" . | fromYamlArray -}}
{{- $groups = concat $groups .apiGroups -}}
{{- end -}}
{{- $groups | uniq | sortAlpha | toYaml -}}
{{- end }}

{{/*
API groups that ship with Kubernetes itself.

Helm's built-in capability set contains exactly these, so seeing nothing
outside this list means .Capabilities.APIVersions was never populated from a
cluster. Entries here intentionally repeat names in rbac.excludeAPIGroups: this
list answers "what does upstream ship", not "what may CostGraph read". Keep
them separate, or excluding a new vendor group would break the discovery check.
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
Every API group the cluster serves, minus core. Returned as a YAML array.

Capabilities carries both "group/version" and "group/version/Kind", so a core
kind arrives as "v1/Pod" and its leading segment is a version, not a group.
*/}}
{{- define "costgraph-operator.discoveredAPIGroups" -}}
{{- $groups := list -}}
{{- range .Capabilities.APIVersions -}}
{{- $group := splitList "/" . | first -}}
{{- if not (regexMatch "^v[0-9]+((alpha|beta)[0-9]+)?$" $group) -}}
{{- $groups = append $groups $group -}}
{{- end -}}
{{- end -}}
{{- $groups | uniq | sortAlpha | toYaml -}}
{{- end }}

{{/*
Custom resource API groups to grant: everything discovered, minus the groups
builtinRules already covers resource by resource, minus rbac.excludeAPIGroups.
*/}}
{{- define "costgraph-operator.grantedAPIGroups" -}}
{{- $builtin := include "costgraph-operator.builtinAPIGroups" . | fromYamlArray -}}
{{- $excluded := concat .Values.rbac.excludeAPIGroups $builtin -}}
{{- $groups := list -}}
{{- range include "costgraph-operator.discoveredAPIGroups" . | fromYamlArray -}}
{{- if not (has . $excluded) -}}
{{- $groups = append $groups . -}}
{{- end -}}
{{- end -}}
{{- $groups | toYaml -}}
{{- end }}

{{/*
Abort when the chart is rendered without cluster discovery.

Helm populates .Capabilities.APIVersions from the cluster only when the
renderer can reach one. `helm install` and `helm upgrade` can. Plain
`helm template`, client-side `--dry-run`, Kustomize chart inflation and Argo CD
before v2.10 fall back to Helm's built-in set, which contains no custom
resource groups at all. The operator would install cleanly and silently collect
nothing outside core Kubernetes, so fail loudly instead.

Helm merges any --api-versions it is given with its built-in set, so the test
is whether a group appeared that Kubernetes itself does not ship.
*/}}
{{- define "costgraph-operator.assertClusterDiscovery" -}}
{{- if and .Values.rbac.requireClusterDiscovery .Values.rbac.grantCustomResources -}}
{{- $shipped := include "costgraph-operator.kubernetesAPIGroups" . | fromYamlArray -}}
{{- $custom := list -}}
{{- range include "costgraph-operator.discoveredAPIGroups" . | fromYamlArray -}}
{{- if not (has . $shipped) -}}
{{- $custom = append $custom . -}}
{{- end -}}
{{- end -}}
{{- if not $custom -}}
{{- fail "costgraph-operator: no custom resource API groups were discovered, so this chart was rendered without cluster access and would collect nothing beyond core Kubernetes. Render with `helm install`/`helm upgrade`, or pass --api-versions (Argo CD does this from v2.10; older versions do not). If this cluster genuinely has no CRDs, set rbac.requireClusterDiscovery=false." -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "costgraph-operator.remoteWriteURL" -}}
{{- coalesce .component .root.Values.global.remoteWriteURL "https://tsdb.costgraph.ai" -}}
{{- end -}}
