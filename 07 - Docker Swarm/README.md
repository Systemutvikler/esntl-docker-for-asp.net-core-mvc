[Docker swarm tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/)

[Docker Hyper-v driver](https://docs.docker.com/machine/drivers/hyper-v/)

This is work in progress. Not there yet!

### Running the swarm on Windows 10 Hyper-V

Commands must be run from an elevated PowerShell (Run as Administrator). Note that you will need a machine with a lot of memory in order to create and run 5 virtual machines on Hyper-V. I had 16GB. We are not using MobyLinuxVM, you could stop it if you are running low on memory (```Stop-VM -Name MobyLinuxVM```).

##### Create Hyper-V switch for the VM's
```
New-VMSwitch -Name MySwarmExternalSwitch -NetAdapterName "Ethernet" -AllowManagementOS $true
```
NetAdapterName might differ in your case (```Get-NetAdapter -Physical```)
##### Create the Hyper-V VM's
This could take some time... 
```
docker-machine create -d hyperv --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 -hyperv-cpu-count 2 manager
docker-machine create -d hyperv --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 dbhost
docker-machine create -d hyperv --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 worker1
docker-machine create -d hyperv --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 worker2
docker-machine create -d hyperv --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 worker3
docker-machine ls
```
The last command shows the ip addresses in use by the VM's. Configure your router (or what ever handles DHCP) to use static lease for those ip's otherwize things might fall apart if you reboot. 

##### Issue all docker commands to manager VM
You have to set some environment variables in PowerShell console so that docker commands get sent to the correct virtual machine. In our case we want to send all commands to manager VM.
```
docker-machine env manager | Invoke-Expression
```
The docker environment variables (```Get-ChildItem Env: | findstr "DOCKER"```) will be lost once you close the PowerShell window.

Now that env variables are set, we will initialise manager VM as the swarm master by:
```
docker swarm init
```
Make a note of the result (token and ip address). Replace token and ip:port in the following commands:
```
docker-machine ssh dbhost "docker swarm join --token ???? ?.?.?.?:????"
docker-machine ssh worker1 "docker swarm join --token ???? ?.?.?.?:????"
docker-machine ssh worker2 "docker swarm join --token ???? ?.?.?.?:????"
docker-machine ssh worker3 "docker swarm join --token ???? ?.?.?.?:????"
```
You may now proceed to page 123 in the book and start with command ```docker node ls```. As long as the docker environment variables are set, all commands will be forwarded to the manager VM/node (```docker-machine active```).
##### Cleanup (Dangerous)
Only select yes to "rm" after you have verified the names in the remove list.
```
docker-machine stop $(docker-machine ls -q)
docker-machine rm $(docker-machine ls -q)
Remove-VMSwitch -Name MySwarmExternalSwitch
```
Misc commands used by me. Ip addresses might differ! ```docker-machine ls``` to get ip's.
```
docker service create --name mysql --mount type=volume,source=productdata,destination=/var/lib/mysql --constraint "node.hostname == dbhost" --replicas 1 --network swarm_backend -e MYSQL_ROOT_PASSWORD=mysecret -e bindaddress=0.0.0.0 --detach=false mysql:8.0.0
docker service ps mysql
docker-machine ssh dbhost "docker ps"
docker service update --detach=false --publish-add 3306:3306 mysql

$Env:INITDB = "true"
$Env:DBHOST = "10.0.0.1"
dotnet run
Remove-Item Env:\DBHOST
Remove-Item Env:\INITDB

dotnet publish -c Release -o dist
docker -D build . -t systemutvikler/exampleapp:swarm-1.0 -f Dockerfile

docker -D service create --detach=false --name mvcapp --constraint "node.labels.type==mvc" --replicas 5 --network swarm_backend -p 8000:80 -e DBHOST=mysql systemutvikler/exampleapp:swarm-1.0

TO-DO: set up local Docker registry https://docs.docker.com/registry/
```
