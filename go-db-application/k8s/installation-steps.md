### SSH from windows into ubuntu
```bash 
ssh -i "C:\Users\ANUROOP P S\Downloads/my-kp.pem" ubuntu@100.26.11.234

## **Installed the core packages required to build the application**
```



```bash
$ go mod init go-k8s
go: creating new go.mod: module go-k8s

$ ls 
go.mod  go.sum
```

```bash
$ go get -u github.com/gorilla/mux
go: downloading github.com/gorilla/mux v1.8.1
go: added github.com/gorilla/mux v1.8.1

$ cat ./go.mod
module go-k8s

go 1.25.5

require github.com/gorilla/mux v1.8.1 // indirect


$ cat ./go.sum
github.com/gorilla/mux v1.8.1 h1:TuBL49tXwgrFYWhqrNgrUNEY92u81SPhu7sTdzQEiWY=
github.com/gorilla/mux v1.8.1/go.mod h1:AKf9I4AEqPTmMytcMc0KkNouC66V3BtZ4qD5fmWSiMQ=
```

```bash
$ go get -u gorm.io/gorm
go get -u gorm.io/driver/postgres
go: downloading gorm.io/gorm v1.31.1
go: downloading github.com/jinzhu/now v1.1.5
go: downloading github.com/jinzhu/inflection v1.0.0
go: downloading golang.org/x/text v0.20.0
go: downloading golang.org/x/text v0.32.0
go: added github.com/jinzhu/inflection v1.0.0
go: added github.com/jinzhu/now v1.1.5
go: added golang.org/x/text v0.32.0
go: added gorm.io/gorm v1.31.1
go: added github.com/jackc/pgx/v5 v5.8.0
go: added github.com/jackc/puddle/v2 v2.2.2
go: added golang.org/x/crypto v0.46.0
go: added gorm.io/driver/postgres v1.6.0


$ cat ./go.mod
module go-k8s

go 1.25.5

require (
        github.com/gorilla/mux v1.8.1 // indirect
        github.com/jackc/pgpassfile v1.0.0 // indirect
        github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
        github.com/jackc/pgx/v5 v5.8.0 // indirect
        github.com/jackc/puddle/v2 v2.2.2 // indirect
        github.com/jinzhu/inflection v1.0.0 // indirect
        github.com/jinzhu/now v1.1.5 // indirect
        golang.org/x/crypto v0.46.0 // indirect
        golang.org/x/sync v0.19.0 // indirect
        golang.org/x/text v0.32.0 // indirect
        gorm.io/driver/postgres v1.6.0 // indirect
        gorm.io/gorm v1.31.1 // indirect
)
```

## GIT related  on nginx linux server, 
```bash
bitnami@ip-10-0-1-222:~/go-db-application$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   go.mod

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        go-k8s

no changes added to commit (use "git add" and/or "git commit -a")
bitnami@ip-10-0-1-222:~/go-db-application$ git stash push -m "server local changes before pull"
Saved working directory and index state On main: server local changes before pull
bitnami@ip-10-0-1-222:~/go-db-application$ git stash
apply    branch   clear    create   drop     list     pop      push     show
bitnami@ip-10-0-1-222:~/go-db-application$ git stash list
stash@{0}: On main: server local changes before pull
bitnami@ip-10-0-1-222:~/go-db-application$ git status
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        go-k8s

nothing added to commit but untracked files present (use "git add" to track)
bitnami@ip-10-0-1-222:~/go-db-application$ git stash push -m "server local changes before pull for go-k8s dir"
No local changes to save
bitnami@ip-10-0-1-222:~/go-db-application$ git status
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        go-k8s

nothing added to commit but untracked files present (use "git add" to track)
bitnami@ip-10-0-1-222:~/go-db-application$ git fetch origin
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (1/1), done.
remote: Total 3 (delta 2), reused 3 (delta 2), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 325 bytes | 325.00 KiB/s, done.
From https://github.com/anuroopps2001/go-db-application
   effeb48..6310dfa  main       -> origin/main
bitnami@ip-10-0-1-222:~/go-db-application$ git log --oneline --decorate HEAD..origin/main
6310dfa (origin/main, origin/HEAD) updated dsn by interchaging dbpassword and dbname in database.go
bitnami@ip-10-0-1-222:~/go-db-application$ git diff HEAD..origin/main
diff --git a/database.go b/database.go
index ac21033..473a952 100644
--- a/database.go
+++ b/database.go
@@ -60,7 +60,7 @@ func NewDBClient() (Client, error) {
                log.Fatal("Invalid DB Port.!")
        }

-       dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%d sslmode=%s", dbHost, dbUsername, dbName, dbPassword, databasePort, "disable")
+       dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%d sslmode=%s", dbHost, dbUsername, dbPassword, dbName, databasePort, "disable")
        db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})

        if err != nil {
bitnami@ip-10-0-1-222:~/go-db-application$



bitnami@ip-10-0-1-222:~/go-db-application$ git merge origin/main
Updating effeb48..6310dfa
Fast-forward
 database.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bitnami@ip-10-0-1-222:~/go-db-application$ git status
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        go-k8s

nothing added to commit but untracked files present (use "git add" to track)
bitnami@ip-10-0-1-222:~/go-db-application$ git stash apply stash@{0}
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   go.mod

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        go-k8s

no changes added to commit (use "git add" and/or "git commit -a")
bitnami@ip-10-0-1-222:~/go-db-application$

```

## Fetch and merge changes from remote repo into localcloned repo

```bash
$ git fetch origin
remote: Enumerating objects: 6, done.
remote: Counting objects: 100% (6/6), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 4 (delta 2), reused 4 (delta 2), pack-reused 0 (from 0)
Unpacking objects: 100% (4/4), 9.45 MiB | 3.36 MiB/s, done.
From github.com:anuroopps2001/go-db-application
   6310dfa..e774837  main       -> origin/main





$ git diff HEAD..origin/main 
diff --git a/go-k8s b/go-k8s
new file mode 100755
index 0000000..a3d8411
Binary files /dev/null and b/go-k8s differ
diff --git a/go.mod b/go.mod
index c74601d..468ae28 100644
--- a/go.mod
+++ b/go.mod
@@ -1,6 +1,6 @@
 module go-k8s

-go 1.25.5
+go 1.24.0

 require (
        github.com/gorilla/mux v1.8.1 // indirect
diff --git a/routes.go b/routes.go
index 9155714..d9194ad 100644
--- a/routes.go
+++ b/routes.go
@@ -3,6 +3,6 @@ package main
 func (s *MuxServer) routes() {
        s.gorilla.HandleFunc("/user", s.addUser).Methods("POST")
        s.gorilla.HandleFunc("/users", s.listUsers).Methods("GET")
-       s.gorilla.HandleFunc("/user/{id}", s.updateUser).Methods("PUT")
-       s.gorilla.HandleFunc("user/{id}", s.deleteUser).Methods("DELETE")
+       s.gorilla.HandleFunc("/user{id}", s.updateUser).Methods("PUT")
+       s.gorilla.HandleFunc("user{id}", s.deleteUser).Methods("DELETE")
 }





 $ git merge origin/main
Merge made by the 'ort' strategy.
 go-k8s | Bin 0 -> 20126750 bytes
 go.mod |   2 +-
 2 files changed, 1 insertion(+), 1 deletion(-)
 create mode 100755 go-k8s
```

## go-db application while running
```bash
# Create user
curl -X POST http://localhost:8080/user \
  -H "Content-Type: application/json" \
  -d '{"name":"Anuroop","email":"anu@example.com"}'

# List users
curl http://localhost:8080/users

# Update user
curl -X PUT http://localhost:8080/user/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Anuroop PS"}'

# Delete user
curl -X DELETE http://localhost:8080/user/1







bitnami@ip-10-0-1-222:~/go-db-application$ curl http://localhost:8080/users
{"id":1,"name":"Anuroop","email":"anu@example.com","age":0}

bitnami@ip-10-0-1-222:~/go-db-application$ curl http://localhost:8080/users/1
404 page not found

bitnami@ip-10-0-1-222:~/go-db-application$ curl -X PUT http://localhost:8080/user/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Anuroop PS"}'
{"message":"User updated successfully"}

bitnami@ip-10-0-1-222:~/go-db-application$ curl http://localhost:8080/users
{"id":1,"name":"Anuroop PS","email":"anu@example.com","age":0}

bitnami@ip-10-0-1-222:~/go-db-application$
```
* Because in routes.go
```bash
package main

func (s *MuxServer) routes() {
	s.gorilla.HandleFunc("/user", s.addUser).Methods("POST")
	s.gorilla.HandleFunc("/users", s.listUsers).Methods("GET")
	s.gorilla.HandleFunc("/user/{id}", s.updateUser).Methods("PUT")
	s.gorilla.HandleFunc("user/{id}", s.deleteUser).Methods("DELETE")
}
```


## Merging feature-branch with main branch from Cli
```bash
$ git status
On branch feature-branch
Your branch is up to date with 'udemy-terraform/feature-branch'.

nothing to commit, working tree clean

ANUROOP P S@ANU MINGW64 /d/udemy-terraform/08-input-vars-locals-outputs (feature-branch)
$ git checkout main
Switched to branch 'main'
Your branch is up to date with 'udemy-terraform/main'.

ANUROOP P S@ANU MINGW64 /d/udemy-terraform/08-input-vars-locals-outputs (main)
$ git branch
  feature-branch
* main

ANUROOP P S@ANU MINGW64 /d/udemy-terraform/08-input-vars-locals-outputs (main)
$ git pull origin main
fatal: 'origin' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.

ANUROOP P S@ANU MINGW64 /d/udemy-terraform/08-input-vars-locals-outputs (main)
$ git pull udemy-terraform main
From github.com:anuroopps2001/udemy-terraform
 * branch            main       -> FETCH_HEAD
Already up to date.

ANUROOP P S@ANU MINGW64 /d/udemy-terraform/08-input-vars-locals-outputs (main)
$ git diff HEAD..udemy-terraform/main

ANUROOP P S@ANU MINGW64 /d/udemy-terraform/08-input-vars-locals-outputs (main)
$ git merge feature-branch
Updating 85812a0..022f1d6
Fast-forward
 06-resources/ec2.tf                                | 108 +++++++++++++++++++++
 06-resources/main.tf                               |  43 ++++----
 06-resources/providers.tf                          |   2 +
 06-resources/scripts/docker_install.sh             |  17 ++++
 06-resources/scripts/install_jenkins.sh            |  41 ++++++++
 06-resources/terraform.tf                          |   2 +-
 06-resources/user_data.tpl                         |  12 +++
 07-data-sources/ami-id/ec2.tf                      |  56 +++++++++++
 07-data-sources/ami-id/outputs.tf                  |  12 +++
 07-data-sources/ami-id/provider.tf                 |  10 ++
 07-data-sources/ami-id/terraform.tf                |   8 ++
 .../iam-policies.tf                                |  20 ++++
 .../iam-policies-creation-datasource/provider.tf   |   3 +
 .../iam-policies-creation-datasource/terraform.tf  |   8 ++
 07-data-sources/region-and-aws-acc-info/output.tf  |   7 ++
 .../region-and-aws-acc-info/provider.tf            |  10 ++
 07-data-sources/region-and-aws-acc-info/region.tf  |  15 +++
 .../region-and-aws-acc-info/terraform.tf           |   8 ++
 07-data-sources/vpc-and-azs-info/provider.tf       |  10 ++
 07-data-sources/vpc-and-azs-info/terraform.tf      |   8 ++
 07-data-sources/vpc-and-azs-info/vpc.tf            |  42 ++++++++
 08-input-vars-locals-outputs/dev.terraform.tfvars  |  12 +++
 08-input-vars-locals-outputs/ec2.tf                |  30 ++++++
 08-input-vars-locals-outputs/prod.terraform.tfvars |  12 +++
 08-input-vars-locals-outputs/terraform.tf          |  13 +++
 08-input-vars-locals-outputs/variables.tf          |  29 ++++++
 alb-ha-ec2/provider.tf                             |   3 +
 alb-ha-ec2/subnets.tf                              |  28 ++++++
 alb-ha-ec2/terraform.tf                            |   8 ++
 alb-ha-ec2/vpc.tf                                  |  14 +++
 amazon-eks-jenkins-terraform/install_jenkins.sh    |  41 ++++++++
 proj01-s3-static-website/build/index.html          |   1 +
 proj01-s3-static-website/outputs.tf                |   3 +
 proj01-s3-static-website/provider.tf               |   4 +
 proj01-s3-static-website/s3.tf                     |  94 ++++++++++++++++++
 proj01-s3-static-website/terraform.tf              |  12 +++
 36 files changed, 727 insertions(+), 19 deletions(-)
 create mode 100644 06-resources/ec2.tf
 create mode 100644 06-resources/scripts/docker_install.sh
 create mode 100644 06-resources/scripts/install_jenkins.sh
 create mode 100644 06-resources/user_data.tpl
 create mode 100644 07-data-sources/ami-id/ec2.tf
 create mode 100644 07-data-sources/ami-id/outputs.tf
 create mode 100644 07-data-sources/ami-id/provider.tf
 create mode 100644 07-data-sources/ami-id/terraform.tf
 create mode 100644 07-data-sources/iam-policies-creation-datasource/iam-policies.tf
 create mode 100644 07-data-sources/iam-policies-creation-datasource/provider.tf
 create mode 100644 07-data-sources/iam-policies-creation-datasource/terraform.tf
 create mode 100644 07-data-sources/region-and-aws-acc-info/output.tf
 create mode 100644 07-data-sources/region-and-aws-acc-info/provider.tf
 create mode 100644 07-data-sources/region-and-aws-acc-info/region.tf
 create mode 100644 07-data-sources/region-and-aws-acc-info/terraform.tf
 create mode 100644 07-data-sources/vpc-and-azs-info/provider.tf
 create mode 100644 07-data-sources/vpc-and-azs-info/terraform.tf
 create mode 100644 07-data-sources/vpc-and-azs-info/vpc.tf
 create mode 100644 08-input-vars-locals-outputs/dev.terraform.tfvars
 create mode 100644 08-input-vars-locals-outputs/ec2.tf
 create mode 100644 08-input-vars-locals-outputs/prod.terraform.tfvars
 create mode 100644 08-input-vars-locals-outputs/terraform.tf
 create mode 100644 08-input-vars-locals-outputs/variables.tf
 create mode 100644 alb-ha-ec2/provider.tf
 create mode 100644 alb-ha-ec2/subnets.tf
 create mode 100644 alb-ha-ec2/terraform.tf
 create mode 100644 alb-ha-ec2/vpc.tf
 create mode 100644 amazon-eks-jenkins-terraform/install_jenkins.sh
 create mode 100644 proj01-s3-static-website/build/index.html
 create mode 100644 proj01-s3-static-website/outputs.tf
 create mode 100644 proj01-s3-static-website/provider.tf
 create mode 100644 proj01-s3-static-website/s3.tf
 create mode 100644 proj01-s3-static-website/terraform.tf

ANUROOP P S@ANU MINGW64 /d/udemy-terraform/08-input-vars-locals-outputs (main)
$ git push udemy-terraform main
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:anuroopps2001/udemy-terraform.git
   85812a0..022f1d6  main -> main
```

## Minikube installation on ubutu

```bash
ubuntu@ip-10-0-1-77:~/go-db-application/k8s$ sudo apt update
sudo apt install -y curl wget apt-transport-https
Hit:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu jammy InRelease
Hit:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:3 http://us-east-1.ec2.archive.ubuntu.com/ubuntu jammy-backports InRelease
Hit:4 http://security.ubuntu.com/ubuntu jammy-security InRelease
0% [Connected to download.docker.com (13.226.209.113)]
Hit:5 https://download.docker.com/linux/ubuntu jammy InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
7 packages can be upgraded. Run 'apt list --upgradable' to see them.
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
curl is already the newest version (7.81.0-1ubuntu1.21).
wget is already the newest version (1.21.2-2ubuntu1.1).
wget set to manually installed.
The following packages were automatically installed and are no longer required:
  bridge-utils dns-root-data dnsmasq-base ubuntu-fan
Use 'sudo apt autoremove' to remove them.
The following NEW packages will be installed:
  apt-transport-https
0 upgraded, 1 newly installed, 0 to remove and 7 not upgraded.
Need to get 1510 B of archives.
After this operation, 170 kB of additional disk space will be used.
Get:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu jammy-updates/universe amd64 apt-transport-https all 2.4.14 [1510 B]
Fetched 1510 B in 0s (109 kB/s)
Selecting previously unselected package apt-transport-https.
(Reading database ... 65236 files and directories currently installed.)
Preparing to unpack .../apt-transport-https_2.4.14_all.deb ...
Unpacking apt-transport-https (2.4.14) ...
Setting up apt-transport-https (2.4.14) ...
Scanning processes...
Scanning candidates...
Scanning linux images...

Running kernel seems to be up-to-date.

Restarting services...
 systemctl restart chrony.service cron.service polkit.service serial-getty@ttyS0.service
Service restarts being deferred:
 /etc/needrestart/restart.d/dbus.service
 systemctl restart getty@tty1.service
 systemctl restart networkd-dispatcher.service
 systemctl restart unattended-upgrades.service
 systemctl restart user@1000.service

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
ubuntu@ip-10-0-1-77:~/go-db-application/k8s$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  133M  100  133M    0     0   113M      0  0:00:01  0:00:01 --:--:--  114M
ubuntu@ip-10-0-1-77:~/go-db-application/k8s$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
^C
ubuntu@ip-10-0-1-77:~/go-db-application/k8s$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
^C
ubuntu@ip-10-0-1-77:~/go-db-application/k8s$ minikube version
minikube version: v1.37.0
commit: 65318f4cfff9c12cc87ec9eb8f4cdd57b25047f3
ubuntu@ip-10-0-1-77:~/go-db-application/k8s$ curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   138  100   138    0     0   1391      0 --:--:-- --:--:-- --:--:--  1393
100 55.8M  100 55.8M    0     0  90.8M      0 --:--:-- --:--:-- --:--:-- 90.8M
ubuntu@ip-10-0-1-77:~/go-db-application/k8s$ kubectl version --client
Client Version: v1.35.0
Kustomize Version: v5.7.1
ubuntu@ip-10-0-1-77:~/go-db-application/k8s$ minikube start --driver=docker
😄  minikube v1.37.0 on Ubuntu 22.04 (xen/amd64)
✨  Using the docker driver based on user configuration

🧯  The requested memory allocation of 3072MiB does not leave room for system overhead (total system memory: 3904MiB). You may face stability issues.
💡  Suggestion: Start minikube with less memory allocated: 'minikube start --memory=3072mb'

📌  Using Docker driver with root privileges
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🚜  Pulling base image v0.0.48 ...
💾  Downloading Kubernetes v1.34.0 preload ...
    > preloaded-images-k8s-v18-v1...:  337.07 MiB / 337.07 MiB  100.00% 75.10 M
    > gcr.io/k8s-minikube/kicbase...:  488.52 MiB / 488.52 MiB  100.00% 47.46 M



🔥  Creating docker container (CPUs=2, Memory=3072MB) ...
🐳  Preparing Kubernetes v1.34.0 on Docker 28.4.0 ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
ubuntu@ip-10-0-1-77:~/go-db-application/k8s$
```


## Go application deployment into k8s
```bash
ubuntu@ip-10-0-1-77:~/go-db-application$ kubectl get svc
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
go-db-service         ClusterIP   10.109.226.55   <none>        8080/TCP   2m59s
kubernetes            ClusterIP   10.96.0.1       <none>        443/TCP    40m
postgres-db-service   ClusterIP   10.102.32.141   <none>        5432/TCP   2m59s
ubuntu@ip-10-0-1-77:~/go-db-application$ kubectl port-forward svc/go-db-service 8080:8080
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
^Cubuntu@ip-10-0-1-77:~/go-db-application$ kubectl get pods,svc
NAME                                      READY   STATUS    RESTARTS        AGE
pod/go-db-app-797b7f59f4-55qr8            1/1     Running   2 (5m28s ago)   5m30s
pod/postgres-deployment-5d9597d5b-526f9   1/1     Running   0               5m30s

NAME                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/go-db-service         ClusterIP   10.109.226.55   <none>        8080/TCP   5m30s
service/kubernetes            ClusterIP   10.96.0.1       <none>        443/TCP    43m
service/postgres-db-service   ClusterIP   10.102.32.141   <none>        5432/TCP   5m30s
ubuntu@ip-10-0-1-77:~/go-db-application$




ubuntu@ip-10-0-1-77:~/go-db-application$ kubectl port-forward svc/go-db-service 8080:8080
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
Handling connection for 8080
Handling connection for 8080





ubuntu@ip-10-0-1-77:~$ ps aux | grep 8080
ubuntu     53162  0.1  1.2 1285028 49536 pts/1   Sl+  06:46   0:00 kubectl port-forward svc/go-db-service 8080:8080
ubuntu     53439  0.0  0.0   7008  2304 pts/2    S+   06:47   0:00 grep --color=auto 8080
ubuntu@ip-10-0-1-77:~$ curl -X POST http://localhost:8080/user \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Anuroop",
    "email": "anu@example.com",
    "age": 25
  }'
{"id":1,"name":"Anuroop","email":"anu@example.com","age":25}
ubuntu@ip-10-0-1-77:~$ curl http://localhost:8080/users
{"id":1,"name":"Anuroop","email":"anu@example.com","age":25}
ubuntu@ip-10-0-1-77:~$
ubuntu@ip-10-0-1-77:~$
ubuntu@ip-10-0-1-77:~$
ubuntu@ip-10-0-1-77:~$ nc
usage: nc [-46CDdFhklNnrStUuvZz] [-I length] [-i interval] [-M ttl]
          [-m minttl] [-O length] [-P proxy_username] [-p source_port]
          [-q seconds] [-s sourceaddr] [-T keyword] [-V rtable] [-W recvlimit]
          [-w timeout] [-X proxy_protocol] [-x proxy_address[:port]]
          [destination] [port]
ubuntu@ip-10-0-1-77:~$ nc -zv localhost 8080
Connection to localhost (127.0.0.1) 8080 port [tcp/http-alt] succeeded!
ubuntu@ip-10-0-1-77:~$
```

## Metrics go code
```bash
ubuntu@ip-10-0-1-77:~/go-db-application$ export DB_HOST=localhost
export DB_PORT=5432
export DB_USERNAME=postgres
export DB_PASSWORD=mysecretpassword
export DB_NAME=mydb
ubuntu@ip-10-0-1-77:~/go-db-application$ export DB_PASSWORD=mysecretpassword
ubuntu@ip-10-0-1-77:~/go-db-application$ ./go-k8s
2026/01/03 08:37:40 DB CONFIG -> host=localhost user=postgres db=mydb port=5432

2026/01/03 08:37:40 /home/ubuntu/go-db-application/database.go:62
[error] failed to initialize database, got error failed to connect to `user=postgres database=mydb`: 127.0.0.1:5432 (localhost): server error: FATAL: database "mydb" does not exist (SQLSTATE 3D000)
2026/01/03 08:37:40 DB Error: failed to connect to `user=postgres database=mydb`: 127.0.0.1:5432 (localhost): server error: FATAL: database "mydb" does not exist (SQLSTATE 3D000)
ubuntu@ip-10-0-1-77:~/go-db-application$ docker ps
CONTAINER ID   IMAGE      COMMAND                  CREATED          STATUS          PORTS                                         NAMES
ab2326c6c4df   postgres   "docker-entrypoint.s…"   25 minutes ago   Up 25 minutes   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   some-postgres
ubuntu@ip-10-0-1-77:~/go-db-application$ ps aux | grep 5432
root       71474  0.0  0.1 1673092 4480 ?        Sl   08:12   0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 5432 -container-ip 172.17.0.2 -container-port 5432 -use-listen-fd
root       71480  0.0  0.1 1599360 4480 ?        Sl   08:12   0:00 /usr/bin/docker-proxy -proto tcp -host-ip :: -host-port 5432 -container-ip 172.17.0.2 -container-port 5432 -use-listen-fd
ubuntu     74846  0.0  0.0   7008  2304 pts/4    S+   08:37   0:00 grep --color=auto 5432
ubuntu@ip-10-0-1-77:~/go-db-application$ docker exec -it some-postgres
docker: 'docker exec' requires at least 2 arguments

Usage:  docker exec [OPTIONS] CONTAINER COMMAND [ARG...]

See 'docker exec --help' for more information
ubuntu@ip-10-0-1-77:~/go-db-application$ docker exec -it some-postgres -- sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "--": executable file not found in $PATH
ubuntu@ip-10-0-1-77:~/go-db-application$ docker exec -it some-postgres sh
# psql -U postgres
psql (18.1 (Debian 18.1-1.pgdg13+2))
Type "help" for help.

postgres=# \dt
Did not find any tables.
postgres=# CREATE DATABASE mydb;
CREATE DATABASE
postgres=# \l
                                                    List of databases
   Name    |  Owner   | Encoding | Locale Provider |  Collate   |   Ctype    | Locale | ICU Rules |   Access privileges
-----------+----------+----------+-----------------+------------+------------+--------+-----------+-----------------------
 mydb      | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           |
 postgres  | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           |
 template0 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +
           |          |          |                 |            |            |        |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +
           |          |          |                 |            |            |        |           | postgres=CTc/postgres
(4 rows)

postgres=# \t
Tuples only is on.
postgres=#
\q
#
ubuntu@ip-10-0-1-77:~/go-db-application$ ./go-k8s
2026/01/03 08:40:14 DB CONFIG -> host=localhost user=postgres db=mydb port=5432
2026/01/03 08:40:14 INFO Serving at port 8080


ubuntu@ip-10-0-1-77:~$ ss -tupln | grep 8080
tcp   LISTEN 0      4096                *:8080            *:*    users:(("go-k8s",pid=74917,fd=6))
ubuntu@ip-10-0-1-77:~$ ss -tupln | grep 8080
tcp   LISTEN 0      4096                *:8080            *:*    users:(("go-k8s",pid=74917,fd=6))
ubuntu@ip-10-0-1-77:~$
```


## metrics from go application
```bash
ubuntu@ip-10-0-1-144:~/go-db-application/Docker$ curl http://localhost:8080/metrics
# HELP go_gc_duration_seconds A summary of the wall-time pause (stop-the-world) duration in garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0
go_gc_duration_seconds{quantile="0.25"} 0
go_gc_duration_seconds{quantile="0.5"} 0
go_gc_duration_seconds{quantile="0.75"} 0
go_gc_duration_seconds{quantile="1"} 0
go_gc_duration_seconds_sum 0
go_gc_duration_seconds_count 0


http_request_duration_seconds_bucket{path="/user/{id}",le="10"} 2
http_request_duration_seconds_bucket{path="/user/{id}",le="+Inf"} 2
http_request_duration_seconds_sum{path="/user/{id}"} 0.006244043
http_request_duration_seconds_count{path="/user/{id}"} 2
http_request_duration_seconds_bucket{path="/users",le="0.005"} 2
http_request_duration_seconds_bucket{path="/users",le="0.01"} 2
http_request_duration_seconds_bucket{path="/users",le="0.025"} 2
http_request_duration_seconds_bucket{path="/users",le="0.05"} 2
http_request_duration_seconds_bucket{path="/users",le="0.1"} 2
http_request_duration_seconds_bucket{path="/users",le="0.25"} 2
http_request_duration_seconds_bucket{path="/users",le="0.5"} 2
http_request_duration_seconds_bucket{path="/users",le="1"} 2
http_request_duration_seconds_bucket{path="/users",le="2.5"} 2
http_request_duration_seconds_bucket{path="/users",le="5"} 2
http_request_duration_seconds_bucket{path="/users",le="10"} 2
http_request_duration_seconds_bucket{path="/users",le="+Inf"} 2
http_request_duration_seconds_sum{path="/users"} 0.001297937
http_request_duration_seconds_count{path="/users"} 2
# HELP http_request_total Total number of HTTP requests
# TYPE http_request_total counter
http_request_total{method="DELETE",path="/user/{id}",status="200"} 1
http_request_total{method="GET",path="/users",status="200"} 2
http_request_total{method="POST",path="/user",status="201"} 1
http_request_total{method="PUT",path="/user/{id}",status="200"} 1
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 0.05


promhttp_metric_handler_requests_total{code="200"} 4
promhttp_metric_handler_requests_total{code="500"} 0
promhttp_metric_handler_requests_total{code="503"} 0
ubuntu@ip-10-0-1-144:~/go-db-application/Docker$
```


## go installation in ubuntu
```bash
wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz


ubuntu@ip-10-0-1-144:~/go-db-application$ echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
ubuntu@ip-10-0-1-144:~/go-db-application$ go version
go: downloading go1.24.0 (linux/amd64)
go version go1.24.0 linux/amd64
ubuntu@ip-10-0-1-144:~/go-db-application$



ubuntu@ip-10-0-1-144:~/go-db-application$ docker images
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
ubuntu@ip-10-0-1-144:~/go-db-application$ sudo usermod -aG docker ubuntu
ubuntu@ip-10-0-1-144:~/go-db-application$ newgrp docker
ubuntu@ip-10-0-1-144:~/go-db-application$ sudo systemctl restart docker
ubuntu@ip-10-0-1-144:~/go-db-application$
ubuntu@ip-10-0-1-144:~/go-db-application$ docker images
                                                                                                    i Info →   U  In Use
IMAGE   ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu@ip-10-0-1-144:~/go-db-application$
```

## Scraping k8s cluster metrics
```bash
ubuntu@ip-10-0-1-48:~$ git clone https://github.com/kubernetes/kube-state-metrics.git
cd kube-state-metrics
Cloning into 'kube-state-metrics'...
remote: Enumerating objects: 32881, done.
remote: Counting objects: 100% (39/39), done.
remote: Compressing objects: 100% (28/28), done.
remote: Total 32881 (delta 23), reused 11 (delta 11), pack-reused 32842 (from 2)
Receiving objects: 100% (32881/32881), 23.74 MiB | 24.63 MiB/s, done.
Resolving deltas: 100% (21279/21279), done.
ubuntu@ip-10-0-1-48:~/kube-state-metrics$ ls
CHANGELOG.md     MAINTAINER.md  README.md.tpl          SECURITY_CONTACTS   docs      internal            pkg
CONTRIBUTING.md  Makefile       RELEASE.md             cloudbuild.yaml     examples  jsonnet             scripts
Dockerfile       OWNERS         SECURITY-INSIGHTS.yml  code-of-conduct.md  go.mod    kustomization.yaml  tests
LICENSE          README.md      SECURITY.md            data.yaml           go.sum    main.go
ubuntu@ip-10-0-1-48:~/kube-state-metrics$ kubectl apply -f examples/standard/



ubuntu@ip-10-0-1-48:~/kube-state-metrics$ kubectl apply -k examples/standard/
serviceaccount/kube-state-metrics created
clusterrole.rbac.authorization.k8s.io/kube-state-metrics created
clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics created
Warning: spec.SessionAffinity is ignored for headless services
service/kube-state-metrics created
deployment.apps/kube-state-metrics created
ubuntu@ip-10-0-1-48:~/kube-state-metrics$


ubuntu@ip-10-0-1-48:~/kube-state-metrics$ kubectl get svc -n kube-system
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns             ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   89m
kube-state-metrics   ClusterIP   None         <none>        8080/TCP,8081/TCP        17m
ubuntu@ip-10-0-1-48:~/kube-state-metrics$ kubectl port-forward -n kube-system svc/kube-state-metrics 8082:8080
Forwarding from 127.0.0.1:8082 -> 8080
Forwarding from [::1]:8082 -> 8080
^Cubuntu@ip-10-0-1-48:~/kube-state-metrics$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             10.0.1.48/24 metric 100 fe80::c6:a1ff:fe49:ce8d/64
docker0          DOWN           172.17.0.1/16 fe80::c4ec:82ff:fe8f:e130/64
br-0da8c617e0ee  UP             192.168.49.1/24 fe80::8062:15ff:feaf:2edf/64
vethb6e0c21@if2  UP             fe80::6c00:cff:fe66:b79b/64
ubuntu@ip-10-0-1-48:~/kube-state-metrics$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             10.0.1.48/24 metric 100 fe80::c6:a1ff:fe49:ce8d/64
docker0          DOWN           172.17.0.1/16 fe80::c4ec:82ff:fe8f:e130/64
br-0da8c617e0ee  UP             192.168.49.1/24 fe80::8062:15ff:feaf:2edf/64
vethb6e0c21@if2  UP             fe80::6c00:cff:fe66:b79b/64
ubuntu@ip-10-0-1-48:~/kube-state-metrics$ kubectl port-forward -n kube-system svc/kube-state-metrics 8082:8080
Forwarding from 127.0.0.1:8082 -> 8080
Forwarding from [::1]:8082 -> 8080
Handling connection for 8082
^Cubuntu@ip-10-0-1-48:~/kube-state-metrics$ kubectl port-forward -n kube-system svc/kube-state-metrics 8082:8081
Forwarding from 127.0.0.1:8082 -> 8081
Forwarding from [::1]:8082 -> 8081
Handling connection for 8082



ubuntu@ip-10-0-1-48:~$ curl -kv http://localhost:8082/metrics
*   Trying 127.0.0.1:8082...
* Connected to localhost (127.0.0.1) port 8082 (#0)
> GET /metrics HTTP/1.1
> Host: localhost:8082
> User-Agent: curl/7.81.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: text/plain; version=0.0.4; charset=utf-8; escaping=underscores
< Date: Sat, 03 Jan 2026 19:43:32 GMT
< Transfer-Encoding: chunked
<
# HELP go_gc_duration_seconds A summary of the wall-time pause (stop-the-world) duration in garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 3.7202e-05
go_gc_duration_seconds{quantile="0.25"} 6.3925e-05
go_gc_duration_seconds{quantile="0.5"} 9.433e-05
go_gc_duration_seconds{quantile="0.75"} 0.000144282
go_gc_duration_seconds{quantile="1"} 0.000280728
go_gc_duration_seconds_sum 0.001975839
go_gc_duration_seconds_count 18
# HELP go_gc_gogc_percent Heap size target percentage configured by the user, otherwise 100. This value is set by the GOGC environment variable, and the runtime/debug.SetGCPercent function. Sourced from /gc/gogc:percent.
# TYPE go_gc_gogc_percent gauge
go_gc_gogc_percent 100
# HELP go_gc_gomemlimit_bytes Go runtime memory limit configured by the user, otherwise math.MaxInt64. This value is set by the GOMEMLIMIT environment variable, and the runtime/debug.SetMemoryLimit function. Sourced from /gc/gomemlimit:bytes.
# TYPE go_gc_gomemlimit_bytes gauge
go_gc_gomemlimit_bytes 9.223372036854776e+18
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 157
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
go_info{version="go1.24.6"} 1
# HELP go_memstats_alloc_bytes Number of bytes allocated in heap and currently in use. Equals to /memory/classes/heap/objects:bytes.
# TYPE go_memstats_alloc_bytes gauge
go_memstats_alloc_bytes 7.99116e+06
# HELP go_memstats_alloc_bytes_total Total number of bytes allocated in heap until now, even if released already. Equals to /gc/heap/allocs:bytes.
# TYPE go_memstats_alloc_bytes_total counter
go_memstats_alloc_bytes_total 5.7109968e+07
# HELP go_memstats_buck_hash_sys_bytes Number of bytes used by the profiling bucket hash table. Equals to /memory/classes/profiling/buckets:bytes.
# TYPE go_memstats_buck_hash_sys_bytes gauge
go_memstats_buck_hash_sys_bytes 1.472051e+06
# HELP go_memstats_frees_total Total number of heap objects frees. Equals to /gc/heap/frees:objects + /gc/heap/tiny/allocs:objects.
# TYPE go_memstats_frees_total counter
go_memstats_frees_total 378264
# HELP go_memstats_gc_sys_bytes Number of bytes used for garbage collection system metadata. Equals to /memory/classes/metadata/other:bytes.
# TYPE go_memstats_gc_sys_bytes gauge
go_memstats_gc_sys_bytes 3.796712e+06
# HELP go_memstats_heap_alloc_bytes Number of heap bytes allocated and currently in use, same as go_memstats_alloc_bytes. Equals to /memory/classes/heap/objects:bytes.
# TYPE go_memstats_heap_alloc_bytes gauge
go_memstats_heap_alloc_bytes 7.99116e+06
# HELP go_memstats_heap_idle_bytes Number of heap bytes waiting to be used. Equals to /memory/classes/heap/released:bytes + /memory/classes/heap/free:bytes.
# TYPE go_memstats_heap_idle_bytes gauge
go_memstats_heap_idle_bytes 4.79232e+06
# HELP go_memstats_heap_inuse_bytes Number of heap bytes that are in use. Equals to /memory/classes/heap/objects:bytes + /memory/classes/heap/unused:bytes
# TYPE go_memstats_heap_inuse_bytes gauge
go_memstats_heap_inuse_bytes 1.04448e+07
# HELP go_memstats_heap_objects Number of currently allocated objects. Equals to /gc/heap/objects:objects.
# TYPE go_memstats_heap_objects gauge
go_memstats_heap_objects 41592
# HELP go_memstats_heap_released_bytes Number of heap bytes released to OS. Equals to /memory/classes/heap/released:bytes.
# TYPE go_memstats_heap_released_bytes gauge
go_memstats_heap_released_bytes 3.375104e+06
# HELP go_memstats_heap_sys_bytes Number of heap bytes obtained from system. Equals to /memory/classes/heap/objects:bytes + /memory/classes/heap/unused:bytes + /memory/classes/heap/released:bytes + /memory/classes/heap/free:bytes.
# TYPE go_memstats_heap_sys_bytes gauge
go_memstats_heap_sys_bytes 1.523712e+07
# HELP go_memstats_last_gc_time_seconds Number of seconds since 1970 of last garbage collection.
# TYPE go_memstats_last_gc_time_seconds gauge
go_memstats_last_gc_time_seconds 1.7674693463612137e+09
# HELP go_memstats_mallocs_total Total number of heap objects allocated, both live and gc-ed. Semantically a counter version for go_memstats_heap_objects gauge. Equals to /gc/heap/allocs:objects + /gc/heap/tiny/allocs:objects.
# TYPE go_memstats_mallocs_total counter
go_memstats_mallocs_total 419856
# HELP go_memstats_mcache_inuse_bytes Number of bytes in use by mcache structures. Equals to /memory/classes/metadata/mcache/inuse:bytes.
# TYPE go_memstats_mcache_inuse_bytes gauge
go_memstats_mcache_inuse_bytes 2416
# HELP go_memstats_mcache_sys_bytes Number of bytes used for mcache structures obtained from system. Equals to /memory/classes/metadata/mcache/inuse:bytes + /memory/classes/metadata/mcache/free:bytes.
# TYPE go_memstats_mcache_sys_bytes gauge
go_memstats_mcache_sys_bytes 15704
# HELP go_memstats_mspan_inuse_bytes Number of bytes in use by mspan structures. Equals to /memory/classes/metadata/mspan/inuse:bytes.
# TYPE go_memstats_mspan_inuse_bytes gauge
go_memstats_mspan_inuse_bytes 159200
# HELP go_memstats_mspan_sys_bytes Number of bytes used for mspan structures obtained from system. Equals to /memory/classes/metadata/mspan/inuse:bytes + /memory/classes/metadata/mspan/free:bytes.
# TYPE go_memstats_mspan_sys_bytes gauge
go_memstats_mspan_sys_bytes 163200
# HELP go_memstats_next_gc_bytes Number of heap bytes when next garbage collection will take place. Equals to /gc/heap/goal:bytes.
# TYPE go_memstats_next_gc_bytes gauge
go_memstats_next_gc_bytes 1.196501e+07
# HELP go_memstats_other_sys_bytes Number of bytes used for other system allocations. Equals to /memory/classes/other:bytes.
# TYPE go_memstats_other_sys_bytes gauge
go_memstats_other_sys_bytes 668949
# HELP go_memstats_stack_inuse_bytes Number of bytes obtained from system for stack allocator in non-CGO environments. Equals to /memory/classes/heap/stacks:bytes.
# TYPE go_memstats_stack_inuse_bytes gauge
go_memstats_stack_inuse_bytes 1.540096e+06
# HELP go_memstats_stack_sys_bytes Number of bytes obtained from system for stack allocator. Equals to /memory/classes/heap/stacks:bytes + /memory/classes/os-stacks:bytes.
# TYPE go_memstats_stack_sys_bytes gauge
go_memstats_stack_sys_bytes 1.540096e+06
# HELP go_memstats_sys_bytes Number of bytes obtained from system. Equals to /memory/classes/total:byte.
# TYPE go_memstats_sys_bytes gauge
go_memstats_sys_bytes 2.2893832e+07
# HELP go_sched_gomaxprocs_threads The current runtime.GOMAXPROCS setting, or the number of operating system threads that can execute user-level Go code simultaneously. Sourced from /sched/gomaxprocs:threads.
# TYPE go_sched_gomaxprocs_threads gauge
go_sched_gomaxprocs_threads 2
# HELP go_threads Number of OS threads created.
# TYPE go_threads gauge
go_threads 8
# HELP http_request_duration_seconds A histogram of requests for kube-state-metrics metrics handler.
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{handler="metrics",method="get",le="0.005"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="0.01"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="0.025"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="0.05"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="0.1"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="0.25"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="0.5"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="1"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="2.5"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="5"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="10"} 36
http_request_duration_seconds_bucket{handler="metrics",method="get",le="+Inf"} 36
http_request_duration_seconds_sum{handler="metrics",method="get"} 0.04335142499999999
http_request_duration_seconds_count{handler="metrics",method="get"} 36
# HELP kube_state_metrics_build_info A metric with a constant '1' value labeled by version, revision, branch, goversion from which kube_state_metrics was built, and the goos and goarch for the build.
# TYPE kube_state_metrics_build_info gauge
kube_state_metrics_build_info{branch="",goarch="amd64",goos="linux",goversion="go1.24.6",revision="unknown",tags="unknown",version="v2.17.0"} 1
# HELP kube_state_metrics_custom_resource_state_add_events_total Number of times that the CRD informer triggered the add event.
# TYPE kube_state_metrics_custom_resource_state_add_events_total counter
kube_state_metrics_custom_resource_state_add_events_total 0
# HELP kube_state_metrics_custom_resource_state_cache Net amount of CRDs affecting the cache currently.
# TYPE kube_state_metrics_custom_resource_state_cache gauge
kube_state_metrics_custom_resource_state_cache 0
# HELP kube_state_metrics_custom_resource_state_delete_events_total Number of times that the CRD informer triggered the remove event.
# TYPE kube_state_metrics_custom_resource_state_delete_events_total counter
kube_state_metrics_custom_resource_state_delete_events_total 0
# HELP kube_state_metrics_list_total Number of total resource list calls in kube-state-metrics
# TYPE kube_state_metrics_list_total counter
kube_state_metrics_list_total{resource="*v1.CertificateSigningRequest",result="success"} 1
kube_state_metrics_list_total{resource="*v1.ConfigMap",result="success"} 1
kube_state_metrics_list_total{resource="*v1.CronJob",result="success"} 1
kube_state_metrics_list_total{resource="*v1.DaemonSet",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Deployment",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Endpoints",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Ingress",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Job",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Lease",result="success"} 1
kube_state_metrics_list_total{resource="*v1.LimitRange",result="success"} 1
kube_state_metrics_list_total{resource="*v1.MutatingWebhookConfiguration",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Namespace",result="success"} 1
kube_state_metrics_list_total{resource="*v1.NetworkPolicy",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Node",result="success"} 1
kube_state_metrics_list_total{resource="*v1.PersistentVolume",result="success"} 1
kube_state_metrics_list_total{resource="*v1.PersistentVolumeClaim",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Pod",result="success"} 1
kube_state_metrics_list_total{resource="*v1.PodDisruptionBudget",result="success"} 1
kube_state_metrics_list_total{resource="*v1.ReplicaSet",result="success"} 1
kube_state_metrics_list_total{resource="*v1.ReplicationController",result="success"} 1
kube_state_metrics_list_total{resource="*v1.ResourceQuota",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Secret",result="success"} 1
kube_state_metrics_list_total{resource="*v1.Service",result="success"} 1
kube_state_metrics_list_total{resource="*v1.StatefulSet",result="success"} 1
kube_state_metrics_list_total{resource="*v1.StorageClass",result="success"} 1
kube_state_metrics_list_total{resource="*v1.ValidatingWebhookConfiguration",result="success"} 1
kube_state_metrics_list_total{resource="*v1.VolumeAttachment",result="success"} 1
kube_state_metrics_list_total{resource="*v2.HorizontalPodAutoscaler",result="success"} 1
# HELP kube_state_metrics_shard_ordinal Current sharding ordinal/index of this instance
# TYPE kube_state_metrics_shard_ordinal gauge
kube_state_metrics_shard_ordinal{shard_ordinal="0"} 0
# HELP kube_state_metrics_total_shards Number of total shards this instance is aware of
# TYPE kube_state_metrics_total_shards gauge
kube_state_metrics_total_shards 1
# HELP kube_state_metrics_watch_total Number of total resource watch calls in kube-state-metrics
# TYPE kube_state_metrics_watch_total counter
kube_state_metrics_watch_total{resource="*v1.CertificateSigningRequest",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.ConfigMap",result="success"} 4
kube_state_metrics_watch_total{resource="*v1.CronJob",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.DaemonSet",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.Deployment",result="success"} 4
kube_state_metrics_watch_total{resource="*v1.Endpoints",result="success"} 4
kube_state_metrics_watch_total{resource="*v1.Ingress",result="success"} 4
kube_state_metrics_watch_total{resource="*v1.Job",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.Lease",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.LimitRange",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.MutatingWebhookConfiguration",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.Namespace",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.NetworkPolicy",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.Node",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.PersistentVolume",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.PersistentVolumeClaim",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.Pod",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.PodDisruptionBudget",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.ReplicaSet",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.ReplicationController",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.ResourceQuota",result="success"} 4
kube_state_metrics_watch_total{resource="*v1.Secret",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.Service",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.StatefulSet",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.StorageClass",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.ValidatingWebhookConfiguration",result="success"} 3
kube_state_metrics_watch_total{resource="*v1.VolumeAttachment",result="success"} 3
kube_state_metrics_watch_total{resource="*v2.HorizontalPodAutoscaler",result="success"} 3
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 0.96
# HELP process_max_fds Maximum number of open file descriptors.
# TYPE process_max_fds gauge
process_max_fds 1.048576e+06ytes 1.318244352e+09
# HELP process_virtual_memory_max_bytes Maximum amount of virtual memory available in bytes.
# TYPE process_virtual_memory_max_bytes gauge
process_virtual_memory_max_bytes 1.8446744073709552e+19
* Connection #0 to host localhost left intact
ubuntu@ip-10-0-1-48:~$
```