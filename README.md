# costgraph-charts
Helm chart definitions to deploy costgraph to the clusters.

| Chart | Status | Deploys |
|-------|--------|---------|
| [`costgraph-operator`](./charts/costgraph-operator) | Active | `costgraph-operator-kubernetes`, `costgraph-operator-prometheus` and their exporters |
| [`costgraph`](./charts/costgraph) | **Deprecated** | Single-binary `costgraph-operator`, replaced by the chart above |

The single-binary operator has been broken out into domain-specific operators,
each versioned and released independently. New installations must use the
`costgraph-operator` chart. See [RELEASING.md](./RELEASING.md).

## Migrating off the `costgraph` chart

Existing `costgraph` installations keep running and keep reporting. They will
not receive new features or fixes.

The two charts do not share a values schema, so migration is a reinstall rather
than a `helm upgrade`:

```bash
helm uninstall costgraph -n <namespace>
helm install costgraph-operator costgraph/costgraph-operator \
  --namespace costgraph --create-namespace \
  --set global.clusterName=<your-cluster-name> \
  --set global.apiKey=<your-api-key>
```

Configuration equivalents are documented in the
[operator configuration reference](https://docs.costgraph.ai/costgraph/operator/configuration).


# Generating diagrams
```bash
pip install KubeDiagrams
helm-diagrams ./charts/costgraph-operator
mv costgraph-operator.png ./images/diagram.png
```
This will generate a diagram of the costgraph operator and its dependencies. The diagram will be saved in the `images` directory as `diagram.png`.

## Testing
Create a new values file that contains the configuration you'd like to deploy

```bash
cd charts/<chart-name>
helm template . -f <your-values-file> | tee | kubectl apply --dry-run=client -f -
``