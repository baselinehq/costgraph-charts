# costgraph-charts
Helm chart definitions to deploy costgraph to the clusters.

| Chart | Status | Deploys |
|-------|--------|---------|
| [`costgraph-operator`](./charts/costgraph-operator) | Active | `costgraph-operator-kubernetes`, `costgraph-operator-prometheus` and their exporters |
| [`costgraph-selfhosted`](./charts/costgraph-selfhosted) | Active | CostGraph itself, in a customer's own infrastructure |
| [`costgraph`](./charts/costgraph) | **Deprecated** | Single-binary `costgraph-operator`, no longer supported |

The single-binary operator has been broken out into domain-specific operators,
each versioned and released independently. Use the `costgraph-operator` chart.
See [RELEASING.md](./RELEASING.md).

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