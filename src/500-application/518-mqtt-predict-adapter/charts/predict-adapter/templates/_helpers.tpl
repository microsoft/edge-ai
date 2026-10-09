{{- define "predict-adapter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "predict-adapter.fullname" -}}
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

{{- define "predict-adapter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "predict-adapter.labels" -}}
helm.sh/chart: {{ include "predict-adapter.chart" . }}
{{ include "predict-adapter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "predict-adapter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "predict-adapter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "predict-adapter.namespace" -}}
{{- default "azure-iot-operations" .Values.namespace }}
{{- end }}

{{- define "predict-adapter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "predict-adapter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- required "serviceAccount.name is required when serviceAccount.create is false" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "predict-adapter.image" -}}
{{- $repository := required "image.repository is required" .Values.image.repository }}
{{- printf "%s:%s" $repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end }}
