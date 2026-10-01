{{- define "ai-edge-inference.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "ai-edge-inference.fullname" -}}
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

{{- define "ai-edge-inference.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "ai-edge-inference.labels" -}}
helm.sh/chart: {{ include "ai-edge-inference.chart" . }}
{{ include "ai-edge-inference.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "ai-edge-inference.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ai-edge-inference.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "ai-edge-inference.namespace" -}}
{{- default "azure-iot-operations" .Values.namespace }}
{{- end }}

{{- define "ai-edge-inference.image" -}}
{{- $repository := required "image.repository is required" .Values.image.repository }}
{{- printf "%s:%s" $repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{- define "ai-edge-inference.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ai-edge-inference.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- required "serviceAccount.name is required when serviceAccount.create is false" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "ai-edge-inference.modelClaimName" -}}
{{- if .Values.models.existingClaim }}
{{- .Values.models.existingClaim }}
{{- else if .Values.models.createClaim }}
{{- printf "%s-models" (include "ai-edge-inference.fullname" .) }}
{{- else }}
{{- required "models.existingClaim is required when models.createClaim is false" .Values.models.existingClaim }}
{{- end }}
{{- end }}