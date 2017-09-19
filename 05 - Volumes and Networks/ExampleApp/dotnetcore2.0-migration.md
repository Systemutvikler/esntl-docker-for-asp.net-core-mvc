### Problem
The add migration command from PowerShell and/or Package Manager Console might fail
```
dotnet ef migrations add Initial
Add-Migration Initial
```
with error message
```
MySql.Data.MySqlClient.MySqlException (0x80004005): Unable to connect to any of the specified MySQL hosts.
```

### Solution
Create a self destructing mysql container for development. Note! It could take some time before mysqld is ready for connections. Stop container after you are done with migation comand.
```
docker run -d -p 3306:3306 --rm --name mysql_dev -e MYSQL_ROOT_PASSWORD=mysecret mysql:8.0.0
```

PowerShell diagnostic commands when all is ok:
```
PS>netstat -n -a | findstr ":3306"
  TCP    0.0.0.0:3306           0.0.0.0:0              LISTENING
  TCP    [::1]:3306             [::]:0                 LISTENING

PS>docker logs mysql_dev
.
...removed...
.
2017-09-17T17:23:48.993622Z 0 [Note] mysqld: ready for connections.
Version: '8.0.0-dmr'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server (GPL)
PS>
```

Commands
```
dotnet publish -c Release -o dist
docker build . -t apress/exampleapp -f Dockerfile
docker run -d --name mysql -v productdata:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=mysecret -e bind_address=0.0.0.0 mysql:8.0.0
docker run -d --name productapp -p 3000:80 -e DBHOST=172.17.0.2 apress/exampleapp
docker create --name productapp1 -e DBHOST=mysql -e MESSAGE="1st Server" --network backend apress/exampleapp
docker network connect frontend productapp1
docker start productapp1
Cleanup:

```
Some reflections: 
* Giving the container the same name as the image is a bad idea. E.g mysql.
* "docker start productapp1 productapp2 productapp3" will generate a lot of exceptions as all of the containers will try to create and seed the dabatase if none exists.