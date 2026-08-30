# focus-exporter

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Runs [focus-exporter](https://github.com/baselinehq/focus-exporter) on a
schedule in your own cluster. It reads your bill where it already lives - an
object store, a provider's billing API - and pushes it to CostGraph as FOCUS.
Your provider credentials stay in your cluster; only the FOCUS rows leave.

A run is one-shot: read a window, push it, exit. Nothing is kept between runs,
so a failed run is re-run rather than repaired, and a window can be pushed
again without doubling the cost - a push replaces the window it covers.

## Install

```bash
helm repo add costgraph https://charts.costgraph.ai
helm install focus-exporter costgraph/focus-exporter \
  --set costgraph.apiKey=$COSTGRAPH_API_KEY \
  --set costgraph.connectionId=fpc_... \
  --set imagePullSecret.apiKey=$COSTGRAPH_API_KEY \
  --set config.OBJECTSTORE_BUCKET=my-focus-export \
  --set config.OBJECTSTORE_PREFIX=focus-1-2/
```

The API key needs two scopes: `focus:write` to push the bill and
`deployment:register` to pull the image from `registry.costgraph.ai`.

## Keeping credentials out of the release

A value passed with `--set` is stored in the Helm release in plain text, where
anyone who can read releases in the namespace can read it back. For anything
but a trial, create the Secrets yourself and leave the values empty. The chart
looks for them by name and creates nothing:

| Secret | Keys | Replaces |
| --- | --- | --- |
| `focus-exporter-costgraph` | `COSTGRAPH_API_KEY`, `COSTGRAPH_CONNECTION_ID`, `COSTGRAPH_URL` | `costgraph.*` |
| `focus-exporter-credentials` | whatever variables your provider reads | `credentials` |
| `focus-exporter-registry` | a `kubernetes.io/dockerconfigjson` for `registry.costgraph.ai` | `imagePullSecret.apiKey` |

## Choosing a provider

`provider` names the adapter and `config` carries its settings, which are
written to `/etc/focus-exporter/config.yaml` and read at startup. Settings that
are credentials go in `credentials` instead, which becomes a Secret and is
passed as environment variables.

Every provider and the variables it takes are listed in the
[provider reference](https://github.com/baselinehq/focus-exporter/tree/main/docs/providers).

Reading an AWS Data Export from S3, with no keys at all because the pod's
service account carries the permission:

```yaml
provider: objectstore
config:
  OBJECTSTORE_BUCKET: my-focus-export
  OBJECTSTORE_PREFIX: focus-1-2/
  OBJECTSTORE_LAYOUT: manifest
focusExporter:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/focus-export-reader
```

Reading STACKIT's report from its Object Storage:

```yaml
provider: objectstore
config:
  OBJECTSTORE_ENDPOINT: https://object.storage.eu01.stackit.schwarz
  OBJECTSTORE_BUCKET: my-cost-reports
  OBJECTSTORE_LAYOUT: latest-run
credentials:
  OBJECTSTORE_ACCESS_KEY_ID: ...
  OBJECTSTORE_SECRET_ACCESS_KEY: ...
```

## Schedule

`schedule` is a daily run at 06:00 by default, reading the current month. A
month is re-read in full each time, so the running month stays correct as the
provider revises it.

```yaml
focusExporter:
  cronJob:
    jobs:
      export:
        schedule: "0 */6 * * *"
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://stakater.github.io/stakater-charts | focusExporter(application) | 9.3.1 |

## Rendering it without a cluster

`helm template` cannot see what the cluster supports, so the upstream
application chart falls back to the removed `batch/v1beta1` for the CronJob.
Ask for the API explicitly when rendering offline; an install against a real
cluster picks `batch/v1` on its own.

```bash
helm template focus-exporter costgraph/focus-exporter --api-versions batch/v1/CronJob
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.OBJECTSTORE_LAYOUT | string | `"manifest"` |  |
| costgraph.apiKey | string | `""` |  |
| costgraph.connectionId | string | `""` |  |
| costgraph.url | string | `"https://api.costgraph.ai"` |  |
| credentials | object | `{}` |  |
| focusExporter.applicationName | string | `"focus-exporter"` |  |
| focusExporter.cronJob.enabled | bool | `true` |  |
| focusExporter.cronJob.jobs.export.backoffLimit | int | `3` |  |
| focusExporter.cronJob.jobs.export.concurrencyPolicy | string | `"Forbid"` |  |
| focusExporter.cronJob.jobs.export.containerSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| focusExporter.cronJob.jobs.export.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| focusExporter.cronJob.jobs.export.containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| focusExporter.cronJob.jobs.export.envFrom.costgraph.name | string | `"focus-exporter-costgraph"` |  |
| focusExporter.cronJob.jobs.export.envFrom.costgraph.type | string | `"secret"` |  |
| focusExporter.cronJob.jobs.export.envFrom.credentials.name | string | `"focus-exporter-credentials"` |  |
| focusExporter.cronJob.jobs.export.envFrom.credentials.optional | bool | `true` |  |
| focusExporter.cronJob.jobs.export.envFrom.credentials.type | string | `"secret"` |  |
| focusExporter.cronJob.jobs.export.failedJobsHistoryLimit | int | `3` |  |
| focusExporter.cronJob.jobs.export.image.imagePullPolicy | string | `"IfNotPresent"` |  |
| focusExporter.cronJob.jobs.export.image.repository | string | `"registry.costgraph.ai/baselinehq/focus-exporter"` |  |
| focusExporter.cronJob.jobs.export.image.tag | string | `"0.1.0"` |  |
| focusExporter.cronJob.jobs.export.imagePullSecrets[0].name | string | `"focus-exporter-registry"` |  |
| focusExporter.cronJob.jobs.export.resources.limits.memory | string | `"1Gi"` |  |
| focusExporter.cronJob.jobs.export.resources.requests.cpu | string | `"100m"` |  |
| focusExporter.cronJob.jobs.export.resources.requests.memory | string | `"256Mi"` |  |
| focusExporter.cronJob.jobs.export.restartPolicy | string | `"OnFailure"` |  |
| focusExporter.cronJob.jobs.export.schedule | string | `"0 6 * * *"` |  |
| focusExporter.cronJob.jobs.export.securityContext.runAsNonRoot | bool | `true` |  |
| focusExporter.cronJob.jobs.export.securityContext.runAsUser | int | `65532` |  |
| focusExporter.cronJob.jobs.export.securityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| focusExporter.cronJob.jobs.export.successfulJobsHistoryLimit | int | `3` |  |
| focusExporter.cronJob.jobs.export.volumeMounts[0].mountPath | string | `"/etc/focus-exporter"` |  |
| focusExporter.cronJob.jobs.export.volumeMounts[0].name | string | `"config"` |  |
| focusExporter.cronJob.jobs.export.volumeMounts[0].readOnly | bool | `true` |  |
| focusExporter.cronJob.jobs.export.volumeMounts[1].mountPath | string | `"/tmp"` |  |
| focusExporter.cronJob.jobs.export.volumeMounts[1].name | string | `"tmp"` |  |
| focusExporter.cronJob.jobs.export.volumes[0].configMap.name | string | `"focus-exporter-config"` |  |
| focusExporter.cronJob.jobs.export.volumes[0].name | string | `"config"` |  |
| focusExporter.cronJob.jobs.export.volumes[1].emptyDir | object | `{}` |  |
| focusExporter.cronJob.jobs.export.volumes[1].name | string | `"tmp"` |  |
| focusExporter.deployment.enabled | bool | `false` |  |
| focusExporter.service.enabled | bool | `false` |  |
| focusExporter.serviceAccount.automountServiceAccountToken | bool | `false` |  |
| focusExporter.serviceAccount.enabled | bool | `true` |  |
| imagePullSecret.apiKey | string | `""` |  |
| month | string | `""` |  |
| provider | string | `"objectstore"` |  |
