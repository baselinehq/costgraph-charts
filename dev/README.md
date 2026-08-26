# Running costgraph-selfhosted locally

A throwaway kind cluster running the same chart a customer installs, with the
bundled Postgres, Redis and VictoriaMetrics so nothing external is needed.

## Once

Put a deployment API key in `dev/.key` (gitignored). Create it in the CostGraph
dashboard under Settings > API Keys; it authenticates the image registry too.

```sh
printf 'bl_...' > dev/.key
```

On an arm64 machine, build aggregator and ingestion-api first. Their published
images are linux/amd64 only, so their pods otherwise sit in ImagePullBackOff
with `no match for platform in manifest`:

```sh
./dev/build-local-images.sh          # needs the monorepo checked out alongside
```

`dev/kind-values.yaml` already points the two at the images that produces.
Delete that block on an amd64 machine to use the published ones.

## Every time

```sh
./dev/up.sh                          # creates the cluster if absent, installs, waits
```

It is an upgrade when the release exists, so it is also the way to re-apply a
template change. The dashboard is on <http://costgraph.localtest.me:8088>.

```sh
./dev/down.sh                        # delete the cluster
```

## Pinned image tags

`image.tag` and `dashboard.image.tag` in `dev/kind-values.yaml` are pinned to
specific `sha-` tags. Images are published per commit rather than per chart
version, so the chart requires an explicit tag. Find a current one with:

```sh
docker manifest inspect registry.costgraph.ai/backend:sha-$(git -C ../backend rev-parse --short=7 origin/main)
```

Only commits that finished a build have a tag, so walk back a few if that 404s.

## Recording rules

`charts/costgraph-selfhosted/recording-rules/` is a copy of the aggregator's
own `deploy/recording-rules`. Helm cannot reference files outside a chart, and
the two live in different repos, so the copy is the only option - but nothing
notices when the aggregator's change lands and this copy does not. A rule
rename upstream shows up as an empty dashboard here, with no error anywhere.

```sh
./dev/sync-recording-rules.sh -check    # fail on drift
./dev/sync-recording-rules.sh           # re-copy from the aggregator checkout
```

## Checking it works

```sh
kubectl get pods -n costgraph
kubectl exec -n costgraph deploy/costgraph-costgraph-selfhosted -- selfhost-doctor -offline
curl -s http://costgraph.localtest.me:8088/api/v1/config
```

`/api/v1/config` returning a `cognito` block means the deployment registered
with the control plane and its app client was provisioned. `config.json` from
the dashboard origin should carry the same `apiBaseUrl` the browser needs.

## The operator, against this deployment

The operator chart is per-cluster and installs separately. `dev/operator-kind-values.yaml`
points it at the in-cluster backend and ingestion-api rather than the hosted ones.

It needs a tenant API key from *this* deployment, with `operator:read` and
`operator:write`. Issue one from the dashboard once you have an account (see
below), write it to `dev/.operator-key` (gitignored), then:

```sh
helm dependency build charts/costgraph-operator
helm upgrade --install cg-operator charts/costgraph-operator -n costgraph \
  -f dev/operator-kind-values.yaml \
  --set-string global.apiKey="$(cat dev/.operator-key)"
```

Confirm metrics arrive:

```sh
kubectl run -n costgraph vmq --rm -i --restart=Never --image=curlimages/curl:8.11.1 -- \
  curl -s 'http://costgraph-costgraph-selfhosted-victoria-metrics:8428/api/v1/series/count'
```

## Signing in

A fresh deployment has no organization and no users, and JIT provisioning only
links a Cognito identity to an `organization_users` row that already exists.
Use "Create an account" on the sign-in page - that runs `POST /api/v1/signup/complete`,
which creates the organization, its default tenant and the owner. An email that
already has a CostGraph SaaS account is fine; the row is local to this database.
