# costgraph-selfhosted

![Version: 0.5.0](https://img.shields.io/badge/Version-0.5.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

CostGraph running in your own infrastructure. Your cost data, cloud
credentials and telemetry stay in your network — see "Network access it
needs" below for the traffic that does leave it.

## What you need first

From CostGraph, one thing: a deployment API key, which you create at
https://app.costgraph.ai/settings/account/api-keys. It is the only credential: the image
registry authenticates with the same key, and the chart wires that up for you.

From your side: a Postgres 14+, a Redis, and a VictoriaMetrics you run, plus
the URL your users will reach the dashboard on. To evaluate without setting
those up, the chart can run all three for you — see "Install" below.

Sign-in needs no configuration. Your users sign in with their CostGraph
accounts.

## Install

```sh
helm repo add costgraph https://charts.costgraph.ai
helm repo update

helm install costgraph costgraph/costgraph-selfhosted \
  --namespace costgraph --create-namespace \
  -f my-values.yaml
```

A minimal `my-values.yaml`:

```yaml
controlPlane:
  apiKey: bl_...

appBaseURL: https://costgraph.internal.example.com

postgres:
  url: postgres://costgraph@pg.internal:5432/costgraph?sslmode=require
  password: ...

redis:
  url: redis://redis.internal:6379

metricsStore:
  url: http://victoria-metrics.internal:8428

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: costgraph.internal.example.com
      paths: [{ path: /, pathType: Prefix }]
  tls:
    - secretName: costgraph-tls
      hosts: [costgraph.internal.example.com]
```

To try it out without standing up Postgres, Redis and VictoriaMetrics first,
replace those three blocks with `bundled.enabled: true` on each and the chart
runs them in-cluster. That is for evaluation only — single replica, no backups,
and the bundled Postgres image does not carry `pg_partman` or `pg_cron`, so
partition maintenance never runs. See "Database" below.

### Keeping credentials out of values

In production, put credentials in Secrets you manage and reference them with
`controlPlane.existingSecret` and `postgres.existingSecret`, so nothing
sensitive sits in your values file or in Helm release history. Each Secret
must use these key names:

| Setting | Secret keys |
|---|---|
| `controlPlane.existingSecret` | `control-plane-api-key` and `pricing-api-key` - copy the control-plane key into `pricing-api-key` unless you were issued a separate pricing key |
| `postgres.existingSecret` | `postgres-url`, `postgres-password` |
| `redis.existingSecret` | `redis-url` — use this if your Redis URL contains a password |

```sh
kubectl create secret generic costgraph-control-plane \
  --namespace costgraph \
  --from-literal=control-plane-api-key=bl_... \
  --from-literal=pricing-api-key=bl_...
```

A chart cannot read a Secret to build the image pull secret from it, so an
install using `controlPlane.existingSecret` creates that one too and names it
in `imagePullSecrets`:

```sh
kubectl create secret docker-registry costgraph-registry \
  --namespace costgraph \
  --docker-server=registry.costgraph.ai \
  --docker-username=x \
  --docker-password=bl_...
```

## Network access it needs

Outbound HTTPS (443) to these hosts:

| Host | Used for |
|---|---|
| `api.costgraph.ai` | licensing, the pricing catalog, billing quantities, outbound account email |
| `cognito-idp.us-east-2.amazonaws.com` | verifying sign-in tokens |
| `registry.costgraph.ai` | pulling the images |
| `pkg-containers.githubusercontent.com` | the image layers themselves, fetched directly |
| `us.i.posthog.com` | only if you set `analytics.enabled` |

Nothing needs to reach the deployment from outside your network.

## What it installs

| | |
|---|---|
| backend | the API and cost engine |
| dashboard | the web UI (`dashboard.enabled`, on by default) |
| ingestion-api | receives metrics from your clusters (`ingestionApi.enabled`, on by default) |
| aggregator | turns those metrics into per-workload costs (`aggregator.enabled`, on by default) |
| vmalert | evaluates the recording rules the cost maths reads, alongside the aggregator |
| Postgres, Redis, VictoriaMetrics | only when `*.bundled.enabled` is set |

The operator in each of your clusters sends metrics to ingestion-api, and the
aggregator turns them into the costs the dashboard shows. Turning either off
leaves the dashboard without cost data.

One ingress host serves both, so there is nothing to configure. Set
`dashboard.apiBaseURL` only if you put the API on a different host.

## Kubernetes Operator

The CostGraph operator installs separately in each cluster you want costgraph features for.

Its defaults point at hosted CostGraph, so a self-hosted install has to redirect
both endpoints at itself:

```sh
helm repo add costgraph https://charts.costgraph.ai

helm install costgraph-operator costgraph/costgraph-operator \
  --namespace costgraph --create-namespace \
  --set global.clusterName=<a name for this cluster> \
  --set global.apiKey=<your deployment API key> \
  --set global.backendURL=https://costgraph.internal.example.com/api/v1 \
  --set global.remoteWriteURL=https://costgraph.internal.example.com
```

| Operator setting | Points at | Default if left alone |
|---|---|---|
| `global.backendURL` | your install's API | hosted CostGraph |
| `global.remoteWriteURL` | your install's metrics endpoint | `tsdb.costgraph.ai` |

Leaving either at its default sends that cluster's metrics to hosted CostGraph
instead of to you, which is the one mistake worth checking for.

Ingestion is reached on the same host as the dashboard when one ingress fronts
both; `ingestionApi.enabled` must stay on for it to exist at all.

## Database

The chart does not run Postgres. A database holding your cost history should
outlive a Helm release, and you almost certainly want it backed up on your own
terms.

Required extensions: `citext`, `pg_trgm`. Strongly recommended: `pg_partman`
and `pg_cron` — without them performance degrades as your history grows.
Managed Postgres (RDS, Cloud SQL) often ships neither; the install still
works, and `selfhost-doctor` warns.

A preflight job runs before install and upgrade, failing the release with the
actual reason if the database cannot support the schema. Read that reason
with:

```sh
kubectl logs -n costgraph job/costgraph-costgraph-selfhosted-doctor
```

It does not run when `postgres.bundled.enabled` is set. Disable it with
`doctor.enabled=false` if your database is provisioned after the release.

## Operating

Resources are named `<release>-costgraph-selfhosted`, so the examples below
assume `helm install costgraph ...` as above. `helm status costgraph` prints
the commands with your own release name filled in.

Health, any time — reads the database, makes no outbound call:

```sh
kubectl exec -n costgraph deploy/costgraph-costgraph-selfhosted -- \
  selfhost-doctor -offline
```

If support asks for a bundle (version, schema state, health, redacted config —
no secrets, no cost data):

```sh
kubectl exec -n costgraph deploy/costgraph-costgraph-selfhosted -- \
  selfhost-doctor -bundle -offline
```

## Losing contact with CostGraph

Ingestion and everything you read locally keep working for a grace period.
Past it the deployment becomes read-only and the dashboard tells you so.

Signing in is the exception, and usually the first thing you notice: people
already signed in are unaffected, but new sign-ins need the connection.

## Upgrades

Upgrade in place. Pending database migrations are applied on start, unless
you set `postgres.runMigrations: false` to apply them yourself:

```sh
helm upgrade costgraph costgraph/costgraph-selfhosted \
  --namespace costgraph -f my-values.yaml
```

Back the database up first. Migrations are not reversible, so rolling the
release back does not roll the schema back.

### One thing you must not delete

On first install the chart generates encryption keys and stores them in a
Secret named `<release>-costgraph-selfhosted-generated`. Everything you have
already saved is tied to them.

Helm keeps this Secret across upgrades and uninstalls, so you do not need to
do anything with it. But it cannot be regenerated. If it is deleted, every
API key your team issued stops working and every connected cloud account has
to be reconnected — the stored credentials can no longer be read.

Back it up alongside the database, and keep the two together. A database
restored next to a different Secret is a database whose credentials cannot be
decrypted:

```sh
kubectl get secret costgraph-costgraph-selfhosted-generated \
  -n costgraph -o yaml > costgraph-keys-backup.yaml
```

## Every setting

`values.yaml` documents each setting inline, next to the value it controls:

```sh
helm show values costgraph/costgraph-selfhosted
```
