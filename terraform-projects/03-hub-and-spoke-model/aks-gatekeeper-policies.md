```bash
$ kubectl get constraint
NAME                                                                                                       ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev1blockdefault.constraints.gatekeeper.sh/azurepolicy-k8sazurev1blockdefault-3ea62cea6d24b67f65f1   dryrun               6

NAME                                                                                                                 ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev1containerrequests.constraints.gatekeeper.sh/azurepolicy-k8sazurev1containerrequests-3a328c73e5b64e788b13   deny                 30

NAME                                                                                                               ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev1ingresshttpsonly.constraints.gatekeeper.sh/azurepolicy-k8sazurev1ingresshttpsonly-7c16f3c817f905a25ad8   dryrun               0

NAME                                                                                                                     ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev1serviceallowedports.constraints.gatekeeper.sh/azurepolicy-k8sazurev1serviceallowedports-fed4fe1b696ce3c50357   dryrun               41

NAME                                                                                                                     ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev2blockautomounttoken.constraints.gatekeeper.sh/azurepolicy-k8sazurev2blockautomounttoken-1d9fa50b041a7c210b54   dryrun               21

NAME                                                                                                                   ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev2blockhostnamespace.constraints.gatekeeper.sh/azurepolicy-k8sazurev2blockhostnamespace-33be563c138c48709246   dryrun               1

NAME                                                                                                                         ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev2containerallowedimages.constraints.gatekeeper.sh/azurepolicy-k8sazurev2containerallowedimag-1b10f0111a41c36df80c   dryrun               37

NAME                                                                                                     ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev2noprivilege.constraints.gatekeeper.sh/azurepolicy-k8sazurev2noprivilege-911ab10740320baa3a98   dryrun               0

NAME                                                                                                                     ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev3allowedcapabilities.constraints.gatekeeper.sh/azurepolicy-k8sazurev3allowedcapabilities-3908b8f1ec18a86eea82   dryrun               0

NAME                                                                                                                   ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev3allowedusersgroups.constraints.gatekeeper.sh/azurepolicy-k8sazurev3allowedusersgroups-6efe345a6aa4cb117753   dryrun               32

NAME                                                                                                             ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev3containerlimits.constraints.gatekeeper.sh/azurepolicy-k8sazurev3containerlimits-4cb9b43a2b795e5be845   dryrun               33

NAME                                                                                                                         ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev3disallowedcapabilities.constraints.gatekeeper.sh/azurepolicy-k8sazurev3disallowedcapabiliti-70240e0a17a067630dfc   dryrun               0

NAME                                                                                                             ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev3enforceapparmor.constraints.gatekeeper.sh/azurepolicy-k8sazurev3enforceapparmor-269762e917eca0a401ca   dryrun               0

NAME                                                                                                                     ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev3hostnetworkingports.constraints.gatekeeper.sh/azurepolicy-k8sazurev3hostnetworkingports-5b9d740354c0a39a128a   dryrun               1

NAME                                                                                                                        ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev3noprivilegeescalation.constraints.gatekeeper.sh/azurepolicy-k8sazurev3noprivilegeescalatio-ee97e863107c17d9a40f   dryrun               2

NAME                                                                                                                         ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev3readonlyrootfilesystem.constraints.gatekeeper.sh/azurepolicy-k8sazurev3readonlyrootfilesyst-916276232b53c952d3dd   dryrun               16

NAME                                                                                                           ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
k8sazurev4hostfilesystem.constraints.gatekeeper.sh/azurepolicy-k8sazurev4hostfilesystem-706b092678ad3d116d40   dryrun               6
azureuser@vm-circleci-runner:~/aks-flexiserver/terraform-projects/03-hub-and-spoke-model$ kubectl delete pod policy-test
pod "policy-test" deleted from default namespace
azureuser@vm-circleci-runner:~/aks-flexiserver/terraform-projects/03-hub-and-spoke-model$ kubectl run policy-test --image=nginx --restart=Never
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [azurepolicy-k8sazurev1containerrequests-3a328c73e5b64e788b13] container <policy-test> has no resource requests. For more information, visit https://aka.ms/aks/deployment-safeguards
azureuser@vm-circleci-runner:~/aks-flexiserver/terraform-projects/03-hub-and-spoke-model$
```