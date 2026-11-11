{{- define "casama.name" -}}{{ .Release.Name }}{{- end -}}
{{- define "casama.labels" -}}
app.kubernetes.io/name: casama
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
{{- define "casama.secretName" -}}{{ default (printf "%s-secrets" .Release.Name) .Values.existingSecret }}{{- end -}}
{{- define "casama.image" -}}{{ .root.Values.image.registry }}/{{ .name }}:{{ .root.Values.image.tag }}{{- end -}}
{{/* Environment shared by the API and the worker. */}}
{{- define "casama.env" -}}
- { name: NODE_ENV, value: production }
- { name: DATABASE_URL, valueFrom: { secretKeyRef: { name: {{ .Release.Name }}-database, key: url } } }
- { name: SUPABASE_URL, value: {{ .Values.supabase.url | quote }} }
- { name: SUPABASE_ANON_KEY, valueFrom: { secretKeyRef: { name: {{ .Release.Name }}-supabase, key: anonKey } } }
- { name: SUPABASE_JWT_SECRET, valueFrom: { secretKeyRef: { name: {{ .Release.Name }}-supabase, key: jwtSecret } } }
- { name: SUPABASE_SERVICE_ROLE_KEY, valueFrom: { secretKeyRef: { name: {{ .Release.Name }}-supabase, key: serviceRoleKey } } }
- { name: PUBLIC_APP_URL, value: {{ .Values.publicUrl | quote }} }
- { name: PUBLIC_API_URL, value: {{ .Values.publicUrl | quote }} }
- { name: PAGES_URL, value: {{ .Values.pagesUrl | quote }} }
- { name: API_INTERNAL_URL, value: "http://{{ .Release.Name }}-api:8787" }
- { name: SUPERVISOR_URL, value: "http://{{ .Release.Name }}-supervisor:8788" }
{{- range $k := list "INTERNAL_TOKEN" "SUPERVISOR_TOKEN" "METRICS_TOKEN" "CONTENT_ENCRYPTION_KEY" }}
- { name: {{ $k }}, valueFrom: { secretKeyRef: { name: {{ include "casama.secretName" $ }}, key: {{ $k }}, optional: true } } }
{{- end }}
{{- range $k, $v := .Values.extraEnv }}
- { name: {{ $k }}, value: {{ $v | quote }} }
{{- end }}
{{- end -}}
