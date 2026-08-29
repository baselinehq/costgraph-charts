{{/*
A Secret whose name is chosen rather than derived, with keys that must survive
an upgrade unchanged.

An entry listed under preserve is read back from the live Secret when one
exists, and only generated on a first install. Regenerating an API key secret or
an encryption key on every upgrade invalidates issued tokens and makes already
encrypted rows unreadable.

Generator specs: randAlphaNum:<n>, randAlphaNum:<n>|b64enc, value:<literal>.

Required: ctx, name, labels.
*/}}
{{- define "costgraph.secret" -}}
{{- $ctx := required "secret: ctx is required" .ctx -}}
{{- $name := required "secret: name is required" .name -}}
{{- $existing := dict -}}
{{- if .preserve -}}
{{- $existing = (lookup "v1" "Secret" $ctx.Release.Namespace $name) | default dict -}}
{{- end -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ $name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    {{- toYaml (required "secret: labels is required" .labels) | nindent 4 }}
  {{- if or .annotations .resourcePolicyKeep }}
  annotations:
    {{- with .annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- if .resourcePolicyKeep }}
    helm.sh/resource-policy: keep
    {{- end }}
  {{- end }}
type: {{ .type | default "Opaque" }}
{{- $stringData := dict }}
{{- range $key, $value := .stringData }}
{{- if and (not (kindIs "invalid" $value)) (ne ($value | toString) "") }}
{{- $_ := set $stringData $key $value }}
{{- end }}
{{- end }}
{{- with $stringData }}
stringData:
  {{- range $key, $value := . }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
{{- if or .data .preserve }}
data:
  {{- range $key, $value := .data }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
  {{- range $key, $spec := .preserve }}
  {{- if and $existing.data (hasKey ($existing.data | default dict) $key) }}
  {{ $key }}: {{ index $existing.data $key | quote }}
  {{- else }}
  {{ $key }}: {{ include "costgraph.generatedValue" (dict "spec" $spec) | b64enc | quote }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
The plaintext behind a preserved key, for a caller that has to embed the same
generated password in a connection URL. Reads the live Secret so the URL matches
the credential already in use instead of a freshly generated one.

Required: ctx, name, key, spec.
*/}}
{{- define "costgraph.preservedValue" -}}
{{- $ctx := required "preservedValue: ctx is required" .ctx -}}
{{- $name := required "preservedValue: name is required" .name -}}
{{- $key := required "preservedValue: key is required" .key -}}
{{- $existing := (lookup "v1" "Secret" $ctx.Release.Namespace $name) | default dict -}}
{{- if and $existing.data (hasKey ($existing.data | default dict) $key) -}}
{{- index $existing.data $key | b64dec -}}
{{- else -}}
{{- include "costgraph.generatedValue" (dict "spec" (required "preservedValue: spec is required" .spec)) -}}
{{- end -}}
{{- end -}}

{{- define "costgraph.generatedValue" -}}
{{- $spec := required "generatedValue: spec is required" .spec -}}
{{- $encode := hasSuffix "|b64enc" $spec -}}
{{- $spec = trimSuffix "|b64enc" $spec -}}
{{- $parts := splitn ":" 2 $spec -}}
{{- $value := "" -}}
{{- if eq $parts._0 "randAlphaNum" -}}
{{- $value = randAlphaNum (atoi $parts._1) -}}
{{- else if eq $parts._0 "value" -}}
{{- $value = $parts._1 -}}
{{- else -}}
{{- fail (printf "generatedValue: unsupported spec %q" $spec) -}}
{{- end -}}
{{- if $encode -}}
{{- $value = b64enc $value -}}
{{- end -}}
{{- $value -}}
{{- end -}}
