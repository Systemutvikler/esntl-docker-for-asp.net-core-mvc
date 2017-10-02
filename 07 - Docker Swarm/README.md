[Docker swarm tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/)

[Docker Hyper-v driver](https://docs.docker.com/machine/drivers/hyper-v/)

This is work in progress. Not there yet!

### Running the swarm on Windows 10 Hyper-V
All commands must be run from an elevated powershell console (Run as administrator). We will create five Hyper-V images by using docker-machine comand witch will install [boot2docker](https://github.com/boot2docker/boot2docker) Linux images. The manager node will also act as a local unsecure registry where the swarm nodes can pull images. The solution is fagile, and might not work after reboots. We use custom MAC addresses in order to ease DHCP static lease configuration. 

We are not using MobyLinuxVM, you could stop it if you are running low on memory (```Stop-VM -Name MobyLinuxVM```).

##### Create Hyper-V switch for the VM's
```
New-VMSwitch -Name MySwarmExternalSwitch -NetAdapterName "Ethernet" -AllowManagementOS $true
```
NetAdapterName might differ in your case (```Get-NetAdapter -Physical```)
##### Create the Hyper-V VM's
First we create the manager node.
```
docker-machine create -d hyperv --hyperv-static-macaddress 00-15-00-00-00-01 --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 -hyperv-cpu-count 2 manager
```
The following command will activate/redirect all docker commands to manager node (instead of MobyLinuxVM). Always run it when you open a new Powershell terminal window. Issue ```docker-machine active``` to display active image/node.
```
docker-machine env manager | Invoke-Expression
```
Next we create the dbhost
```
docker-machine create -d hyperv --hyperv-static-macaddress 00-15-00-00-00-02 --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 dbhost
```
 And swarm workers. The swarm nodes needs the ip:port for the insecure registry on manager.
```
$Env:INSECURE_REGISTRY = $Env:DOCKER_HOST.SubString(6).Replace(":2376", ":5000")
docker-machine create -d hyperv --hyperv-static-macaddress 00-15-00-00-00-03 --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 --engine-insecure-registry $Env:INSECURE_REGISTRY worker1
docker-machine create -d hyperv --hyperv-static-macaddress 00-15-00-00-00-04 --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 --engine-insecure-registry $Env:INSECURE_REGISTRY worker2
docker-machine create -d hyperv --hyperv-static-macaddress 00-15-00-00-00-05 --hyperv-virtual-switch MySwarmExternalSwitch --hyperv-memory 2048 --engine-insecure-registry $Env:INSECURE_REGISTRY worker3
```
##### Configure static lease for ip adress on DHCP server (optional)
Head over to your router or what ever is handling [DHCP](https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol) on your network and set up static lease for the ipadresses shown in following command:
```
docker-machine ls
```
Static lease will make sure you get the same ip addresses for the images/nodes when you reboot or recreate the images. Unfortunately Docker swarm will break down if ip addresses change.
##### Install registry on manager VM
```
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

##### Setup Swarm
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
This is almost the same as in the book on page 122 except we have to prefix swarm join with "docker machine ssh xxxx". You may now proceed to page 123 in the book and start with command ```docker node ls```. As long as the docker environment variables are set, all commands will be forwarded to the manager VM/node (```docker-machine active```).

##### Initialize DB
```
$Env:INITDB = "true"
$Env:DBHOST = $(docker-machine ip dbhost)
dotnet run
Remove-Item Env:\DBHOST
Remove-Item Env:\INITDB
```
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



dotnet publish -c Release -o dist
docker -D build . -t $Env:INSECURE_REGISTRY/exampleapp:swarm-1.0 -f Dockerfile
docker -D push $Env:INSECURE_REGISTRY/exampleapp
docker image rm localhost:5000/exampleapp:swarm-1.0

docker -D service create --detach=false --name mvcapp --constraint "node.labels.type==mvc" --replicas 5 --network swarm_backend -p 8000:80 -e DBHOST=mysql -e REGISTRY_HTTP_ADDR=$Env:INSECURE_REGISTRY $Env:INSECURE_REGISTRY/exampleapp

-e REGISTRY_HTTP_ADDR=0.0.0.0:5000

TO-DO: set up local Docker registry 
https://docs.docker.com/registry/ 
https://hub.docker.com/_/registry/
```
docker exec -it registry /bin/sh
cat > /etc/docker/daemon.json
{
    "insecure-registries" : [ "10.0.0.6:5000" ]
}
ctrl+D
exit
