# costgraph-common

Library chart holding the objects `stakater/application` cannot render. It is a
supplement to that chart, not a replacement, and it is deliberately kept small.

## What belongs here

`application` 9.3.1 renders Deployment, Job, CronJob, Service, Ingress,
ConfigMap, Secret, ServiceAccount, PVC, ServiceMonitor, HPA, PDB, NetworkPolicy,
VPA, Role, RoleBinding, ClusterRole, ClusterRoleBinding, ExternalSecret,
Certificate and HTTPRoute. It also supports sidecars, through
`deployment.additionalContainers`.

Add a define here only when `application` cannot express the object at all, or
cannot express it the way a CostGraph chart needs:

| Define | Why `application` cannot do it |
|---|---|
| `costgraph.workload` | No StatefulSet and no DaemonSet template exists |
| `costgraph.service` | Object names come from `applicationName`, a plain value that cannot contain `.Release.Name` |
| `costgraph.configMap` | Names are forced to `<appName>-<suffix>`; an unsuffixed name is impossible |
| `costgraph.secret` | Cannot set `type:`, and data values are not `tpl`-rendered, so `lookup` preservation cannot be smuggled in |
| `costgraph.dockerConfigJsonSecret` | Same `type:` limitation |
| `costgraph.ingress` | Backends address ports by name only, never by number |
| `costgraph.job` | Always emits `serviceAccountName`, which a pre-upgrade hook cannot reference |
| `costgraph.serviceAccount` | Name is not templated |
| `costgraph.externalSecret` | Chart-specific shape |
| `costgraph.vmalert` | Composite: Service plus two Deployments plus a rules init container |
| `costgraph.selectorLabels` | Selector labels are hardcoded and not overridable |

Anything outside that table is a duplicate. Use the `application` alias instead.

## Conventions

Every define takes one dict containing `ctx` and derives no names internally.
`env`, `volumes` and `volumeMounts` are in raw Kubernetes list form, so a caller
can build them with `append`.

Defines are added when a chart calls them, not ahead of one. A define with no
caller is deleted rather than carried, since git holds it until the change that
needs it lands.

`costgraph.workload` renders exactly one main container. Sidecars are out of
scope: for a Deployment use `application`'s `additionalContainers`, and extend
this define only when a StatefulSet or DaemonSet genuinely needs a second
container.

`lookup` returns empty under `helm template`, so the `preserve` map in
`costgraph.secret` regenerates its values on every Argo CD sync. Only use it for
credentials a chart can afford to rotate, or set `resourcePolicyKeep`.
