{{/*
Fail the render, not the pod. Every one of these is something onboarding hands
you, and a missing value otherwise surfaces as a CrashLoopBackOff whose cause
is buried in container logs.
*/}}
{{- define "costgraph-selfhosted.validate" -}}

{{- if and (not .Values.controlPlane.apiKey) (not .Values.controlPlane.existingSecret) -}}
{{- fail "controlPlane.apiKey (or controlPlane.existingSecret) is required: it is the deployment key CostGraph issued you, and without it this deployment cannot register, fetch its licence, or sync pricing." -}}
{{- end -}}

{{- if not .Values.controlPlane.configPublicKey -}}
{{- fail "controlPlane.configPublicKey is required: it is the pinned RSA public key used to verify signed config documents. It is issued alongside your deployment key." -}}
{{- end -}}

{{/*
Not required: with app-client provisioning enabled the control plane creates
this deployment's own client at registration and returns it in the signed
config document. Set it only when CostGraph issued you a client id by hand.
*/}}

{{- if not .Values.appBaseURL -}}
{{- fail "appBaseURL is required: it is the origin your users reach the dashboard on, and it shapes the links in invite mail CostGraph sends on your behalf." -}}
{{- end -}}

{{- if and (not .Values.postgres.url) (not .Values.postgres.existingSecret) (not .Values.postgres.bundled.enabled) -}}
{{- fail "postgres.url (or postgres.existingSecret) is required. For production, point it at a Postgres 14+ you operate — a database holding cost history should outlive a Helm release. To evaluate, set postgres.bundled.enabled=true to run one in-cluster (single replica, no backups)." -}}
{{- end -}}

{{- if and (not .Values.redis.url) (not .Values.redis.existingSecret) (not .Values.redis.bundled.enabled) -}}
{{- fail "redis.url is required (or redis.existingSecret, or redis.bundled.enabled=true). Redis holds auth and billing caches plus the metering locks." -}}
{{- end -}}

{{- if and .Values.analytics.enabled (not .Values.analytics.posthogKey) -}}
{{- fail "analytics.enabled is true but analytics.posthogKey is empty." -}}
{{- end -}}

{{- if and .Values.ingress.enabled (not .Values.ingress.hosts) -}}
{{- fail "ingress.enabled is true but ingress.hosts is empty." -}}
{{- end -}}

{{- end -}}
