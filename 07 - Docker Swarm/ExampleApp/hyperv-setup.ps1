# Swarm mode using Docker Machine

# Change the SwitchName to the name of your external virtual switch if you have one
$SwitchName = "MySwarmExternalSwitch"

# check if switchis created
if (!$(Get-VMSwitch $SwitchName 2>$null)) {
	$netadaptername = $(Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Select-Object -First(1)).Name
	echo "You need to create a hyper-v external switch before you can run this script"
	echo "or modify this script to use an existing hyper-v switch (Get-VMSwitch -SwitchType External)"
	echo "Try:"
	echo "   New-VMSwitch ""$SwitchName"" -NetAdapterName ""$netadaptername"" -AllowManagementOS `$true"
	echo "and then rerun the script once network is back up again."
	Exit(1)
}

# create manager machine
echo "======> Creating manager machine ..."
docker-machine create -d hyperv --hyperv-virtual-switch $SwitchName manager
echo "======> Initializing swarm manager ..."
$managerip = docker-machine ip manager
docker-machine ssh manager "docker swarm init --listen-addr $managerip --advertise-addr $managerip"

# get worker tokens
$workertoken = docker-machine ssh manager "docker swarm join-token worker -q"

# create/init worker machines
$workernodes = "dbhost", "worker1", "worker2", "worker3"
echo "======> Creating worker machines ..."
foreach ($node in $workernodes) {
	echo "======> Creating $node machine ..."
	docker-machine create -d hyperv --hyperv-virtual-switch $SwitchName $node
	echo "======> $node joining swarm as worker ..."
	$nodeip = docker-machine ip $node
	docker-machine ssh $node "docker swarm join --token $workertoken --listen-addr $nodeip --advertise-addr $nodeip $managerip"
}

# list all machines
echo "======> List of docker machines"
docker-machine ls

# show members of swarm
echo "======> Members of swarm on manager node"
docker-machine ssh manager "docker node ls"

echo "You may now run script 'manager-setup.ps1'"