#### docker-compose up dbinit fail
```
Attaching to exampleapp_dbinit_1
dbinit_1        | /usr/bin/env: 'bash\r': No such file or directory
exampleapp_dbinit_1 exited with code 127
```
#### Solution
Files in node_modules/ are corrupt (contain crlf). Reinstall! This only apply to Windows. Ubuntu 16.04 is fine due to different core.autocrlf setting.
```
npm uninstall wait-for-it.sh@1.0.0
npm install wait-for-it.sh@1.0.0
```
Clean up with "docker-compose down -v" and restart from "docker-compose build". 

This is another reason for not tracking files in wwwroot/lib/ and node_modules/ folders. Make sure they are excluded in .gitignore. Should be that by now, I guess.
