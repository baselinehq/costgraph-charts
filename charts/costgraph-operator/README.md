# costgraph-operator

![Version: 0.7.0](https://img.shields.io/badge/Version-0.7.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.4.0](https://img.shields.io/badge/AppVersion-0.4.0-informational?style=flat-square)
A Helm chart for the Costgraph operator

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../costgraph-common | costgraph-common | * |
| https://charts.bitnami.com/bitnami | cadvisor | 0.1.* |
| https://nvidia.github.io/dcgm-exporter/helm-charts | dcgm-exporter | 3.* |
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 5.27.* |
| https://prometheus-community.github.io/helm-charts | prometheus-node-exporter | 4.* |
| https://stakater.github.io/stakater-charts | operatorKubernetes(application) | 9.3.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aiGatewayScraper | object | `{"applicationName":"costgraph-operator-ai-gateway","config":{"httpTimeout":"30s","remoteWritePath":"/api/v1/write/short","remoteWriteURL":""},"deployment":{"enabled":true,"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/baselinehq/costgraph-operator-prometheus","tag":"v0.4.1"},"replicas":1,"resources":{"requests":{"cpu":"100m","memory":"64Mi"}}},"enabled":false}` | ------------------------------------------------------------------------ |
| cadvisor | object | `{"enabled":true,"image":{"registry":"ghcr.io","repository":"baselinehq/cadvisor","tag":"0.56.3-baseline"},"resources":{"requests":{"cpu":"100m","memory":"100Mi"}},"tolerations":[{"operator":"Exists"}]}` | ------------------------------------------------------------------------ |
| dcgm-exporter | object | `{"enabled":false,"nodeSelector":{"accelerator":"nvidia"},"podAnnotations":{},"podLabels":{},"resources":{"requests":{"cpu":"100m","memory":"100Mi"}},"serviceMonitor":{"enabled":false},"tolerations":[]}` | ------------------------------------------------------------------------ |
| flowtrace | object | `{"applicationName":"costgraph-operator-flowtrace","config":{"httpTimeout":"30s","includeHostFlows":false,"pushInterval":"4m","remoteWritePath":"/api/v1/write/short","remoteWriteURL":""},"daemonSet":{"automountServiceAccountToken":false,"containerSecurityContext":{"privileged":true,"runAsUser":0},"enabled":true,"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/baselinehq/costgraph-operator-prometheus","tag":"v0.4.1"},"priorityClassName":"","resources":{"limits":{"memory":"256Mi"},"requests":{"cpu":"50m","memory":"64Mi"}},"tolerations":[{"operator":"Exists"}]},"enabled":true,"maxUnavailable":1}` | ------------------------------------------------------------------------ |
| fullnameOverride | string | `""` |  |
| global.apiKey | string | `""` |  |
| global.backendURL | string | `"https://api.costgraph.ai"` |  |
| global.clusterName | string | `""` |  |
| global.existingSecret | string | `""` |  |
| global.existingSecretKey | string | `""` |  |
| global.remoteWriteURL | string | `""` |  |
| global.security.allowInsecureImages | bool | `true` |  |
| imagePullSecrets | list | `[]` |  |
| kube-state-metrics | object | `{"collectors":["cronjobs","daemonsets","deployments","endpoints","horizontalpodautoscalers","ingresses","jobs","limitranges","namespaces","networkpolicies","nodes","persistentvolumeclaims","persistentvolumes","poddisruptionbudgets","pods","replicasets","replicationcontrollers","resourcequotas","services","statefulsets","storageclasses","volumeattachments"],"enabled":true}` | ------------------------------------------------------------------------ |
| nameOverride | string | `""` |  |
| operatorKubernetes | object | `{"applicationName":"costgraph-operator-kubernetes","deployment":{"automountServiceAccountToken":true,"containerSecurityContext":null,"enabled":true,"env":{"API_KEY":{"valueFrom":{"secretKeyRef":{"key":"{{ include \"costgraph-operator.apiKeySecretKey\" . }}","name":"{{ include \"costgraph-operator.apiKeySecretName\" . }}"}}},"BACKEND_URL":{"value":"{{ .Values.global.backendURL }}"},"CLUSTER_NAME":{"value":"{{ required \"Cluster name must be provided\" .Values.global.clusterName }}"},"OPERATOR_VERSION":{"value":"{{ .Values.deployment.image.tag }}"}},"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/baselinehq/costgraph-operator-kubernetes","tag":"v0.1.1"},"imagePullSecrets":[],"ports":[{"containerPort":6060,"name":"pprof","protocol":"TCP"}],"replicas":1,"resources":{"requests":{"cpu":"10m","memory":"64Mi"}}},"enabled":true,"rbac":{"enabled":false,"serviceAccount":{"create":false,"name":"costgraph-operator"}},"service":{"enabled":false}}` | ------------------------------------------------------------------------ |
| operatorPrometheus | object | `{"applicationName":"costgraph-operator-prometheus","config":{"httpTimeout":"30s","prometheusAPIProvider":"prometheus","prometheusAPIVersion":"kube-state-metrics","remoteWritePath":"/api/v1/write","remoteWriteURL":""},"deployment":{"enabled":true,"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/baselinehq/costgraph-operator-prometheus","tag":"v0.4.1"},"ports":[{"containerPort":6060,"name":"pprof","protocol":"TCP"}],"replicas":1,"resources":{"requests":{"cpu":"100m","memory":"64Mi"}}},"enabled":true,"scrapeTargets":{"cadvisor":{"enabled":true,"labelSelector":"app.kubernetes.io/name=cadvisor","namespace":"{{ include \"costgraph-operator.namespace\" . }}","nodeMetrics":true,"port":8080},"dcgm-exporter":{"enabled":false,"labelSelector":"app.kubernetes.io/name=dcgm-exporter","namespace":"{{ include \"costgraph-operator.namespace\" . }}","nodeMetrics":true,"port":9400},"kube-state-metrics":{"enabled":true,"labelSelector":"app.kubernetes.io/name=kube-state-metrics","namespace":"{{ include \"costgraph-operator.namespace\" . }}","port":8080},"kubelet":{"enabled":true,"kind":"node","metricNamePrefixes":["kubelet_"],"nodeMetrics":true,"path":"/metrics"},"node-exporter":{"enabled":true,"labelSelector":"app.kubernetes.io/name=prometheus-node-exporter","namespace":"{{ include \"costgraph-operator.namespace\" . }}","nodeMetrics":true,"port":"{{ index .Values \"prometheus-node-exporter\" \"service\" \"port\" }}"}}}` | ------------------------------------------------------------------------ |
| operatorPrometheus.scrapeTargets | object | `{"cadvisor":{"enabled":true,"labelSelector":"app.kubernetes.io/name=cadvisor","namespace":"{{ include \"costgraph-operator.namespace\" . }}","nodeMetrics":true,"port":8080},"dcgm-exporter":{"enabled":false,"labelSelector":"app.kubernetes.io/name=dcgm-exporter","namespace":"{{ include \"costgraph-operator.namespace\" . }}","nodeMetrics":true,"port":9400},"kube-state-metrics":{"enabled":true,"labelSelector":"app.kubernetes.io/name=kube-state-metrics","namespace":"{{ include \"costgraph-operator.namespace\" . }}","port":8080},"kubelet":{"enabled":true,"kind":"node","metricNamePrefixes":["kubelet_"],"nodeMetrics":true,"path":"/metrics"},"node-exporter":{"enabled":true,"labelSelector":"app.kubernetes.io/name=prometheus-node-exporter","namespace":"{{ include \"costgraph-operator.namespace\" . }}","nodeMetrics":true,"port":"{{ index .Values \"prometheus-node-exporter\" \"service\" \"port\" }}"}}` | ---------------------------------------------------------------------- |
| prometheus-node-exporter | object | `{"enabled":true,"podAnnotations":{},"podLabels":{},"resources":{"requests":{"cpu":"100m","memory":"100Mi"}},"service":{"port":9101,"targetPort":9101},"tolerations":[{"operator":"Exists"}]}` | ------------------------------------------------------------------------ |
| rbac | object | `{"builtinAPIGroups":["apps","autoscaling","batch","discovery.k8s.io","networking.k8s.io","policy","storage.k8s.io"],"excludeAPIGroups":["acme.cert-manager.io","authentication.k8s.io","authorization.k8s.io","cert-manager.io","certificates.k8s.io","external-secrets.io","generators.external-secrets.io","helm.toolkit.fluxcd.io","notification.toolkit.fluxcd.io","rbac.authorization.k8s.io","traefik.io","velero.io","admissionregistration.k8s.io","apiextensions.k8s.io","apiregistration.k8s.io","coordination.k8s.io","events.k8s.io","flowcontrol.apiserver.k8s.io","internal.apiserver.k8s.io","longhorn.io","metrics.k8s.io","node.k8s.io","scheduling.k8s.io","storagemigration.k8s.io"],"extraRules":[],"grantCustomResources":true,"requireClusterDiscovery":true}` | ------------------------------------------------------------------------ || serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `"costgraph-operator"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
