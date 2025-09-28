{{/*
Expand the name of the chart.
*/}}
{{- define "cluster-ai.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cluster-ai.fullname" -}}
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
{{- define "cluster-ai.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cluster-ai.labels" -}}
helm.sh/chart: {{ include "cluster-ai.chart" . }}
{{ include "cluster-ai.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cluster-ai.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cluster-ai.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-ai.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cluster-ai.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "cluster-ai.frontend.selectorLabels" -}}
{{ include "cluster-ai.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "cluster-ai.backend.selectorLabels" -}}
{{ include "cluster-ai.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Database selector labels
*/}}
{{- define "cluster-ai.database.selectorLabels" -}}
{{ include "cluster-ai.selectorLabels" . }}
app.kubernetes.io/component: database
{{- end }}

{{/*
Cache selector labels
*/}}
{{- define "cluster-ai.cache.selectorLabels" -}}
{{ include "cluster-ai.selectorLabels" . }}
app.kubernetes.io/component: cache
{{- end }}
