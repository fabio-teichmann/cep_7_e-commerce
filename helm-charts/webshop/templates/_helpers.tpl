{{- define "webshop.name" -}}
webshop
{{- end -}}

{{- define "webshop.fullname" -}}
{{ .Release.Name }}-{{ include "webshop.name" . }}
{{- end -}}

{{- define "webshop.labels" -}}
app.kubernetes.io/name: {{ include "webshop.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "webshop.serviceAccountName" -}}
{{- if .Values.serviceAccount.name }}
{{ .Values.serviceAccount.name }}
{{- else }}
{{ include "webshop.fullname" . }}
{{- end }}
{{- end }}
