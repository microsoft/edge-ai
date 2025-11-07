{{- define "mqtt-otel-trace-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mqtt-otel-trace-exporter.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "mqtt-otel-trace-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "mqtt-otel-trace-exporter.satSecretName" -}}
{{- if not .Values.satAuth.enabled -}}
{{- "" -}}
{{- else if .Values.satAuth.create -}}
{{- $fullName := include "mqtt-otel-trace-exporter.fullname" . -}}
{{- default (printf "%s-sat" $fullName) .Values.satAuth.secretName -}}
{{- else -}}
{{- required "satAuth.secretName is required when satAuth.enabled=true and create=false" .Values.satAuth.secretName -}}
{{- end -}}
{{- end -}}

{{- define "mqtt-otel-trace-exporter.x509SecretName" -}}
{{- if not .Values.x509Auth.enabled -}}
{{- "" -}}
{{- else if .Values.x509Auth.create -}}
{{- $fullName := include "mqtt-otel-trace-exporter.fullname" . -}}
{{- default (printf "%s-x509" $fullName) .Values.x509Auth.secretName -}}
{{- else -}}
{{- required "x509Auth.secretName is required when x509Auth.enabled=true and create=false" .Values.x509Auth.secretName -}}
{{- end -}}
{{- end -}}

{{- define "mqtt-otel-trace-exporter.labels" -}}
helm.sh/chart: {{ include "mqtt-otel-trace-exporter.chart" . }}
app.kubernetes.io/name: {{ include "mqtt-otel-trace-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.podLabels }}
{{- range $key, $value := .Values.podLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end -}}
