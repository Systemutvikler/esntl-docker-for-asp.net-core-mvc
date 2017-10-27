$exampleappimagename = "myswarmregistry:5000/exampleapp:swarm-1.0"
$gitbash = "C:\Program Files\Git\git-bash.exe"
$managerip = docker-machine ip manager

# copy haproxy.cfg to manager
& $gitbash -c "docker-machine scp './haproxy.cfg' manager:~ && echo 'OK' || exec bash"

# copy registry cert files to manager
& $gitbash -c "docker-machine scp -r ./certs/host/ manager:~/certs && echo 'OK' || exec bash"

# copy certs we need on manager and worker nodes to get docker pull/push work for loacal registry
docker-machine ssh manager "sudo mkdir -p /etc/docker/certs.d/myswarmregistry:5000;sudo cp /home/docker/certs/myswarmregistry.crt /etc/docker/certs.d/myswarmregistry:5000/ca.crt"

# Redirect all docker commands to manager VM
docker-machine env manager | Invoke-Expression

# create registry at manager VM
docker run -d --restart=always --name myswarmregistry --hostname myswarmregistry -v /home/docker/certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/myswarmregistry.crt -e REGISTRY_HTTP_TLS_KEY=/certs/myswarmregistry.key -e REGISTRY_HTTP_SECRET=hemmelig -p 5000:5000 registry:2

# tell manager where to find registry
$myswarmregistryip = docker inspect --format "{{ .NetworkSettings.IPAddress }}" myswarmregistry
docker-machine ssh manager "echo $myswarmregistryip  myswarmregistry | sudo tee -a /etc/hosts"

$workernodes = "worker1", "worker2", "worker3"
$myswarmregistryca = [IO.File]::ReadAllText("$pwd\certs\host\myswarmregistry.crt")
foreach ($node in $workernodes)
{
	docker node update --label-add type=mvc $node
	# make sure worker node trust our registry, and find it exposed on manager:5000 
	docker-machine ssh $node "sudo mkdir -p /etc/docker/certs.d/myswarmregistry:5000; \
								printf '%s' '$myswarmregistryca' | sudo tee /etc/docker/certs.d/myswarmregistry:5000/ca.crt; \
								echo $managerip  myswarmregistry | sudo tee -a /etc/hosts" 
}

docker network create -d overlay swarm_backend

echo "======> Setting up mysql service. Could take some time ..."
docker -D service create --name mysql --mount type=volume,source=productdata,destination=/var/lib/mysql --constraint "node.hostname == dbhost" --replicas 1 --network swarm_backend -e MYSQL_ROOT_PASSWORD=mysecret -e bindaddress=0.0.0.0 --detach=false mysql:8.0.0

echo "======> Initializing database on dbhost:3306"
docker service update --detach=false --publish-add 3306:3306 mysql
$Env:INITDB = "true"
$Env:DBHOST = $(docker-machine ip dbhost)
dotnet run
Remove-Item Env:\DBHOST
Remove-Item Env:\INITDB
docker service update --detach=false --publish-rm 3306:3306 mysql

echo "======> Build App image using <TargetFramework> from .csproj"
dotnet publish -c Release -o dist
docker build . -t $exampleappimagename -f .\Dockerfile

docker push $exampleappimagename

docker -D service create --detach=false --name mvcapp --constraint "node.labels.type==mvc" --replicas 5 --network swarm_backend -p 3000:80 -e DBHOST=mysql $exampleappimagename

docker container run -d --name loadbalancer -v "/home/docker/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg" --add-host manager:$managerip -p 80:80 haproxy:1.7.0
docker logs loadbalancer

docker-machine env -u | Invoke-Expression

echo "======> done"
echo "======> You may now browse to http://$managerip"
