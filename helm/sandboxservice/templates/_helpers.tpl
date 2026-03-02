{{/*
Nombre base del chart (puede ser sobreescrito con nameOverride).
*/}}
{{- define "sandboxservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Nombre completo del release (estable y único).
Por defecto: <releaseName>-<chartName> salvo que fullnameOverride esté definido.
*/}}
{{- define "sandboxservice.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "sandboxservice.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Labels mínimos para organización.
*/}}
{{- define "sandboxservice.labels" -}}
app.kubernetes.io/name: {{ include "sandboxservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Labels de selección: deben ser idénticos en:
- Deployment.spec.selector.matchLabels
- Deployment.spec.template.metadata.labels
- Service.spec.selector
*/}}
{{- define "sandboxservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sandboxservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}