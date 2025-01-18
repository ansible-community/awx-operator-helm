# GNU vs BSD in-place sed
ifeq ($(shell sed --version 2>/dev/null | grep -q GNU && echo gnu),gnu)
	SED_I := sed -i
else
	SED_I := sed -i ''
endif

# System variables
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCHA := $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
ARCHX := $(shell uname -m | sed -e 's/amd64/x86_64/' -e 's/aarch64/arm64/')

# Operator configuration variables
IMAGE_TAG_BASE ?= quay.io/ansible/awx-operator

# Helm variables
CHART_NAME ?= awx-operator
CHART_OWNER ?= $(GH_REPO_OWNER)
CHART_REPO ?= awx-operator
CHART_BRANCH ?= gh-pages
CHART_DIR ?= gh-pages
CHART_INDEX ?= index.yaml
# use python3 if python isn't in the path
PYTHON ?= $(shell which python >/dev/null 2>&1 && echo python || echo python3)

.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize: ## Download kustomize locally if necessary.
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v5.0.1/kustomize_v5.0.1_$(OS)_$(ARCHA).tar.gz | \
	tar xzf - -C bin/ ;\
	}
else
KUSTOMIZE = $(shell which kustomize)
endif
endif

.PHONY: kubectl-slice
KUBECTL_SLICE = $(shell pwd)/bin/kubectl-slice
kubectl-slice: ## Download kubectl-slice locally if necessary.
ifeq (,$(wildcard $(KUBECTL_SLICE)))
ifeq (,$(shell which kubectl-slice 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUBECTL_SLICE)) ;\
	curl -sSLo - https://github.com/patrickdappollonio/kubectl-slice/releases/download/v1.2.6/kubectl-slice_$(OS)_$(ARCHX).tar.gz | \
	tar xzf - -C bin/ kubectl-slice ;\
	}
else
KUBECTL_SLICE = $(shell which kubectl-slice)
endif
endif

.PHONY: yq
YQ = $(shell pwd)/bin/yq
yq: ## Download yq locally if necessary.
ifeq (,$(wildcard $(YQ)))
ifeq (,$(shell which yq 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(HELM)) ;\
	curl -sSLo - https://github.com/mikefarah/yq/releases/download/v4.20.2/yq_$(OS)_$(ARCHA).tar.gz | \
	tar xzf - -C bin/ ;\
	mv bin/yq_$(OS)_$(ARCHA) bin/yq ;\
	}
else
YQ = $(shell which yq)
endif
endif

.PHONY: chart-version
chart-version: yq
CHART_VERSION = $(shell cat .helm/starter/Chart.yaml | $(YQ) '.version')

.PHONY: helm
HELM = $(shell pwd)/bin/helm
helm: ## Download helm locally if necessary.
ifeq (,$(wildcard $(HELM)))
ifeq (,$(shell which helm 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(HELM)) ;\
	curl -sSLo - https://get.helm.sh/helm-v3.8.0-$(OS)-$(ARCHA).tar.gz | \
	tar xzf - -C bin/ $(OS)-$(ARCHA)/helm ;\
	mv bin/$(OS)-$(ARCHA)/helm bin/helm ;\
	rmdir bin/$(OS)-$(ARCHA) ;\
	}
else
HELM = $(shell which helm)
endif
endif

PHONY: cr
CR = $(shell pwd)/bin/cr
cr: ## Download cr locally if necessary.
ifeq (,$(wildcard $(CR)))
ifeq (,$(shell which cr 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(CR)) ;\
	curl -sSLo - https://github.com/helm/chart-releaser/releases/download/v1.3.0/chart-releaser_1.3.0_$(OS)_$(ARCHA).tar.gz | \
	tar xzf - -C bin/ cr ;\
	}
else
CR = $(shell which cr)
endif
endif

charts:
	mkdir -p $@

.PHONY: helm-chart
helm-chart: helm-chart-generate

.PHONY: helm-chart-generate
helm-chart-generate: kustomize helm kubectl-slice yq charts

	@echo "== Clone the AWX Operator repository =="
	$(PYTHON) clone-awx-operator.py

	@echo "== KUSTOMIZE: Set image and chart label =="
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMAGE_TAG_BASE):$(shell $(YQ) '.appVersion' .helm/starter/Chart.yaml)
	cd config/manager && $(KUSTOMIZE) edit set label helm.sh/chart:$(CHART_NAME)
	cd config/default && $(KUSTOMIZE) edit set label helm.sh/chart:$(CHART_NAME)

	@echo "== Gather Helm Chart Metadata =="
	# remove the existing chart if it exists
	# edit and copy the Chart.yaml ourselves since helm doesn't do it: https://github.com/helm/helm/issues/9551#issuecomment-811217822
	rm -rf charts/$(CHART_NAME)
	cd charts && \
		$(HELM) create $(CHART_NAME) --starter $(shell pwd)/.helm/starter ;\
		$(YQ) '.name = "$(CHART_NAME)"' $(shell pwd)/.helm/starter/Chart.yaml > $(CHART_NAME)/Chart.yaml;\

	@echo "Generated chart metadata:"
	@cat charts/$(CHART_NAME)/Chart.yaml

	@echo "== KUSTOMIZE: Generate resources and slice into templates =="
	# place in raw-files directory so they can be modified while they are valid yaml - as soon as they are in templates/,
	# wild cards pick up the actual templates, which are not real yaml and can't have yq run on them.
	$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/default | \
		$(KUBECTL_SLICE) --input-file=- \
			--output-dir=charts/$(CHART_NAME)/raw-files \
			--sort-by-kind

	@echo "== Build Templates and CRDS =="
	# Delete metadata.namespace, release namespace will be automatically inserted by helm
	for file in charts/$(CHART_NAME)/raw-files/*; do\
		$(YQ) -i 'del(.metadata.namespace)' $${file};\
	done
	# Correct namespace for rolebinding to be release namespace, this must be explicit
	for file in charts/$(CHART_NAME)/raw-files/*rolebinding*; do\
		$(YQ) -i '.subjects[0].namespace = "{{ .Release.Namespace }}"' $${file};\
	done

	# Correct .metadata.name for cluster scoped resources
	cluster_scoped_files="charts/$(CHART_NAME)/raw-files/clusterrolebinding-awx-operator-proxy-rolebinding.yaml charts/$(CHART_NAME)/raw-files/clusterrole-awx-operator-metrics-reader.yaml charts/$(CHART_NAME)/raw-files/clusterrole-awx-operator-proxy-role.yaml";\
	for file in $${cluster_scoped_files}; do\
		$(YQ) -i '.metadata.name += "-{{ .Release.Name }}"' $${file};\
	done
	# Correct the reference for the clusterrolebinding
	$(YQ) -i '.roleRef.name += "-{{ .Release.Name }}"' 'charts/$(CHART_NAME)/raw-files/clusterrolebinding-awx-operator-proxy-rolebinding.yaml'

	# Feed controller deployment file into template to allow for override from values
	for file in charts/$(CHART_NAME)/raw-files/deployment-*-controller-manager.yaml; do\
		cat $${file} >> charts/$(CHART_NAME)/templates/operator-controller/_operator-controller.tpl;\
		echo "\n---" >> charts/$(CHART_NAME)/templates/operator-controller/_operator-controller.tpl;\
		rm -f $${file} ;\
	done
	echo '{{- end -}}' >> charts/$(CHART_NAME)/templates/operator-controller/_operator-controller.tpl


	# move all custom resource definitions to crds folder
	mkdir charts/$(CHART_NAME)/crds
	mv charts/$(CHART_NAME)/raw-files/customresourcedefinition*.yaml charts/$(CHART_NAME)/crds/.
	# remove any namespace definitions
	rm -f charts/$(CHART_NAME)/raw-files/namespace*.yaml
	# move remaining resources to helm templates
	mv charts/$(CHART_NAME)/raw-files/* charts/$(CHART_NAME)/templates/.
	# remove the raw-files folder
	rm -rf charts/$(CHART_NAME)/raw-files

	# create and populate NOTES.txt
	@echo "AWX Operator installed with Helm Chart version {{ .Chart.Version }}" > charts/$(CHART_NAME)/templates/NOTES.txt

	@echo "Helm chart successfully configured for $(CHART_NAME)"
