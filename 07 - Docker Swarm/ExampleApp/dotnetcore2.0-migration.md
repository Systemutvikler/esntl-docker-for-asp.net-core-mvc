[Docker swarm tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/)

[Docker Hyper-v driver](https://docs.docker.com/machine/drivers/hyper-v/)


### Running the swarm on Windows 10 Hyper-V with local registry
All commands must be run from an elevated PowerShell console (Run as administrator). 
Shortcut: Win-X A. Do not attempt to run the scripts unless you have at least 16GB and a SSD.

The scripts rely on a hyper-v external switch named "MySwarmExternalSwitch" that is connected to a physical adapter. 
You will get a warning and script will exit if it is missing.
If you are clueless,  create one with the following two PS commands:
```
$netadaptername = $(Get-NetAdapter -Physical | ? Status -eq 'up' | Select-Object -First 1).Name
New-VMSwitch "MySwarmExternalSwitch" -NetAdapterName $netadaptername -AllowManagementOS $true
```
You may alter hyperv-setup.ps1 to use an existing hyper-v switch as log as it is external.
#### Create hyper-v images
Creating the five images and local registry may take some time. Issue PS scipt:
```
.\hyperv-setup.ps1
```
After it is done you have two options, run the manual script below or follow the (modified) commands from page 135 and onwards. 

### Manual deploy script
```
.\manaual-deploy-setup.ps1
```
Watch out for the last line wich will give you the http address to run the sample. 
Also make sure the log output above do not contain any errors.

### Deploy commands from page 135
```
docker-machine env manager | Invoke-Expression
docker stack deploy --compose-file docker-compose-swarm-hyperv.yml exampleapp
docker service ls
docker service ps exampleapp_mvc
docker service update --detach=false --publish-add 3306:3306 exampleapp_mysql
$Env:INITDB = "true"
$Env:DBHOST = $(docker-machine ip dbhost)
dotnet run
Remove-Item Env:\DBHOST
Remove-Item Env:\INITDB
docker service update --detach=false --publish-rm 3306:3306 exampleapp_mysql
docker container run -d --name loadbalancer -v "/etc/docker/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg" --add-host manager:$(docker-machine ip manager) -p 80:80 haproxy:1.7.0
docker logs loadbalancer
# the rest of the commands go here ... 
# when done, detach from active host (manager) by
docker-machine env -u | iex
```

#### Cleanup
```
.\hyperv-teardown.ps1
Remove-VMSwitch "MySwarmExternalSwitch"
```
