docker-machine env manager | Invoke-Expression
docker service rm mvcapp
docker service rm mysql
docker container rm -f loadbalancer
docker container rm -f myswarmregistry
docker network rm swarm_backend
docker-machine env -u | Invoke-Expression
