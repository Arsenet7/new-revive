{{/*
Expand the name of the chart.
*/}}
{{- define "catalog.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "catalog.fullname" -}}
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
{{- define "catalog.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "catalog.labels" -}}
{{ include "catalog.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "catalog.selectorLabels" -}}
app.kubernetes.io/name: {{ include "catalog.name" . }}
{{- end }}

{{/*
Common labelsdb
*/}}
{{- define "catalog.labelsdb" -}}
{{ include "catalog.selectorLabelsdb" . }}
{{- end }}

{{/*
Selector labelsdb
*/}}
{{- define "catalog.selectorLabelsdb" -}}
app.kubernetes.io/name: {{ include "catalog.name" . }}-db
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "catalog.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "catalog.serviceAccountNamedb" -}}
{{- if .Values.serviceAccount.create }}
{{- default "default" .Values.serviceAccount.namedb }}
{{- end }}
{{- end }}