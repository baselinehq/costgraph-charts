# costgraph-charts
Helm chart definitions to deploy costgraph to the clusters.

## Testing
Create a new values file that contains the configuration you'd like to deploy

```bash
helm template . -f <values-file> | tee | kubectl apply --dry-run=client -f -
```