# costgraph

![Version: 0.1.20](https://img.shields.io/badge/Version-0.1.20-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.2](https://img.shields.io/badge/AppVersion-0.1.2-informational?style=flat-square)

Distributed observability for modern workloads on Kubernetes

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"kubernetes.io/os"` |  |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"In"` |  |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0] | string | `"linux"` |  |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/arch"` |  |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"In"` |  |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"arm64"` |  |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[1] | string | `"amd64"` |  |
| arch | string | `"amd64"` |  |
| costgraph.chat.image | string | `"ghcr.io/baselinehq/costgraph-chat"` |  |
| costgraph.chat.ingress.annotations | object | `{}` |  |
| costgraph.chat.ingress.tls.enabled | bool | `false` |  |
| costgraph.chat.ingress.tls.secret_name | string | `""` |  |
| costgraph.chat.port | int | `8000` |  |
| costgraph.chat.resources.limits.cpu | string | `"2"` |  |
| costgraph.chat.resources.limits.memory | string | `"2Gi"` |  |
| costgraph.chat.resources.requests.cpu | string | `"250m"` |  |
| costgraph.chat.resources.requests.memory | string | `"100Mi"` |  |
| costgraph.chat.tag | string | `"latest"` |  |
| costgraph.config.api_key | string | `""` |  |
| costgraph.config.costgraph_feature_flags.chat | bool | `false` |  |
| costgraph.config.costgraph_feature_flags.graph | bool | `true` |  |
| costgraph.config.costgraph_feature_flags.prometheus | bool | `true` |  |
| costgraph.config.costgraph_feature_flags.superset | bool | `true` |  |
| costgraph.config.costgraph_instance_master_domains | list | `[]` |  |
| costgraph.config.costgraph_instance_name | string | `""` |  |
| costgraph.config.costgraph_instance_replication_provider | string | `"s3"` |  |
| costgraph.config.expected_utilisation_percent.cpu | int | `80` |  |
| costgraph.config.expected_utilisation_percent.memory | int | `80` |  |
| costgraph.config.fortknox_server_url | string | `"https://fortknox.baselinehq.cloud"` |  |
| costgraph.config.openai_api_key | string | `""` |  |
| costgraph.config.prometheus_endpoint | string | `"http://prometheus-server.prometheus-system"` |  |
| costgraph.config.prometheus_metrics_port | int | `9090` |  |
| costgraph.config.superset_address | string | `"http://superset"` |  |
| costgraph.config.worker_count | int | `10` |  |
| costgraph.operator.env | list | `[]` |  |
| costgraph.operator.image | string | `"ghcr.io/baselinehq/costgraph-operator"` |  |
| costgraph.operator.port | int | `8090` |  |
| costgraph.operator.resources.limits.cpu | string | `"1"` |  |
| costgraph.operator.resources.limits.memory | string | `"512Mi"` |  |
| costgraph.operator.resources.requests.cpu | string | `"250m"` |  |
| costgraph.operator.resources.requests.memory | string | `"100Mi"` |  |
| costgraph.operator.tag | string | `"v0.1.2"` |  |
| domain | string | `"costgraph.internal"` |  |
| os | string | `"linux"` |  |
| postgres.config.pg_data_directory | string | `"/var/lib/postgresql/data"` |  |
| postgres.config.postgres_db | string | `"costgraph"` |  |
| postgres.config.postgres_host | string | `"db"` |  |
| postgres.config.postgres_password | string | `"password"` |  |
| postgres.config.postgres_port | int | `5432` |  |
| postgres.config.postgres_user | string | `"user"` |  |
| postgres.enabled | bool | `true` |  |
| postgres.image | string | `"postgres"` |  |
| postgres.pvc.enabled | bool | `false` |  |
| postgres.pvc.size | string | `"10Gi"` |  |
| postgres.resources.limits.cpu | string | `"2"` |  |
| postgres.resources.limits.memory | string | `"1Gi"` |  |
| postgres.resources.requests.cpu | string | `"250m"` |  |
| postgres.resources.requests.memory | string | `"100Mi"` |  |
| postgres.tag | string | `"14-alpine"` |  |
| superset.config.server_worker_amount | string | `"3"` |  |
| superset.config.superset_admin_email | string | `"admin@costgraph-superset.com"` |  |
| superset.config.superset_admin_password | string | `"admin"` |  |
| superset.config.superset_admin_username | string | `"admin"` |  |
| superset.config.superset_dashboard_zip | string | `"/app/dashboard.zip"` |  |
| superset.config.superset_guest_email | string | `"guest@public.internal"` |  |
| superset.config.superset_guest_password | string | `"public"` |  |
| superset.config.superset_guest_role | string | `"Public"` |  |
| superset.config.superset_guest_username | string | `"guest"` |  |
| superset.config.superset_secret_key | string | `"test123"` |  |
| superset.enabled | bool | `true` |  |
| superset.image | string | `"ghcr.io/baselinehq/costgraph-superset"` |  |
| superset.ingress.annotations | object | `{}` |  |
| superset.ingress.tls.enabled | bool | `false` |  |
| superset.ingress.tls.secret_name | string | `""` |  |
| superset.port | int | `8088` |  |
| superset.resources.limits.cpu | string | `"2"` |  |
| superset.resources.limits.memory | string | `"1Gi"` |  |
| superset.resources.requests.cpu | string | `"1"` |  |
| superset.resources.requests.memory | string | `"500Mi"` |  |
| superset.tag | string | `"v0.1.0"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
