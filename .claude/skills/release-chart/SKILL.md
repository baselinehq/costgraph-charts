---
name: release-chart
description: Use when cutting a release of a CostGraph service and shipping it to customers - releasing a binary (backend, dashboard, ingestion-api, aggregator, operator, focus-exporter), bumping a chart image pin, or publishing a chart version. Covers the dispatch-only release-please flow, the tag footguns that produce broken images, and the customer changelog in mintlify-docs.
---

# Releasing a CostGraph service and chart

A customer upgrades a **chart version**, not an image tag. A release is therefore
two halves: cut a versioned image, then pin and publish the chart that ships it.

`RELEASING.md` in this repo is the reference for the operator and focus-exporter
charts. This skill is the operational sequence, including the failure modes that
have actually bitten.

## 1. Cut the binary release

Release-please is wired **dispatch-only** (`workflow_dispatch`) in every
first-party repo, authenticated with `GO_GET_TOKEN` (web-v2 uses
`RELEASE_TOKEN`). Merging to main does NOT open or land a release on its own.

```bash
gh workflow run release-please.yml --repo baselinehq/<repo> --ref main
```

1. Dispatch. This raises or refreshes `chore(main): release X.Y.Z`.
2. Review the changelog wording in that PR. Generated entries are engineering
   history; edit them if they are not customer-legible.
3. Merge the release PR.
4. **Dispatch again.** Nothing runs on the merge alone, and without this second
   dispatch no tag is cut and no image is ever built.
5. The tag push fires the Docker workflow.

Verify the tag landed on the release-PR merge commit, not a `Deploy ...` commit:

```bash
gh api repos/baselinehq/<repo>/git/refs/tags/vX.Y.Z --jq '.object.sha'
gh api repos/baselinehq/<repo>/commits/<sha> --jq '.commit.message'
```

## 2. Confirm the image exists

Never pin a tag you have not seen in the registry. A chart pinned to a
non-existent tag is an ImagePullBackOff on every upgrade, and the old pod keeps
serving so it can go unnoticed.

## 3. Pin and publish the chart

1. Set the image tag in the chart's `values.yaml`. Use `vX.Y.Z`; never ship a
   `sha-` pin in a released chart.
2. Bump `version` in `Chart.yaml`. Bump `appVersion` when the binary moved.
3. Open a PR. On merge, chart-releaser packages it, publishes to
   https://charts.costgraph.ai and updates `index.yaml`.
4. Confirm the new version appears in the published `index.yaml`.

## 4. Update the customer changelog

Per-repo `CHANGELOG.md` files are engineering history. The customer-facing
changelog lives in `mintlify-docs` and is keyed to **chart** versions:

| Chart | Changelog |
| --- | --- |
| `costgraph-selfhosted` | `costgraph/self-hosted/changelog.mdx` |
| `costgraph-operator` | `costgraph/operator/changelog.mdx` |
| agent | `costgraph/agent/changelog.mdx` |

```mdx
<Update label="YYYY-MM-DD" description="costgraph-selfhosted vX.Y.Z">
    ### Added
    - ...
</Update>
```

Per the published SLA: changelogs for major and minor releases, and any breaking
change is called out in the cycle it lands in. Write what the customer can now
do or must now change - not the internal mechanism.

## Footguns paid for

- **`bootstrap-sha` past the last conventional commit** makes a dispatch exit
  silently with "No user facing commits found". `release-as` does NOT bypass it.
- **A tag on a commit whose workflow YAML is invalid** fails with ZERO jobs, at
  parse level. Re-releasing through a fresh release PR is the fix; re-pushing the
  tag is not.
- **Two deploy dispatches on the same repo run back to back**: the second tags
  the first's `Deploy ...` commit, which has no image because docker-publish
  ignores `deploy/**`. Re-running cannot fix it - correct `deploy/values.yaml` on
  main by hand to the real merge-commit sha.
- **No conventional commits since the last tag** means no release is possible.
  `docs:`, `ci:`, `chore:`, `test:` and `build:` do not produce one on their own.
- Repos squash-merge, so the **PR title becomes the commit subject** and is what
  drives the version. A `PR Title` check enforces the format.

## Checklist

- [ ] Release PR merged in each repo that changed
- [ ] Second dispatch run, `vX.Y.Z` tag cut on the release-PR merge commit
- [ ] Image visible in the registry
- [ ] `values.yaml` pinned to `vX.Y.Z`, no `sha-` pins
- [ ] `Chart.yaml` `version` bumped, `appVersion` if the binary moved
- [ ] Chart PR merged, new version present in `index.yaml`
- [ ] `<Update>` block added to the right `mintlify-docs` changelog
- [ ] Breaking changes communicated to affected customers
