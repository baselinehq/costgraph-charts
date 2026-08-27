{{/*
A geesefs-backed StorageClass over an S3 bucket. Every consumer differs only in
the class name and the bucket it points at.

Required: name, bucket.
*/}}
{{- define "costgraph.storageClass" -}}
{{- $name := required "storageClass: name is required" .name -}}
{{- $secretNamespace := .secretNamespace | default "kube-system" -}}
{{- $secretName := .secretName | default "csi-s3-secret" -}}
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: {{ $name }}
provisioner: {{ .provisioner | default "ru.yandex.s3.csi" }}
parameters:
  csi.storage.k8s.io/controller-publish-secret-name: {{ $secretName }}
  csi.storage.k8s.io/controller-publish-secret-namespace: {{ $secretNamespace }}
  csi.storage.k8s.io/node-publish-secret-name: {{ $secretName }}
  csi.storage.k8s.io/node-publish-secret-namespace: {{ $secretNamespace }}
  csi.storage.k8s.io/node-stage-secret-name: {{ $secretName }}
  csi.storage.k8s.io/node-stage-secret-namespace: {{ $secretNamespace }}
  csi.storage.k8s.io/provisioner-secret-name: {{ $secretName }}
  csi.storage.k8s.io/provisioner-secret-namespace: {{ $secretNamespace }}
  mounter: {{ .mounter | default "geesefs" }}
  options: {{ .options | default "--memory-limit 1000 --dir-mode 0777 --file-mode 0666" | quote }}
  bucket: {{ required "storageClass: bucket is required" .bucket }}
{{- end -}}
