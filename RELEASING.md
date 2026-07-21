# Releasing

This document covers releasing the CostGraph operator: the two operator
binaries and the Helm chart that ships them.

## Components

| Component | Repository | Artifact |
| --- | --- | --- |
| Kubernetes operator | `baselinehq/costgraph-operator-kubernetes` | `ghcr.io/baselinehq/costgraph-operator-kubernetes:vX.Y.Z` |
| Prometheus operator | `baselinehq/costgraph-operator-prometheus` | `ghcr.io/baselinehq/costgraph-operator-prometheus:vX.Y.Z` |
| Helm chart | `baselinehq/costgraph-charts` | `charts/costgraph-operator` published to https://charts.costgraph.ai |

The two binaries version independently. The chart is the customer-facing
release unit: a customer upgrades a chart version, not an image tag.

## Versioning

Both binaries follow Semantic Versioning and are released from
Conventional Commit history:

- `fix:` -> patch
- `feat:` -> minor
- `feat!:` / `BREAKING CHANGE:` footer -> minor while pre-1.0, major after
- `docs:`, `ci:`, `chore:`, `test:`, `build:` -> no release on their own

Both repositories squash-merge, so the **PR title becomes the commit
subject** and is what drives the release. A `PR Title` check enforces the
Conventional Commit format on every pull request.

## Binary release flow (automated)

1. Merge a PR into `main`. The `Release Please` workflow opens (or updates)
   a release PR titled `chore(main): release X.Y.Z`, containing the version
   bump and the generated `CHANGELOG.md` section.
2. Review the release PR. Edit the changelog wording in that PR if the
   generated entries are not customer-legible.
3. Merge the release PR. Release Please creates the `vX.Y.Z` git tag and a
   GitHub Release.
4. The `Docker` workflow triggers on the tag and publishes
   `vX.Y.Z`, `vX.Y` and `vX` image tags to GHCR.

Nothing is tagged or published by hand. To hold a release, leave the
release PR unmerged.

## Chart release flow

1. Confirm both image tags exist in GHCR.
2. In `charts/costgraph-operator/values.yaml`, set
   `kubernetes.image.tag` and `prometheus.image.tag` to the new `vX.Y.Z`
   values. Never pin `sha-` tags in a released chart.
3. Bump `version` in `charts/costgraph-operator/Chart.yaml`. Bump
   `appVersion` when the operator binaries move.
4. Open a PR. On merge to `main`, `chart-releaser` packages the chart,
   publishes it to the chart repository and updates `index.yaml`.
5. Verify the new version appears in
   https://charts.costgraph.ai/index.yaml.

## Customer changelog

Per-repo `CHANGELOG.md` files are engineering history. The customer-facing
changelog lives in `mintlify-docs` at `costgraph/operator/changelog.mdx`
and is keyed to **chart** versions, not binary versions.

Add an `<Update>` block for every chart release that carries a user-visible
change:

```mdx
<Update label="YYYY-MM-DD" description="vX.Y.Z">
    ### Breaking Changes
    - N/A

    ### Updates
    - ...
</Update>
```

Per the published SLA: changelogs are provided for major and minor
releases, and any breaking change is called out in the release cycle it
lands in.

## Release checklist

- [ ] Release PR merged in each operator repo that changed
- [ ] `vX.Y.Z` image tags visible in GHCR for both binaries
- [ ] `values.yaml` image tags updated, no `sha-` pins
- [ ] `Chart.yaml` `version` bumped (and `appVersion` if binaries moved)
- [ ] Chart PR merged and new version present in `index.yaml`
- [ ] `<Update>` block added to `costgraph/operator/changelog.mdx`
- [ ] Breaking changes communicated to affected customers
