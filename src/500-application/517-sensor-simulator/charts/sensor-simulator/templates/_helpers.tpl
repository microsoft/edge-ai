{{- define "sensor-simulator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "sensor-simulator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "sensor-simulator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "sensor-simulator.labels" -}}
helm.sh/chart: {{ include "sensor-simulator.chart" . }}
{{ include "sensor-simulator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "sensor-simulator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sensor-simulator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "sensor-simulator.namespace" -}}
{{- default "azure-iot-operations" .Values.namespace }}
{{- end }}

{{- define "sensor-simulator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sensor-simulator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- required "serviceAccount.name is required when serviceAccount.create is false" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "sensor-simulator.image" -}}
{{- $repository := required "image.repository is required" .Values.image.repository }}
{{- printf "%s:%s" $repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end }}
