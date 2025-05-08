{{- define "webshop.name" -}}
webshop
{{- end -}}

{{- define "webshop.fullname" -}}
{{ .Release.Name }}-{{ include "webshop.name" . }}
{{- end -}}
