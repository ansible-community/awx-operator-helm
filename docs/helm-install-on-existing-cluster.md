# Helm Install on existing cluster

For those that wish to use [Helm](https://helm.sh/) to install the awx-operator to an existing K8s cluster:

The helm chart is generated from the `helm-chart` Makefile section using the starter files in `.helm/starter`. Consult [the documentation](https://github.com/ansible-community/awx-operator-helm/blob/main/README.md) on how to customize the AWX resource with your own values.

```bash
$ helm repo add awx-operator https://ansible-community.github.io/awx-operator-helm/
"awx-operator" has been added to your repositories

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "awx-operator" chart repository
Update Complete. ⎈Happy Helming!⎈

$ helm search repo awx-operator
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
awx-operator/awx-operator       2.19.1          2.19.1          A Helm chart for the AWX Operator

$ helm install -n awx --create-namespace my-awx-operator awx-operator/awx-operator
NAME: my-awx-operator
LAST DEPLOYED: Thu Feb 17 22:09:05 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Helm Chart 0.17.1
```
