{{/*
Expand the name of the chart.
*/}}
{{- define "meteo-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "meteo-app.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "meteo-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "meteo-app.labels" -}}
helm.sh/chart: {{ include "meteo-app.chart" . }}
{{ include "meteo-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "meteo-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "meteo-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create ECR repository URL
*/}}
{{- define "meteo-app.ecrUrl" -}}
{{- if .awsAccountId }}
{{- printf "%s.dkr.ecr.%s.amazonaws.com/%s-%s" .awsAccountId .awsRegion .ecrRepositoryPrefix .serviceName }}
{{- else }}
{{- printf "REQUIRES_AWS_ACCOUNT_ID" }}
{{- end }}
{{- end }}

