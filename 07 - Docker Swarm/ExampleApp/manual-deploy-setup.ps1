# run after hyperv-setup.ps1, see ./dotnetcore2.0-migration.md
$exampleappimagename = "myswarmregistry:5000/exampleapp:swarm-1.0"
$managerip = docker-machine ip manager

# Redirect all docker commands to manager VM
docker-machine env manager | Invoke-Expression

docker network create -d overlay swarm_backend

# --detach=false means the script waits until the command is done. Obvious choise here, next command can't run unless this one succeedes.
echo "======> Setting up mysql service. Could take some time ..."
docker service create --detach=false --name mysql --mount type=volume,source=productdata,destination=/var/lib/mysql --constraint "node.hostname == dbhost" --replicas 1 --network swarm_backend -e MYSQL_ROOT_PASSWORD=mysecret -e bindaddress=0.0.0.0 mysql:8.0.0
#docker service logs --tail 5 mysql

echo "======> Initializing database on dbhost:3306"
docker service update --detach=false --publish-add 3306:3306 mysql
$Env:INITDB = "true"
$Env:DBHOST = $(docker-machine ip dbhost)
dotnet run
Remove-Item Env:\DBHOST
Remove-Item Env:\INITDB
docker service update --detach=false --publish-rm 3306:3306 mysql

# BUG in docker 17.10 "Unable to complete atomic operation, key modified" Solved: Git issue. crlf in files copied to boot2docker
echo "======> Creating mvcapp service. "
docker -D service create --detach=false --name mvcapp --constraint "node.labels.type==mvc" --replicas 5 --network swarm_backend -p 3000:80 -e DBHOST=mysql $exampleappimagename
#docker service logs --tail 5 mvcapp

echo "======> Setting up loadbalancer"
docker pull haproxy:1.7.0
docker container run -d --name loadbalancer -v "/etc/docker/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg" --add-host manager:$managerip -p 80:80 haproxy:1.7.0

echo "======> loadbalancer logs"
docker logs --tail 5 loadbalancer

echo "======> Detaching from active machine manager. To reattach issue: docker-machine env manager | iex"
docker-machine env -u | Invoke-Expression

echo "======> done"
echo "======> You may now browse to http://$managerip"
