{{/*
This template gets filled with the operator SDK's controller definition
during chart build
*/}}
{{- define "awx-operator.controller" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    control-plane: controller-manager
    helm.sh/chart: awx-operator
  name: awx-operator-controller-manager
spec:
  replicas: 1
  selector:
    matchLabels:
      control-plane: controller-manager
      helm.sh/chart: awx-operator
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/default-container: awx-manager
      labels:
        control-plane: controller-manager
        helm.sh/chart: awx-operator
    spec:
      containers:
        - args:
            - --secure-listen-address=0.0.0.0:8443
            - --upstream=http://127.0.0.1:8080/
            - --logtostderr=true
            - --v=0
          image: gcr.io/kubebuilder/kube-rbac-proxy:v0.15.0
          name: kube-rbac-proxy
          ports:
            - containerPort: 8443
              name: https
              protocol: TCP
          resources:
            limits:
              cpu: 500m
              memory: 128Mi
            requests:
              cpu: 5m
              memory: 64Mi
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
        - args:
            - --health-probe-bind-address=:6789
            - --metrics-bind-address=127.0.0.1:8080
            - --leader-elect
            - --leader-election-id=awx-operator
          env:
            - name: ANSIBLE_GATHERING
              value: explicit
            - name: ANSIBLE_DEBUG_LOGS
              value: "false"
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          image: quay.io/ansible/awx-operator:2.19.1
          imagePullPolicy: IfNotPresent
          livenessProbe:
            httpGet:
              path: /healthz
              port: 6789
            initialDelaySeconds: 15
            periodSeconds: 20
          name: awx-manager
          readinessProbe:
            httpGet:
              path: /readyz
              port: 6789
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            limits:
              cpu: 1500m
              memory: 960Mi
            requests:
              cpu: 50m
              memory: 32Mi
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
      imagePullSecrets:
        - name: redhat-operators-pull-secret
      securityContext:
        runAsNonRoot: true
      serviceAccountName: awx-operator-controller-manager
      terminationGracePeriodSeconds: 10

---
{{- end -}}
