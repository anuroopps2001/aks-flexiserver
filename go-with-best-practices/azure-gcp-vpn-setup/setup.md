Steps for vpn between Azure and GCP
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
In azure aks vnet
1. Create gateway subnet (10.1.255.0/27) 32 IPs

2. Create the Public IP Instance for VPN 

3. Create Vnet Gateway instance in the above created Dedicated gateway subnet called "GatewaySubnet" also by using the PIP created earlier



In GCP side

1. Create vpn gateway instance
2. Add VPN gateway tunnel with single interface, because azure side we have only single PIP for vpn gateway
3. Create cloud router(BGP:- Border Gateway Protocol)
