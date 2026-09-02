{{/*
Build the SCRAPE_TARGETS env value as JSON from operatorPrometheus.scrapeTargets.

This stays a parent-chart template because it reads a sibling top-level key
(prometheus-node-exporter.service.port), which is invisible from inside a
subchart, and because it uses fail/required to reject a misconfigured target at
render time instead of at container start.

scrapeTargets is a map keyed by target name so callers can override individual
fields via `--set` without clobbering siblings. String fields are coerced via
toString before tpl so non-string YAML values do not blow up tpl. Entries that
are nil or non-map (e.g. produced by `--set foo[3].x=y` against a map) are
skipped defensively. Entries with enabled: false are excluded. `int` coerces
non-numeric input to 0, so checking < 1 also catches strings like "foo".
Helm value keys are camelCase; emitted JSON keys are snake_case to match the
operator config struct tags.
*/}}
{{- define "costgraph-operator.scrapeTargets" -}}
{{- $ctx := required "scrapeTargets: ctx is required" .ctx -}}
{{- $targets := list -}}
{{- range $name, $tgt := .targets }}
  {{- if and $tgt (kindIs "map" $tgt) }}
    {{- $enabled := true }}
    {{- if hasKey $tgt "enabled" }}{{- $enabled = $tgt.enabled }}{{- end }}
    {{- if $enabled }}
      {{- $kind := default "pod" $tgt.kind }}
      {{- if eq $kind "node" }}
        {{- /* Node targets scrape kubelets via the API-server node proxy;
        namespace/port do not apply. labelSelector is an optional node filter. */}}
        {{- $t := dict "name" $name "kind" "node" }}
        {{- if $tgt.labelSelector }}{{- $_ := set $t "label_selector" (tpl ($tgt.labelSelector | toString) $ctx) }}{{- end }}
        {{- if $tgt.path }}{{- $_ := set $t "path" (tpl ($tgt.path | toString) $ctx) }}{{- end }}
        {{- if $tgt.nodeMetrics }}{{- $_ := set $t "node_metrics" true }}{{- end }}
        {{- if $tgt.metricNamePrefixes }}{{- $_ := set $t "metric_name_prefixes" $tgt.metricNamePrefixes }}{{- end }}
        {{- $targets = append $targets $t }}
      {{- else if eq $kind "pod" }}
        {{- $namespace := required (printf "operatorPrometheus.scrapeTargets.%s: namespace is required" $name) $tgt.namespace }}
        {{- $selector := required (printf "operatorPrometheus.scrapeTargets.%s: labelSelector is required" $name) $tgt.labelSelector }}
        {{- $port := required (printf "operatorPrometheus.scrapeTargets.%s: port is required" $name) $tgt.port }}
        {{- $portInt := int (tpl ($port | toString) $ctx) }}
        {{- if or (lt $portInt 1) (gt $portInt 65535) }}
          {{- fail (printf "operatorPrometheus.scrapeTargets.%s: port must be an integer between 1 and 65535, got %v" $name $port) }}
        {{- end }}
        {{- $t := dict
            "name"           $name
            "namespace"      (tpl ($namespace | toString) $ctx)
            "label_selector" (tpl ($selector | toString) $ctx)
            "port"           $portInt }}
        {{- if $tgt.path }}{{- $_ := set $t "path" (tpl ($tgt.path | toString) $ctx) }}{{- end }}
        {{- if $tgt.nodeMetrics }}{{- $_ := set $t "node_metrics" true }}{{- end }}
        {{- if $tgt.metricNamePrefixes }}{{- $_ := set $t "metric_name_prefixes" $tgt.metricNamePrefixes }}{{- end }}
        {{- $targets = append $targets $t }}
      {{- else }}
        {{- fail (printf "operatorPrometheus.scrapeTargets.%s: kind must be \"pod\" or \"node\", got %v" $name $kind) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $targets | toJson -}}
{{- end }}
