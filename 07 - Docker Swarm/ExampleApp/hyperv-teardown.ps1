# remove swarm sample nodes and Hyper-V switch
$nodes = "worker1", "worker2", "worker3", "dbhost", "manager"
docker-machine stop $nodes
docker-machine rm --force -y $nodes

#$SwitchName = "MySwarmExternalSwitch"
#if($(Get-VMSwitch $SwitchName 2>$null)) {
#	# NOTE! will disrupt network traffic on your machine
#	Remove-VMSwitch $SwitchName -Force
#}
