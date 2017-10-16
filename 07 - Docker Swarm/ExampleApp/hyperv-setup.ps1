# Swarm mode using Docker Machine

$managers=3
$workers=3

# Change the SwitchName to the name of your virtual switch
$SwitchName = "MySwarmExternalSwitch"

# create manager machine
echo "======> Creating manager machine ..."
docker-machine create -d hyperv --hyperv-virtual-switch $SwitchName manager

# create dbhost machine
echo "======> Creating dbhost machine ..."
docker-machine create -d hyperv --hyperv-virtual-switch $SwitchName dbhost

# create worker machines
echo "======> Creating worker machines ..."
for ($node=1;$node -le $workers;$node++) {
	echo "======> Creating worker$node machine ..."
	docker-machine create -d hyperv --hyperv-virtual-switch $SwitchName ('worker'+$node)
}

# list all machines
docker-machine ls
echo "======> Initializing swarm manager ..."
$managerip = docker-machine ip manager

docker-machine ssh manager "docker swarm init --listen-addr $managerip --advertise-addr $managerip"

# get manager and worker tokens
$workertoken = docker-machine ssh manager "docker swarm join-token worker -q"

$nodeip = docker-machine ip dbhost
docker-machine ssh dbhost "docker swarm join --token $workertoken --listen-addr $nodeip --advertise-addr $nodeip $managerip"

# workers join swarm
for ($node=1;$node -le $workers;$node++) {
	echo "======> worker$node joining swarm as worker ..."
	$nodeip = docker-machine ip worker$node
	docker-machine ssh "worker$node" "docker swarm join --token $workertoken --listen-addr $nodeip --advertise-addr $nodeip $managerip"
}

# show members of swarm
docker-machine ssh manager "docker node ls"