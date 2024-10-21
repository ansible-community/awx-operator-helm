# Include the Makefile from the ansible/awx-operator repository.
# This Makefile is created with the clone-awx-operator.py script.
include Makefile.awx-operator

AWX_VERSION := $(shell cat awx-operator-version.txt)

# GNU vs BSD in-place sed
ifeq ($(shell sed --version 2>/dev/null | grep -q GNU && echo gnu),gnu)
	SED_I := sed -i
else
	SED_I := sed -i ''
endif

# Helm variables
CHART_NAME ?= awx-operator
CHART_DESCRIPTION ?= A Helm chart for the AWX Operator
CHART_OWNER ?= $(GH_REPO_OWNER)
CHART_REPO ?= awx-operator
CHART_BRANCH ?= gh-pages
CHART_DIR ?= gh-pages
CHART_INDEX ?= index.yaml

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
	python clone-awx-operator.py

	@echo "== KUSTOMIZE: Set image and chart label =="
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	cd config/manager && $(KUSTOMIZE) edit set label helm.sh/chart:$(CHART_NAME)
	cd config/default && $(KUSTOMIZE) edit set label helm.sh/chart:$(CHART_NAME)

	@echo "== Gather Helm Chart Metadata =="
	# remove the existing chart if it exists
	rm -rf charts/$(CHART_NAME)
	# create new chart metadata in Chart.yaml
	cd charts && \
		$(HELM) create $(CHART_NAME) --starter $(shell pwd)/.helm/starter ;\
		$(YQ) -i '.version = "$(AWX_VERSION)"' $(CHART_NAME)/Chart.yaml ;\
		$(YQ) -i '.appVersion = "$(VERSION)" | .appVersion style="double"' $(CHART_NAME)/Chart.yaml ;\
		$(YQ) -i '.description = "$(CHART_DESCRIPTION)"' $(CHART_NAME)/Chart.yaml ;\

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
	# Add .spec.replicas for the controller-manager deployment
	for file in charts/$(CHART_NAME)/raw-files/deployment-*-controller-manager.yaml; do\
		$(YQ) -i '.spec.replicas = "{{ (.Values.Operator).replicas | default 1 }}"' $${file};\
	done
	# Correct .metadata.name for cluster scoped resources
	cluster_scoped_files="charts/$(CHART_NAME)/raw-files/clusterrolebinding-awx-operator-proxy-rolebinding.yaml charts/$(CHART_NAME)/raw-files/clusterrole-awx-operator-metrics-reader.yaml charts/$(CHART_NAME)/raw-files/clusterrole-awx-operator-proxy-role.yaml";\
	for file in $${cluster_scoped_files}; do\
		$(YQ) -i '.metadata.name += "-{{ .Release.Name }}"' $${file};\
	done
	# Correct the reference for the clusterrolebinding
	$(YQ) -i '.roleRef.name += "-{{ .Release.Name }}"' 'charts/$(CHART_NAME)/raw-files/clusterrolebinding-awx-operator-proxy-rolebinding.yaml'
	# Correct .spec.replicas type for the controller-manager deployment
	for file in charts/$(CHART_NAME)/raw-files/deployment-*-controller-manager.yaml; do\
		$(SED_I) "s/'{{ (.Values.Operator).replicas | default 1 }}'/{{ (.Values.Operator).replicas | default 1 }}/g" $${file};\
	done
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
	@echo "AWX Operator installed with Helm Chart version $(VERSION)" > charts/$(CHART_NAME)/templates/NOTES.txt

	@echo "Helm chart successfully configured for $(CHART_NAME) version $(AWX_VERSION)"


.PHONY: helm-package
helm-package: helm-chart
	@echo "== Package Current Chart Version =="
	mkdir -p .cr-release-packages
	# package the chart and put it in .cr-release-packages dir
	$(HELM) package ./charts/$(CHART_NAME) -d .cr-release-packages/$(VERSION)

# List all tags oldest to newest.
TAGS := $(shell git ls-remote --tags --sort=version:refname --refs -q | cut -d/ -f3)

# The actual release happens in ansible/helm-release.yml, which calls this targer
# until https://github.com/helm/chart-releaser/issues/122 happens, chart-releaser is not ideal for a chart
# that is contained within a larger repo, where a tag may not require a new chart version
.PHONY: helm-index
helm-index:
	# when running in CI the gh-pages branch is checked out by the ansible playbook
	# TODO: test if gh-pages directory exists and if not exist

	@echo "== GENERATE INDEX FILE =="
	# This step to workaround issues with old releases being dropped.
	# Until https://github.com/helm/chart-releaser/issues/133 happens
	@echo "== CHART FETCH previous releases =="
	# Download all old releases
	mkdir -p .cr-release-packages

	for tag in $(TAGS); do\
		dl_url="https://github.com/$(CHART_OWNER)/$(CHART_REPO)/releases/download/$${tag}/$(CHART_REPO)-$${tag}.tgz";\
		echo "Downloading $${tag} from $${dl_url}";\
		curl -RLOs -z "$(CHART_REPO)-$${tag}.tgz" --fail $${dl_url};\
		result=$$?;\
		if [ $${result} -eq 0 ]; then\
			echo "Downloaded $${dl_url}";\
			mkdir -p .cr-release-packages/$${tag};\
			mv ./$(CHART_REPO)-$${tag}.tgz .cr-release-packages/$${tag};\
		else\
			echo "Skipping release $${tag}; No helm chart present";\
			rm -rf "$(CHART_REPO)-$${tag}.tgz";\
		fi;\
	done;\

	# generate the index file in the root of the gh-pages branch
	# --merge will leave any values in index.yaml that don't get generated by this command, but
	# it is likely that all values are overridden
	$(HELM) repo index .cr-release-packages --url https://github.com/$(CHART_OWNER)/$(CHART_REPO)/releases/download/ --merge $(CHART_DIR)/index.yaml

	mv .cr-release-packages/index.yaml $(CHART_DIR)/index.yaml
