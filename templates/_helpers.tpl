{{- define "netclab.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "netclab.podAffinity" -}}
podAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: app.kubernetes.io/name
        operator: In
        values:
        - {{ .Chart.Name }}
      - key: app.kubernetes.io/instance
        operator: In
        values:
        - {{ .Release.Name }}
    topologyKey: kubernetes.io/hostname
{{- end }}
