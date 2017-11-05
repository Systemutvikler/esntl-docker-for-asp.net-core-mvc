# Swarm mode using Docker Machine and Hyper-V

# Change the SwitchName to the name of your external virtual switch if you have one
$SwitchName = "MySwarmExternalSwitch"
$exampleappimagename = "myswarmregistry:5000/exampleapp:swarm-1.0"

# check if switchis created
if (!$(Get-VMSwitch $SwitchName 2>$null)) {
	$netadaptername = $(Get-NetAdapter -Physical | ? Status -eq 'up' | Select-Object -First 1).Name
	echo "You need to create a hyper-v external switch before running this script,"
	echo "or modify it to use an existing hyper-v switch. (Get-VMSwitch -SwitchType External)"
	echo "Try:"
	echo "   New-VMSwitch ""$SwitchName"" -NetAdapterName ""$netadaptername"" -AllowManagementOS `$true"
	echo "and then re-run the script once network is back up again."
	Exit(1)
}

# cant build unless all files are present
if ( !$(Test-Path ".\node_modules\wait-for-it.sh"))
{
	echo "Open solution in Visual Studio to restore packages, then re-run this script"
	Exit 1
}

echo "======> Creating manager machine ..."
docker-machine create -d hyperv --hyperv-virtual-switch $SwitchName manager
$managerip = docker-machine ip manager

echo "======> copy haproxy.cfg and registry cert files to manager VM"
$haproxycfg = [IO.File]::ReadAllText("$pwd\haproxy.cfg")
$myswarmregistryca = [IO.File]::ReadAllText("$pwd\certs\host\myswarmregistry.crt")
$myswarmregistrykey = [IO.File]::ReadAllText("$pwd\certs\host\myswarmregistry.key")
docker-machine ssh manager "printf '%s' '$haproxycfg' | sudo tee /etc/docker/haproxy.cfg && \
  sudo mkdir -p /etc/docker/certs.d/myswarmregistry:5000 && \
  printf '%s' '$myswarmregistryca' | sudo tee /etc/docker/myswarmregistry.crt && \
  printf '%s' '$myswarmregistrykey' | sudo tee /etc/docker/myswarmregistry.key && \
  sudo cp /etc/docker/myswarmregistry.crt /etc/docker/certs.d/myswarmregistry:5000/ca.crt" 

# Redirect all docker commands to manager VM (not shell commands, have to ssh on them)
docker-machine env manager | Invoke-Expression

# create registry at manager VM
docker pull registry:2
echo "======> Setting up local registry exposed by manager ($managerip)"
docker run -d --restart=always --name myswarmregistry --hostname myswarmregistry -v /etc/docker:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/myswarmregistry.crt -e REGISTRY_HTTP_TLS_KEY=/certs/myswarmregistry.key -e REGISTRY_HTTP_SECRET=hemmelig -p 5000:5000 registry:2

# Oddity! Guess the next command waits for previous "docker run --detach" to complete before it returns ip
# Tell manager where to find registry. Works as long as ip's don't change between hyper-v reboots
$myswarmregistryip = docker inspect --format "{{ .NetworkSettings.IPAddress }}" myswarmregistry
echo "======> myswarmregistry ip address: $myswarmregistryip"
# docker push won't work unless we modify /etc/hosts
docker-machine ssh manager "echo $myswarmregistryip  myswarmregistry | sudo tee -a /etc/hosts"

echo "======> Build App image using <TargetFramework> from .csproj"
dotnet publish -c Release -o dist
docker build . -t $exampleappimagename -f .\Dockerfile

echo "======> Pushing $exampleappimagename to local registry $managerip (manager VM)"
docker push $exampleappimagename

# init swarm
docker-machine ssh manager "docker swarm init --listen-addr $managerip --advertise-addr $managerip"
$workertoken = docker-machine ssh manager "docker swarm join-token worker -q"

echo "======> Creating dbhost machine ..."
docker-machine create -d hyperv --hyperv-virtual-switch $SwitchName dbhost
echo "======> dbhost joining swarm ...."
$dbhostip = docker-machine ip dbhost
docker-machine ssh dbhost "docker swarm join --token $workertoken --listen-addr $dbhostip --advertise-addr $dbhostip $managerip"

# create/init worker machines
$workernodes = "worker1", "worker2", "worker3"
echo "======> Creating worker machines ..."
foreach ($node in $workernodes) {
	echo "======> Creating $node machine ..."
	docker-machine create -d hyperv --hyperv-virtual-switch $SwitchName $node
	echo "======> $node joining swarm as worker ..."
	$nodeip = docker-machine ip $node
	docker-machine ssh $node "docker swarm join --token $workertoken --listen-addr $nodeip --advertise-addr $nodeip $managerip"
	docker node update --label-add type=mvc $node
	# make sure worker node trust our registry, and can find it exposed on manager:5000 
	docker-machine ssh $node "sudo mkdir -p /etc/docker/certs.d/myswarmregistry:5000 && \
								printf '%s' '$myswarmregistryca' | sudo tee /etc/docker/certs.d/myswarmregistry:5000/ca.crt; \
								echo $managerip  myswarmregistry | sudo tee -a /etc/hosts" 
}

# display any errors
echo "======> myswarmregistry logs"
docker logs --tail 5 myswarmregistry
echo "======> end logs"

# list all machines
echo "======> List of docker machines"
docker-machine ls

# show members of swarm
echo "======> Members of swarm on manager node"
docker-machine ssh manager "docker node ls"

docker-machine env -u | Invoke-Expression

echo "You may now run script 'manual-deploy-setup.ps1' or deploy using compose file ????"