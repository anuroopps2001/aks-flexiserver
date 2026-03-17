```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```


helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install loki-stack grafana/loki-stack \
  --namespace monitoring \
  --set prometheus.enabled=true \
  --set promtail.enabled=true


helm install grafana grafana/grafana \
  --namespace monitoring \
  --set persistence.enabled=true \
  --set adminPassword="admin"


azureuser@client-management-vm:~/aks-flexiserver/nginx-ingres-controller$ kubectl apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml
customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com created
azureuser@client-management-vm:~/aks-flexiserver/nginx-ingres-controller$ kubectl apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/kube-prometheus-stack/charts/crds/crds/crd-prometheuses.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/kube-prometheus-stack/charts/crds/crds/crd-podmonitors.yaml
The CustomResourceDefinition "prometheuses.monitoring.coreos.com" is invalid: metadata.annotations: Too long: may not be more than 262144 bytes
customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com created
azureuser@client-management-vm:~/aks-flexiserver/nginx-ingres-controller$ kubectl get crd | grep servicemonitors
servicemonitors.monitoring.coreos.com            2026-03-17T08:18:26Z
azureuser@client-management-vm:~/aks-flexiserver/nginx-ingres-controller$


prometheus alerting rules:
```
azureuser@client-management-vm:~/aks-flexiserver/nginx-ingres-controller$ kubectl apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/kube-prometheus-stack/charts/crds/crds/crd-prometheusrules.yaml
customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com created
azureuser@client-management-vm:~/aks-flexiserver/nginx-ingres-controller$ kubectl apply -f go-app-alerts.yaml
prometheusrule.monitoring.coreos.com/go-app-alerts created
azureuser@client-management-vm:~/aks-flexiserver/nginx-ingres-controller$
```



### Loki in Openshift

To understand this, think of it as a two-operator system:

Loki Operator: Sets up the "Warehouse" (Loki) where logs are stored.

Red Hat OpenShift Logging Operator: Deploys the "Trucks" (Collectors) that pick up logs and drive them to the warehouse.

Who actually sends the logs?
The component that sends logs is the Collector, which runs as a DaemonSet (one pod on every single node in your cluster). Depending on your OpenShift version, this collector is either Vector or Fluentd.

Vector (Modern/Current): Written in Rust, very fast, and now the default in OpenShift 5.6+.

Fluentd (Legacy): The older default, which is being phased out in favor of Vector.

How the Flow Works (Step-by-Step)
The Pod Logs: Your application writes logs to stdout. OpenShift saves these into files on the Node at /var/log/pods/.

The Collector (Vector/Fluentd): The Collector pod on that node "tails" those files. It automatically attaches Kubernetes metadata (like namespace, pod_name, and container_name) as labels.

The ClusterLogForwarder: This is the "Brain." You create a Custom Resource (CR) called a ClusterLogForwarder that tells the collector: "Take these logs and send them to the LokiStack service."

The Ingestion: The Collector sends the logs over HTTPS to the Loki Gateway, which then hands them off to Loki's Distributors and Ingesters.
