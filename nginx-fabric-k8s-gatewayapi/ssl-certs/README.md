```bash
# Generate a self-signed certificate and key
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=://example.com"

# Create the Kubernetes TLS secret
kubectl create secret tls app-tls-secret --cert=tls.crt --key=tls.key --namespace=default
```


# Generating wildCard or SAN certs to be used for multiple Hostnames
```bash
cat <<EOF > openssl.cnf
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = req_ext
prompt             = no

[req_distinguished_name]
C  = IN
ST = KA
L  = Bangalore
O  = Dev
CN = *.local

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.local
DNS.2 = local
EOF
```

```bash
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -config openssl.conf
```


Create K8s secret using the generated tls certs:
```bash
$ kubectl create secret tls wildcard-tls-secret --cert=tls.crt --key=t
ls.key
```

Update the gateway CRD yaml to include secret for https:
```bash
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"   # since AKS is in private subnet, keep the LB ip also private
  name: nginx-gateway
  namespace: default
spec:
  gatewayClassName: nginx
  listeners:
  - allowedRoutes:
      namespaces:
        from: Same
    name: http
    port: 80
    protocol: HTTP
  - allowedRoutes:
      namespaces:
        from: Same
    name: https
    port: 443
    protocol: HTTPS
    tls:
      certificateRefs:
      - group: ""
        kind: Secret
        name: wildcard-tls-secret
      mode: Terminate
```
