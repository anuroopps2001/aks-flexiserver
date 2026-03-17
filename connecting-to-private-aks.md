azureuser@client-management-vm:~$ nslookup aks-private-ptksdb4k.10324b85-7776-4014-a6a1-a8b8165f039c.privatelink.southindia.azmk8s.io
Server:         127.0.0.53
Address:        127.0.0.53#53

** server can't find aks-private-ptksdb4k.10324b85-7776-4014-a6a1-a8b8165f039c.privatelink.southindia.azmk8s.io: NXDOMAIN

azureuser@client-management-vm:~$ az network private-dns zone list -g MC_rg-aks-southindia_aks-private-india_southindia --query "[0].name" -o tsv
10324b85-7776-4014-a6a1-a8b8165f039c.privatelink.southindia.azmk8s.io
azureuser@client-management-vm:~$ VNET_ID=$(az network vnet show -g rg-db-centralindia -n vnet-db --query id -o tsv)
azureuser@client-management-vm:~$ DNS_ZONE=$(az network private-dns zone list -g MC_rg-aks-southindia_aks-private-india_southindia --query "[0].name" -o tsv)
azureuser@client-management-vm:~$ az network private-dns link vnet create \
  --resource-group MC_rg-aks-southindia_aks-private-india_southindia \
  --name central-vnet-to-aks-dns \
  --virtual-network $VNET_ID \
  --zone-name $DNS_ZONE \
  --registration-enabled false
{
  "etag": "\"2f03f1d1-0000-0100-0000-69b8e49c0000\"",
  "id": "/subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/mc_rg-aks-southindia_aks-private-india_southindia/providers/Microsoft.Network/privateDnsZones/10324b85-7776-4014-a6a1-a8b8165f039c.privatelink.southindia.azmk8s.io/virtualNetworkLinks/central-vnet-to-aks-dns",
  "location": "global",
  "name": "central-vnet-to-aks-dns",
  "provisioningState": "Succeeded",
  "registrationEnabled": false,
  "resolutionPolicy": "Default",
  "resourceGroup": "mc_rg-aks-southindia_aks-private-india_southindia",
  "type": "Microsoft.Network/privateDnsZones/virtualNetworkLinks",
  "virtualNetwork": {
    "id": "/subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/rg-db-centralindia/providers/Microsoft.Network/virtualNetworks/vnet-db",
    "resourceGroup": "rg-db-centralindia"
  },
  "virtualNetworkLinkState": "Completed"
}
azureuser@client-management-vm:~$ nslookup aks-private-ptksdb4k.10324b85-7776-4014-a6a1-a8b8165f039c.privatelink.southindia.azmk8s.io
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   aks-private-ptksdb4k.10324b85-7776-4014-a6a1-a8b8165f039c.privatelink.southindia.azmk8s.io
Address: 10.1.1.4

azureuser@client-management-vm:~$