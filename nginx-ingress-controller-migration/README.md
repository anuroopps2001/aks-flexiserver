## Kubernetes API Gateway

- Ingress controller is used to manage the single `Ingress` object

- Kubernetes Gateway API is split into 3 different layers
* **GatewayClass**: Defines the infrastructure (managed by the Cloud/Cluster provider).
* **Gateway**: Defines the entry point, IP address, and TLS settings (managed by the Platform Engineer).
* **HTTPRoute**: Defines the routing rules, paths, and backends (managed by the Application Developer).

### Step-by-Step Migration Strategy

#### Step A: Install the Gateway API CRDs
```bash
$ kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

$ kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
```

#### Step B: Install Gateway Controller
In market, there are bunch of gateway controllers like, nginx gateway controller, envoy gateway and other

We will configure envoy gateway controller and migrate from nginx ingress controller

```bash
$ helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.6.3 \
  -n envoy-gateway-system \
  --create-namespace
```


#### Get the details of the gateway class which will manage the gateway's we will be configuring
```bash
NAME   CONTROLLER                                      ACCEPTED   AGE
eg     gateway.envoyproxy.io/gatewayclass-controller   True       17h
azureuser@client-management-vm:~$ kubectl get gatewayclass eg -oyaml -n envoy-gateway-system
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"gateway.networking.k8s.io/v1","kind":"GatewayClass","metadata":{"annotations":{},"name":"eg"},"spec":{"controllerName":"gateway.envoyproxy.io/gatewayclass-controller"}}
  creationTimestamp: "2026-03-25T12:02:48Z"
  finalizers:
  - gateway-exists-finalizer.gateway.networking.k8s.io
  generation: 1
  name: eg
  resourceVersion: "2140220"
  uid: 1366bec4-7cc6-40ea-a43c-eeaef921e136
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller    # controller
status:
  conditions:
  - lastTransitionTime: "2026-03-25T12:02:48Z"
    message: Valid GatewayClass
    observedGeneration: 1
    reason: Accepted
    status: "True"
    type: Accepted
```



#### Define the Entry Point (The Gateway)
This replaces the NGINX Controller's "Listener" configuration. This manifest tells Envoy to open port 80 and wait for your routes to attach to it.
```bash
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: aks-migration-gateway
  namespace: default
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
```


Once the Gateway resource is being created, a new pod will come up in:
```bash
azureuser@client-management-vm:~$ kubectl get pods  -A
NAMESPACE              NAME                                                            READY   STATUS    RESTARTS   AGE
envoy-gateway-system   envoy-default-aks-migration-gateway-54350ccc-574986b46c-897q5   2/2     Running   0          63s
```

#### Create HTTP Route instance
This is similar to our ingress resource we create in nginx ingress controllers
| NGINX Ingress Field                              | HTTPRoute Equivalent                  |
|--------------------------------------------------|--------------------------------------|
| spec.rules.host                                  | spec.hostnames                       |
| spec.rules.http.paths.path                       | spec.rules.matches.path              |
| spec.rules.http.paths.backend                    | spec.rules.backendRefs               |
| nginx.ingress.kubernetes.io/rewrite-target       | spec.rules.filters.urlRewrite        |


### Adding annotations for envoy gateway instead of gateway resource to have a controller over the loadbalancer IP for gateway
```bash
$ helm upgrade eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.6.3 \
  -n envoy-gateway-system \
  -f aks-flexiserver/nginx-ingress-controller-migration/helm-values.yaml
Pulled: docker.io/envoyproxy/gateway-helm:v1.6.3
Digest: sha256:6dca101fdc0d41c702c1070eb42db119a2768a33388ba28041ae615cbe262aaf
Release "eg" has been upgraded. Happy Helming!
NAME: eg
LAST DEPLOYED: Thu Mar 26 06:22:26 2026
NAMESPACE: envoy-gateway-system
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
TEST SUITE: None
```


Verify whether values are updated or not:
```bash
$ helm get values eg -n envoy-gateway-system

USER-SUPPLIED VALUES:
config:
  envoyGateway:
    provider:
      kubernetes:
        service:
          annotations:
            service.beta.kubernetes.io/azure-load-balancer-internal: "true"
``` 
