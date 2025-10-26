{{- define "netclab.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
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

{{- define "netclab.networkTypeMap" -}}
  {{- $networkDefaultType := "veth" -}}
  {{- $networkTypeMap := dict -}}
  {{- range .Values.topology.networks -}}
    {{- $networkTypeMap = merge $networkTypeMap (dict .name (default $networkDefaultType .type)) -}}
  {{- end -}}
  {{ toYaml $networkTypeMap }}
{{- end -}}

{{- /*
Return the joined networks string for a given node and the networkTypeMap
Expected inputs:
- .node: the node object (with interfaces and name)
- .networkTypeMap: map of network name -> network type
*/ -}}
{{- define "netclab.nodeNetworks" -}}
  {{- $node := .node -}}
  {{- $networkTypeMap := .networkTypeMap -}}
  {{- $nets := list -}}
  {{- range $iface := $node.interfaces -}}
    {{- if eq (index $networkTypeMap $iface.network) "veth" }}
      {{- $nets = append $nets (printf "%s-%s@%s" $iface.network $node.name $iface.name) }}
    {{- else }}
      {{- $nets = append $nets (printf "%s@%s" $iface.network $iface.name) }}
    {{- end }}
  {{- end }}
  {{- join "," $nets }}
{{- end }}

{{- define "netclab.hasVeth" -}}
  {{- $networkTypeMap := include "netclab.networkTypeMap" . | fromYaml -}}
  {{- $hasVeth := false -}}
  {{- range $name, $type := $networkTypeMap -}}
    {{- if eq $type "veth" -}}
      {{- $hasVeth = true -}}
    {{- end -}}
  {{- end -}}
  {{- if $hasVeth }}true{{ else }}false{{ end }}
{{- end -}}
