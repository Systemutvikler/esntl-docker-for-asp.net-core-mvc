# Requirements: $pwd.Drive.Root must be shared in docker. Must be logged in to docker hub by "docker login -u <username> --password-stdin" before you run this script
# replace "systemutvikler" with your own username at hub.docker.com
$exampleappimagename = "systemutvikler/exampleapp:swarm-1.0"
$haproxycfg = [IO.File]::ReadAllText("$pwd\haproxy.cfg")
docker-machine ssh manager "printf '%s' '$haproxycfg' | sudo tee /root/haproxy.cfg"


# Redirect all docker commands to manager node
docker-machine env manager | Invoke-Expression

$workernodes = "worker1", "worker2", "worker3"
foreach ($node in $workernodes)
{
	docker node update --label-add type=mvc $node
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

$managerip = docker-machine ip manager
docker container run -d --name loadbalancer -v "/root/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg" --add-host manager:$managerip -p 80:80 haproxy:1.7.0
docker logs loadbalancer

docker-machine env -u | Invoke-Expression
