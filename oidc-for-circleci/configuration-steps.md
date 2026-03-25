### Flow 

1. The Architecture of Trust
In this setup, Azure acts as the Identity Provider and CircleCI acts as the External Subject.

CircleCI generates a temporary OIDC token for every job.

Azure AD (Entra ID) validates that the token came from your specific CircleCI organization and project.

Azure issues a temporary access token to the CircleCI runner.

CircleCI uses that token to run kubectl commands against AKS.


### Step-by-Step Configuration

#### Step A: Create an Azure Identity
```bash
# Create a Service Principal
azureuser@client-management-vm:~/aks-flexiserver/oidc-for-circleci$ APP_ID=$(az ad app create --display-name "circleci-aks-federation" --query appId -o tsv)
echo "Your App ID is: $APP_ID"
Your App ID is: dda41202-0d40-4cf8-9d25-a7580ca43d57
azureuser@client-management-vm:~/aks-flexiserver/oidc-for-circleci$ az ad sp create --id $APP_ID
{
  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#servicePrincipals/$entity",
  "accountEnabled": true,
  "addIns": [],
  "alternativeNames": [],
  "appDescription": null,
  "appDisplayName": "circleci-aks-federation",
  "appId": "dda41202-0d40-4cf8-9d25-a7580ca43d57",
  "appOwnerOrganizationId": "3241b922-8d4a-4339-9b21-5009e9c776b8",
  "appRoleAssignmentRequired": false,
  "appRoles": [],
  "applicationTemplateId": null,
  "createdByAppId": "04b07795-8ddb-461a-bbee-02f9e1bf7b46",
  "createdDateTime": null,
  "deletedDateTime": null,
  "description": null,
  "disabledByMicrosoftStatus": null,
  "displayName": "circleci-aks-federation",
  "homepage": null,
  "id": "02de8a77-ccbc-41ee-9018-91a81445c088",
  "info": {
    "logoUrl": null,
    "marketingUrl": null,
    "privacyStatementUrl": null,
    "supportUrl": null,
    "termsOfServiceUrl": null
  },
  "keyCredentials": [],
  "loginUrl": null,
  "logoutUrl": null,
  "notes": null,
  "notificationEmailAddresses": [],
  "oauth2PermissionScopes": [],
  "passwordCredentials": [],
  "preferredSingleSignOnMode": null,
  "preferredTokenSigningKeyThumbprint": null,
  "replyUrls": [],
  "resourceSpecificApplicationPermissions": [],
  "samlSingleSignOnSettings": null,
  "servicePrincipalNames": [
    "dda41202-0d40-4cf8-9d25-a7580ca43d57"
  ],
  "servicePrincipalType": "Application",
  "signInAudience": "AzureADMyOrg",
  "tags": [],
  "tokenEncryptionKeyId": null,
  "verifiedPublisher": {
    "addedDateTime": null,
    "displayName": null,
    "verifiedPublisherId": null
  }
}
```

#### Step B: Create the Federated Identity Credential
UI:
```bash
This is the "bridge." You tell Azure: "Trust tokens from CircleCI if they match my Org ID."

Issuer URL: https://oidc.circleci.com/org/YOUR_CIRCLECI_ORG_ID

Subject: org/YOUR_ORG_ID/project/YOUR_PROJECT_ID/user/*

Audience: YOUR_ORG_ID

You can do this in the Azure Portal under Microsoft Entra ID -> App Registrations -> [Your App] -> Certificates & Secrets -> Federated credentials.
```

CLI:
```bash
az ad app federation-credential create --id $APP_ID \
  --parameters '{
    "name": "circleci-oidc-federation",
    "issuer": "https://oidc.circleci.com/org/CIRCLE_CI_ORG_ID",
    "subject": "org/CIRCLE_CI_ORG_ID/project/CIRCLE_CI_PROJECT_ID/user/*",
    "audiences": ["CIRCLE_CI_ORG_ID"]
  }
```
#### Step C: Assign RBAC Permissions
Your new Identity needs permission to talk to the AKS cluster.

```bash
# Assign "Azure Kubernetes Service Cluster User" role
az role assignment create --role "Azure Kubernetes Service Cluster User Role" \
  --assignee <SP_APP_ID> \
  --scope <AKS_RESOURCE_ID>
```
