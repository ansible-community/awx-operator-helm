{{/*
Override the operator controller containers so that configuration can be added without
completely overriding the list. Helm list merge semantics dictate that lists are always
completely overridden when specified downstream, which is why we need custom merge logic

Expects dict input:
.values holding the $.Values map
.controllerTemplate holding the operator controller Deployment template
*/}}
{{- define "awx-operator.controller.container-override" -}}
  {{- $overrideContainers := index $.values "operator-controller-containers" }}
  {{- range $containerSpec := .controllerTemplate.spec.template.spec.containers }}
    {{- if (hasKey $overrideContainers $containerSpec.name ) }}
      {{- $_ := mergeOverwrite $containerSpec (index $overrideContainers $containerSpec.name) }}
    {{- end }}
  {{- end }}
{{- end -}}
