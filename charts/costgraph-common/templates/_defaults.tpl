{{/*
Layers one component's values over the shared defaults.

mergeOverwrite mutates its first argument, so both inputs are deep-copied
before merging: without that, the first component's result becomes the
defaults every later component is merged onto.

mergeOverwrite also ignores a nil in the override, so a key the caller set to
null is pruned afterwards; that is the only way to un-set an inherited map.
*/}}
{{- define "costgraph.componentValues" -}}
{{- $_ := required "componentValues: ctx is required" .ctx -}}
{{- $defaults := deepCopy (.defaults | default dict) -}}
{{- $component := .component | default dict -}}
{{- $merged := mergeOverwrite $defaults (deepCopy $component) -}}
{{- range $key, $value := $component }}
{{- if kindIs "invalid" $value }}
{{- $_ := unset $merged $key }}
{{- end }}
{{- end }}
{{- range $key, $value := $merged }}
{{- if kindIs "invalid" $value }}
{{- $_ := unset $merged $key }}
{{- end }}
{{- end }}
{{- toYaml $merged -}}
{{- end -}}
