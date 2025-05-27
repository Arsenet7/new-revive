{{/*
Expand the name of the chart.
*/}}
{{- define "carts.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "rabbitmq.name" -}}
{{- default .Values.namemq .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "carts.fullname" -}}
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
{{- define "carts.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "carts.labels" -}}
{{ include "carts.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "carts.selectorLabels" -}}
app.kubernetes.io/name: {{ include "carts.name" . }}
{{- end }}

{{/*
Common labelsdb
*/}}
{{- define "carts.labelsdb" -}}
{{ include "carts.selectorLabelsdb" . }}
{{- end }}

{{/*
Selector labelsdb
*/}}
{{- define "carts.selectorLabelsdb" -}}
app.kubernetes.io/name: {{ include "carts.name" . }}-db
{{- end }}

{{/*
Selector labelsmq
*/}}
{{- define "rabbitmq.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rabbitmq.name" . }}
{{- end }}

{{/*
Common labelsmq
*/}}
{{- define "rabbitmq.labels" -}}
{{ include "rabbitmq.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "carts.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "carts.serviceAccountNamedb" -}}
{{- if .Values.serviceAccount.create }}
{{- default "default" .Values.serviceAccount.namedb }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "carts.serviceAccountNamemq" -}}
{{- if .Values.serviceAccount.create }}
{{- default "default" .Values.serviceAccount.namemq }}
{{- end }}
{{- end }}