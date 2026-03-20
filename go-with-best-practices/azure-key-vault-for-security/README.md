### Secure access of secrets from Azure keyvault into AKS using Workload Identity enabled

#### Step 01. Create azure keyvault
```bash
$ az keyvault create --name <name> --resource-group <resource-group> --location <region>
```


#### Step 02. Add secrets into keyvault
```bash
$ az keyvault secret set --vault-name <key_vault_name> --name <specific_key> --vaule "<corresponding_value>"
```

#### Create the Managed Identity (Step 3)
```bash
Log in to the Azure Portal.

In the search bar at the top, type Managed Identities and select it.

Click + Create.

Basics Tab:

Subscription: Select your subscription (3c744587...).

Resource Group: Select rg-aks-southindia.

Region: South India (to match your Resource Group).

Name: aks-kv-identity.

Click Review + Create, then Create.

Once deployment is complete, click Go to resource.

IMPORTANT: On the Overview page, look for the Client ID (a long string of letters and numbers). Copy this—you will need it for your Kubernetes configuration later.
```

#### Step 04: Get the ClientID from above created Managed Identity
```bash
$ az identity show --name <name_of_identity> --resource-group <rg_name> --query clientId -o tsv
```

#### Step 05: For Managed Identity grant access at keyvault
```bash
$ az role assignment create --assignee <CLIENT_ID> --role 'Key Vault Secrets User" --scope $(az keyvault show --name <key_vault_name> --query id -o tsv)
```

#### Step 06: Create Federation Identity

This is the "Golden Bridge" step. By creating the Federated Identity Credential, you are telling Azure: "If a request comes from a Kubernetes Pod using the Service Account go-app-sa in the default namespace, trust it as if it were the aks-kv-identity Managed Identity."

```bash
Step 1: Get your AKS OIDC Issuer URL
Before going to the Identity, you need the unique "Address" of your AKS cluster's identity provider.

In the Azure Portal, go to your Kubernetes Service (AKS cluster).

On the Overview page, look for the JSON View link (top right) or check the Settings > Networking tab.

Search for oidcIssuerProfile. Copy the issuerUrl (it starts with https:// and looks like a long unique ID).
```

```bash
Step 2: Create the Federated Credential in the UI
Search for Managed Identities and select aks-kv-identity (the one we created in the previous step).

In the left-hand menu, under Settings, click on Federated credentials.

Click + Add.

Federated credential scenario: Select Kubernetes accessing Azure resources.

Fill in the details:

Name: kv-federation

Namespace: default (or whichever namespace your Go app runs in).

Service account: go-app-sa (This must match the serviceAccountName in your K8s Deployment YAML).

Issuer URL: Paste the OIDC Issuer URL you copied from Step 1.

The Audience should default to api://AzureADTokenExchange. Leave it as is.

Click Add.
```

```bash
Step 3: Create the Service Account in Kubernetes
To finish the bridge, you must ensure that Service Account actually exists in your AKS cluster. Run this on your Ubuntu management machine:

Bash

apiVersion: v1
kind: ServiceAccount
metadata:
  name: go-app-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: <CLIENT_ID>

And in your Deployment YAML, you must reference it:

YAML

spec:
  template:
    spec:
      serviceAccountName: go-app-sa  # <--- This connects the Pod to the Azure Bridge
      containers:
        - name: go-db-app-container
          ...
```

Think of it as a Trust Agreement between two different governments:

The Government of AKS (Kubernetes): Issues a "Local ID" called a Service Account.

The Government of Azure (Managed Identity): Issues a "Universal ID" called a Managed Identity.

The Federation: Is a formal agreement that says: "If someone shows a valid Local ID from the 'AKS' cluster, we will accept it as a valid Universal ID here in Azure."

#### Step 07: Install CSI Driver
```bash
$ az aks enable-addons --addons azure-keyvault-secrets-provider --name <aks_name> -resource-group <resource_group_name>
```

#### Step 08: CreateSecretProviderClass
* Create secretProviderClass instance with the `secret key` and respective `secret value` you want to access in your deployment

#### Step 09: Update the Deployment YAML

Add Specific Label:
```bash
metadata:
  labels:
    azure.workload.identity/use: "true"
```

Add service account
```bash
spec:
  serviceAccountName: go-app-sa
```
Add Volume
```bash
volumes:
- name: secrets-store   # use name as per requirements
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: kv-secrets   # secretProviderClass instance name
```

Mount the volume
```bash
volumeMounts:
- name: secrets-store
  mountPath: "/mnt/secrets"
  readOnly: "true"
```


Once the deployment is done, exec into the pod and verify 

