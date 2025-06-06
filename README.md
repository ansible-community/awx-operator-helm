# AWX Operator Helm Chart

This chart installs the AWX Operator resources configured in [this](https://github.com/ansible/awx-operator) repository.

## Communication

Refer to the
[Getting in touch](https://ansible.readthedocs.io/projects/awx-operator-helm/contributing.html#getting-in-touch)
section of the Contributors guide to find out how to get in touch with us.

You can also find more ways to talk to the community in the [Ansible communication guide](https://docs.ansible.com/ansible/devel/community/communication.html).

## Code of Conduct

Please read and abide by the [Ansible Community Code of Conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html).

## Documentation

- The [Basic usage guide](https://ansible-community.github.io/awx-operator-helm/) provides quickstart information to install the chart.
- The [AWX operator helm chart docsite](https://ansible.readthedocs.io/projects/awx-operator-helm/) provides complete information about installing, using, contributing, and more.

## Getting Started

To configure your AWX resource using this chart, create your own `yaml` values file. The name is up to personal preference since it will explicitly be passed into the helm chart. Helm will merge whatever values you specify in your file with the default `values.yaml`, overriding any settings you've changed while allowing you to fall back on defaults. Because of this functionality, `values.yaml` should not be edited directly.

In your values config, enable `AWX.enabled` and add `AWX.spec` values based on the awx operator's [documentation](https://github.com/ansible/awx-operator/blob/devel/README.md). Consult the docs below for additional functionality.

### Installing

To install the `awx-operator` chart, visit the [chart usage guide](https://ansible-community.github.io/awx-operator-helm/).

Example:

```bash
helm install my-awx-operator awx-operator/awx-operator -n awx --create-namespace -f myvalues.yaml
```

Argument breakdown:

* `-f` passes in the file with your custom values
* `-n` sets the namespace to be installed in
  * This value is accessed by `{{ $.Release.Namespace }}` in the templates
  * Acts as the default namespace for all unspecified resources
* `--create-namespace` specifies that helm should create the namespace before installing

To update an existing installation, use `helm upgrade` instead of `install`. The rest of the syntax remains the same.

### Caveats on upgrading existing installation

There is no support at this time for upgrading or deleting CRDs using Helm.  See [helm documentation](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/#some-caveats-and-explanations) for additional detail.

When upgrading to releases with CRD changes use the following command to update the CRDs

```bash
kubectl apply --server-side -k github.com/ansible/awx-operator/config/crd?ref=<VERSION>
```

If running above command results in an error like below:

```text
Apply failed with 1 conflict: conflict with "helm" using apiextensions.k8s.io/v1: .spec.versions
Please review the fields above--they currently have other managers. Here
are the ways you can resolve this warning:
* If you intend to manage all of these fields, please re-run the apply
  command with the `--force-conflicts` flag.
* If you do not intend to manage all of the fields, please edit your
  manifest to remove references to the fields that should keep their
  current managers.
* You may co-own fields by updating your manifest to match the existing
  value; in this case, you'll become the manager if the other manager(s)
  stop managing the field (remove it from their configuration).
See https://kubernetes.io/docs/reference/using-api/server-side-apply/#conflicts
```

Use `--force-conflicts` flag to resolve the conflict.

```bash
kubectl apply --server-side --force-conflicts -k github.com/ansible/awx-operator/config/crd?ref=<VERSION>
```

## Releases

Releases occur using the [chart-releaser](https://github.com/helm/chart-releaser-action) action, which creates chart artifacts as GitHub releases and updates a helm index held in the `gh-pages` branch.

> The original releases from awx-operator were pre-seeded into the `index.yaml`

Chart-releaser is designed to use the `charts` directory as the source of truth for the current state of the chart.
If there are changes to that directory, the action generates a release.
Unlike many other helm charts, this one is generated on the fly by pulling in the awx-operator source code.

As a result, submitting a pull request that modifies the helm chart generation requires you to run `make helm-chart-generate` and commit the chart changes.

### Versioning
The current CI setup does not run chart releases for PRs that do not change the generated chart.

*Any* release that affects helm chart generation *must* increment the `version` field in `.helm/starter/Chart.yaml`, which is our source of truth for versioning in this repo. Follow the [semantic versioning](https://helm.sh/docs/topics/charts/#charts-and-versioning) guidelines outlined by the helm documentation.

The `appVersion` field in `.helm/starter/Chart.yaml` is the source of truth for the version of AWX Operator that is pulled into the chart templates.

> Before version 3.0.0 of this Chart, the `version` field matched the AWX Operator version. The `version` and `appVersion` fields are independent and can be incremented separately to reflect changes to the chart or the underlying app it installs.

## Custom Resource Configuration

The goal of adding helm configurations is to abstract out and simplify the creation of multi-resource configs. The `AWX.spec` field maps directly to the spec configs of the `AWX` resource that the operator provides, which are detailed in the [main README](https://github.com/ansible/awx-operator/blob/devel/README.md). Other sub-config can be added with the goal of simplifying more involved setups that require additional resources to be specified.

These sub-headers aim to be a more intuitive entrypoint into customizing your deployment, and are easier to manage in the long-term. By design, the helm templates will defer to the manually defined specs to avoid configuration conflicts. For example, if `AWX.spec.postgres_configuration_secret` is being used, the `AWX.postgres` settings will not be applied, even if enabled.

Configuring this field is optional, and additional `AWX` resources can be applied to the cluster once the helm chart is installed. In some cases, it may be advisable to install the AWX resource after chart installation to ensure that there is not a race condition with the CRD installation.

For details on configuration options, see the [AWX values section](#awx) below.

> The helm chart is not responsible for implementing any of the functionality configured in the `AWX` resource. If you are seeing an issue where the `AWX` resource spec is not behaving as expected, raise an issue within the [awx-operator](https://github.com/ansible/awx-operator) repo.

## Values Summary

### Operator Controller Spec
The configuration of the `awx-operator-controller-manager` `Deployment` resource can be overridden by the
`operator-controller` field. Any fields specified under this key will map directly onto the root hierarchy of the [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) configuration.

For example, to override the replicas of the controller deployment, use:

```yml
# values
operator-controller:
  spec:
    replicas: 4
```

Similarly, to add or override annotations:
```yml
# values
operator-controller:
  metadata:
    annotations:
      my-key: my-value
```

To override configurations for the Pod managed by the Deployment

```yml
operator-controller:
  spec:
    template:
      spec:
        securityContext:
          fsGroup: 2000

```

> Note that helm list merge semantics dictate that any list item you specify will *override* the underlying list instead of merging with it. Use the [container override](#operator-controller-container-configuration-override) field below to allow merging container configs

### Operator Controller Container Configuration override
A common use-case is the need to override configurations for individual containers. Because of the helm list override semantics mentioned previously, overriding pieces of a container spec would require re-specifying the *entire* `spec.template.spec.containers` list.

For convenience, the `operator-controller-containers` field can be used to specify container overrides that will be merged when the key of the container matches the `name` of the container in the original deployment spec. This field takes precedence over the `operator-controller` field if there are any conflicts.

The following sample values show overriding at the Deployment, Pod, and Container levels:

```yml
AWX:
  enabled: true
  # These configurations relate to awx pods created by the operator, *not* the controller pods themselves
  spec:
    security_context_settings:
      runAsNonRoot: true
      runAsUser: 1001
      seccompProfile:
        type: RuntimeDefault
      allowPrivilegeEscalation: false
      capabilities:
        drop: [ "ALL" ]

operator-controller-containers:
  # this will get merged into the operator controller deployment spec for
  # the container named `kube-rbac-proxy` at `spec.template.spec.containers`
  kube-rbac-proxy:
    securityContext:
      runAsNonRoot: true
      runAsUser: 1001
      seccompProfile:
        type: RuntimeDefault
      allowPrivilegeEscalation: false
      capabilities:
        drop: [ "ALL" ]
  # example: override the environment variables of the main controller container
  # note that since `env` is a list, it will be an override instead of a merge
  # so any env var change requires re-specifying the whole list
  awx-manager:
    env:
    - name: ANSIBLE_GATHERING
      value: explicit
    - name: ANSIBLE_DEBUG_LOGS
      value: "true" # default was "false"
    - name: WATCH_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace


operator-controller:
  spec:
    # replicas is an example spec for the deployment
    replicas: 2
    # template drills down into the pod that will be manaeg
    template:
      spec:
        # This is a pod-level override, so it can be applied here
        # and not worry about container list semantics
        securityContext:
          fsGroup: 2000

```


> Currently, this field cannot be used to add additional containers to the operator controller deployment


### AWX

| Value | Description | Default |
|---|---|---|
| `AWX.enabled` | Enable this AWX resource configuration | `false` |
| `AWX.name` | The name of the AWX resource and default prefix for other resources | `"awx"` |
| `AWX.annotations` | add annotations to the AWX resource | `{}` |
| `AWX.labels` | add labels to the AWX resource | `{}` |
| `AWX.spec` | specs to directly configure the AWX resource | `{}` |
| `AWX.postgres` | configurations for the external postgres secret | - |


The `AWX.postgres` section simplifies the creation of the external postgres secret. If enabled, the configs provided will automatically be placed in a `postgres-config` secret and linked to the `AWX` resource. For proper secret management, the `AWX.postgres.password` value, and any other sensitive values, can be passed in at the command line rather than specified in code. Use the `--set` argument with `helm install`. Supplying the password this way is not recommended for public-facing workloads, but may be helpful for initial PoC.

### extraDeploy

| Value | Description | Default |
|---|---|---|
| `extraDeploy` | array of additional resources to be deployed (supports YAML or literal "\|") | - |


The `extraDeploy` section allows the creation of additional Kubernetes resources. This simplifies setups requiring additional objects that are used by AWX, e.g. using `ExternalSecrets` to create Kubernetes secrets.

Resources are passed as an array, either as YAML or strings (literal "|"). The resources are passed through `tpl`, so templating is possible. Example:

```yaml
AWX:
  # enable use of awx-deploy template
  ...

  # configurations for external postgres instance
  postgres:
    enabled: false
    ...

extraDeploy:
  - |
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: {{ .Release.Name }}-postgres-secret-string-example
      namespace: {{ .Release.Namespace }}
      labels:
        app: {{ .Release.Name }}
    spec:
      secretStoreRef:
        name: vault
        kind: ClusterSecretStore
      refreshInterval: "1h"
      target:
        name: postgres-configuration-secret-string-example
        creationPolicy: "Owner"
        deletionPolicy: "Delete"
      dataFrom:
        - extract:
            key: awx/postgres-configuration-secret

  - apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: "{{ .Release.Name }}-postgres-secret-yaml-example"
      namespace: "{{ .Release.Namespace }}"
      labels:
        app: "{{ .Release.Name }}"
    spec:
      secretStoreRef:
        name: vault
        kind: ClusterSecretStore
      refreshInterval: "1h"
      target:
        name: postgres-configuration-secret-yaml-example
        creationPolicy: "Owner"
        deletionPolicy: "Delete"
      dataFrom:
        - extract:
            key: awx/postgres-configuration-secret
```

### customSecrets

| Value | Description | Default |
|---|---|---|
| `customSecrets.enabled` | Enable the secret resources configuration | `false` |
| `customSecrets.admin` | Configurations for the secret that contains the admin user password | - |
| `customSecrets.secretKey` | Configurations for the secret that contains the symmetric key for encryption | - |
| `customSecrets.ingressTls` | Configurations for the secret that contains the TLS information when `ingress_type=ingress` | - |
| `customSecrets.routeTls` |  Configurations for the secret that contains the TLS information when `ingress_type=route` (`route_tls_secret`) | - |
| `customSecrets.ldapCacert` | Configurations for the secret that contains the LDAP Certificate Authority | - |
| `customSecrets.ldap` | Configurations for the secret that contains the LDAP BIND DN password | - |
| `customSecrets.bundleCacert` | Configurations for the secret that contains the Certificate Authority | - |
| `customSecrets.eePullCredentials` | Configurations for the secret that contains the pull credentials for registered ees can be found | - |
| `customSecrets.cpPullCredentials` | Configurations for the secret that contains the image pull credentials for app and database containers | - |

Below the addition variables to customize the secret configuration.

#### Admin user password secret configuration

| Value | Description | Default |
|---|---|---|
| `customSecrets.admin.enabled` | If `true`, secret will be created | `false` |
| `customSecrets.admin.password` | Admin user password | - |
| `customSecrets.admin.secretName` | Name of secret for `admin_password_secret` | `<resourcename>-admin-password>` |

#### Secret Key secret configuration

| Value | Description | Default |
|---|---|---|
| `customSecrets.secretKey.enabled` | If `true`, secret will be created | `false` |
| `customSecrets.secretKey.key` | Key is used to encrypt sensitive data in the database | - |
| `customSecrets.secretKey.secretName` | Name of secret for `secret_key_secret` | `<resourcename>-secret-key` |

#### Ingress TLS secret configuration

| Value | Description | Default |
|---|---|---|
| `customSecrets.ingressTls.enabled` | If `true`, secret will be created | `false` |
| `customSecrets.ingressTls.selfSignedCert` | If `true`, an self-signed TLS certificate for `AWX.spec.hostname` will be create by helm | `false` |
| `customSecrets.ingressTls.key` | Private key to use for TLS/SSL | - |
| `customSecrets.ingressTls.certificate` | Certificate to use for TLS/SSL | - |
| `customSecrets.ingressTls.secretName` | Name of secret for `ingress_tls_secret` | `<resourcename>-ingress-tls` |
| `customSecrets.ingressTls.labels` | Array of labels for the secret | - |

#### Route TLS secret configuration

| Value | Description | Default |
|---|---|---|
| `customSecrets.routeTls.enabled` | If `true`, secret will be created | `false` |
| `customSecrets.routeTls.key` | Private key to use for TLS/SSL | - |
| `customSecrets.routeTls.certificate` | Certificate to use for TLS/SSL | - |
| `customSecrets.routeTls.secretName` | Name of secret for `route_tls_secret` | `<resourcename>-route-tls` |

#### LDAP Certificate Authority secret configuration

| Value | Description | Default |
|---|---|---|
| `customSecrets.ldapCacert.enabled` | If `true`, secret will be created | `false` |
| `customSecrets.ldapCacert.crt` | Bundle of CA Root Certificates | - |
| `customSecrets.ldapCacert.secretName` | Name of secret for `ldap_cacert_secret` | `<resourcename>-custom-certs` |

#### LDAP BIND DN Password secret configuration

| Value | Description | Default |
|---|---|---|
| `customSecrets.ldap.enabled` | If `true`, secret will be created | `false` |
| `customSecrets.ldap.password` | LDAP BIND DN password | - |
| `customSecrets.ldap.secretName` | Name of secret for `ldap_password_secret` | `<resourcename>-ldap-password` |

#### Certificate Authority secret configuration

| Value | Description | Default |
|---|---|---|
| `customSecrets.bundleCacert.enabled` | If `true`, secret will be created | `false` |
| `customSecrets.bundleCacert.crt` | Bundle of CA Root Certificates | - |
| `customSecrets.bundleCacert.secretName` | Name of secret for `bundle_cacert_secret` | `<resourcename>-custom-certs` |

#### Default EE pull secrets configuration

| Value | Description | Default |
|---|---|---|
| `customSecrets.eePullCredentials.enabled` | If `true`, secret will be created | `false` |
| `customSecrets.eePullCredentials.url` | Registry url | - |
| `customSecrets.eePullCredentials.username` | Username to connect as | - |
| `customSecrets.eePullCredentials.password` | Password to connect with | - |
| `customSecrets.eePullCredentials.sslVerify` | Whether verify ssl connection or not. | `true` |
| `customSecrets.eePullCredentials.secretName` | Name of secret for `ee_pull_credentials_secret` | `<resourcename>-ee-pull-credentials` |

#### Control Plane pull secrets configuration

| Value | Description | Default |
|---|---|---|
| `customSecrets.cpPullCredentials.enabled` | If `true`, secret will be created | `false` |
| `customSecrets.cpPullCredentials.dockerconfig` | Array of configurations for the Docker credentials that are used for accessing a registry | - |
| `customSecrets.cpPullCredentials.dockerconfig[].registry` | Server location for Docker registry | `https://index.docker.io/v1/` |
| `customSecrets.cpPullCredentials.dockerconfig[].username` | Username to connect as | - |
| `customSecrets.cpPullCredentials.dockerconfig[].password` | Password to connect with | - |
| `customSecrets.cpPullCredentials.secretName` |  Name of secret for `image_pull_secrets`| `<resoucename>-cp-pull-credentials` |

The `customSecrets` section simplifies the creation of our custom secrets used during AWX deployment. Supplying the passwords this way is not recommended for public-facing workloads, but may be helpful for initial PoC.

If enabled, the configs provided will automatically used to create the respective secrets and linked at the CR spec level. For proper secret management, the sensitive values can be passed in at the command line rather than specified in code. Use the `--set` argument with `helm install`.

Example:

```yaml
AWX:
  # enable use of awx-deploy template
  ...

  # configurations for external postgres instance
  postgres:
    enabled: false
    ...

customSecrets:
  enabled: true
  admin:
    enabled: true
    password: mysuperlongpassword
    secretName: my-admin-password
  secretKey:
    enabled: true
    key: supersecuresecretkey
    secretName: my-awx-secret-key
  ingressTls:
    enabled: true
    selfSignedCert: true
    key: unset
    certificate: unset
  routeTls:
    enabled: false
    key: <contentoftheprivatekey>
    certificate: <contentofthepublickey>
  ldapCacert:
    enabled: false
    crt: <contentofmybundlecacrt>
  ldap:
    enabled: true
    password: yourldapdnpassword
  bundleCacert:
    enabled: false
    crt: <contentofmybundlecacrt>
  eePullCredentials:
    enabled: false
    url: unset
    username: unset
    password: unset
    sslVerify: true
    secretName: my-ee-pull-credentials
  cpPullCredentials:
    enabled: false
    dockerconfig:
      - registry: https://index.docker.io/v1/
        username: unset
        password: unset
    secretName: my-cp-pull-credentials
```

### customVolumes

#### Persistent Volume for databases postgres

| Value | Description | Default |
|---|---|---|
| `customVolumes.postgres.enabled` | Enable the PV resource configuration for the postgres databases | `false` |
| `customVolumes.postgres.hostPath` | Directory location on host | - |
| `customVolumes.postgres.size` | Size of the volume | `8Gi` |
| `customVolumes.postgres.accessModes` | Volume access mode | `ReadWriteOnce` |
| `customVolumes.postgres.storageClassName` | PersistentVolume storage class name for `postgres_storage_class` | `<resourcename>-postgres-volume` |

#### Persistent Volume for projects files

| Value | Description | Default |
|---|---|---|
| `customVolumes.projects.enabled` | Enable the PVC and PVC resources configuration for the projects files | `false` |
| `customVolumes.projects.hostPath` | Directory location on host | - |
| `customVolumes.projects.size` |  Size of the volume | `8Gi` |
| `customVolumes.projects.accessModes` | Volume access mode | `ReadWriteOnce` |
| `customVolumes.postgres.storageClassName` | PersistentVolume storage class name | `<resourcename>-projects-volume` |

The `customVolumes` section simplifies the creation of Persistent Volumes used when you want to store your databases and projects files on the cluster's Node. Since their backends are `hostPath`, the size specified are just like a label and there is no actual capacity limitation.

You have to prepare directories for these volumes. For example:

```bash
sudo mkdir -p /data/postgres-13
sudo mkdir -p /data/projects
sudo chmod 755 /data/postgres-13
sudo chown 1000:0 /data/projects
```

Example:

```yaml
AWX:
  # enable use of awx-deploy template
  ...

  # configurations for external postgres instance
  postgres:
    enabled: false
    ...

customVolumes:
  postgres:
    enabled: true
    hostPath: /data/postgres-13
  projects:
    enabled: true
    hostPath: /data/projects
    size: 1Gi
```

## Contributing

### Adding abstracted sections

Where possible, defer to `AWX.spec` configs before applying the abstracted configs to avoid collision. This can be facilitated by the `(hasKey .spec what_i_will_abstract)` check.

### Building and Testing

This chart is built using the Makefile in the [awx-operator repo](https://github.com/ansible/awx-operator). Clone the repo and run `make helm-chart-generate`. This will create the awx-operator chart in the `charts/awx-operator` directory. In this process, the contents of the `.helm/starter` directory will be added to the chart.
