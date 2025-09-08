{{/*
Expand the name of the chart.
*/}}
{{- define "this.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "this.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "this.labels" -}}
helm.sh/chart: {{ include "this.chart" . }}
{{ include "this.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "this.selectorLabels" -}}
app.kubernetes.io/name: {{ include "this.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "this.findElem" -}}
  {{- $return := false }}
  {{- range $k, $v := .authorization.users }}
    {{- if and (eq (get $v "user") $.user.username) (hasKey $v "password") -}}
      {{- $return = $v | toJson }}
    {{- end -}}
  {{- end }}
  {{- $return }}
{{- end -}}

{{- define "gen.client-auth-secret" -}}
  {{- if .Values.auth.enabled }}
    {{- $secret := lookup "v1" "Secret" .Release.Namespace "nats-client-auth" -}}
    {{- $auth := dict "authorization" dict }}
    {{- $users := list -}}
    {{- if not $secret -}}{{ $secret = dict "data" dict "auth.conf" dict }}{{- end }}
    {{- if hasKey $secret.data "auth.conf" }}{{ $auth = ((get $secret.data "auth.conf") | b64dec | fromJson) }} {{- end }}
    {{- range $k, $v := .Values.auth.users }}
      {{- $elem := include "this.findElem" (mergeOverwrite dict $auth (dict "user" $v)) }}
      {{- if eq $elem "false" }}
        {{- $users = (prepend $users (dict "user" $v.username "password" ((get $v "password") | default (randAlphaNum 32)))) }}
      {{- else }}
        {{- $users = (prepend $users (merge (dict "password" (get $v "password")) ($elem | fromJson))) }}
      {{- end }}
    {{- end }}
    {{- $_ := set $auth.authorization "users" $users }}
    {{- $_ := set $secret.data "auth.conf" ($auth | toJson | b64enc) }}
    {{- $secret.data | toYaml }}
  {{- end -}}
{{- end -}}
