# focus-exporter

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.1](https://img.shields.io/badge/AppVersion-0.1.1-informational?style=flat-square)

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
| `<release>-focus-exporter-costgraph` | `COSTGRAPH_API_KEY`, `COSTGRAPH_CONNECTION_ID` | `costgraph.apiKey`, `costgraph.connectionId` |
| `<release>-focus-exporter-credentials` | whatever variables your provider reads | `credentials` |
| `<release>-focus-exporter-registry` | a `kubernetes.io/dockerconfigjson` for `registry.costgraph.ai` | `imagePullSecret.apiKey` |

Point the chart at yours with `costgraph.existingSecret`,
`credentialsExistingSecret`, and `imagePullSecret.existingSecret`. The CostGraph
URL is not a credential - it rides in the config file, so a custom
`costgraph.url` is honoured even when the credentials come from your own Secret.

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
| https://charts.costgraph.ai | costgraph-common | 0.2.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| backoffLimit | int | `3` |  |
| concurrencyPolicy | string | `"Forbid"` |  |
| config.OBJECTSTORE_LAYOUT | string | `"manifest"` |  |
| containerSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| costgraph.apiKey | string | `""` |  |
| costgraph.connectionId | string | `""` |  |
| costgraph.existingSecret | string | `""` |  |
| costgraph.url | string | `"https://api.costgraph.ai"` |  |
| credentials | object | `{}` |  |
| credentialsExistingSecret | string | `""` |  |
| failedJobsHistoryLimit | int | `3` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"registry.costgraph.ai/baselinehq/focus-exporter"` |  |
| image.tag | string | `""` |  |
| imagePullSecret.apiKey | string | `""` |  |
| imagePullSecret.existingSecret | string | `""` |  |
| month | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext.runAsGroup | int | `65532` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| podSecurityContext.runAsUser | int | `65532` |  |
| podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| provider | string | `"objectstore"` |  |
| resources.limits.memory | string | `"1Gi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"256Mi"` |  |
| restartPolicy | string | `"OnFailure"` |  |
| schedule | string | `"0 6 * * *"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| successfulJobsHistoryLimit | int | `3` |  |
| tolerations | list | `[]` |  |
