#### docker-compose up dbinit fail
```
Attaching to exampleapp_dbinit_1
dbinit_1        | /usr/bin/env: 'bash\r': No such file or directory
exampleapp_dbinit_1 exited with code 127
```
#### Solution
Files in node_modules/ are corrupt. Reinstall! This only apply to Windows. Ubuntu 16.04 is fine due to different core.autocrlf setting.
```
npm uninstall wait-for-it.sh@1.0.0
npm install wait-for-it.sh@1.0.0
```
Clean up with "docker-compose down -v" and restart from "docker-compose build". 

This is another reason for not tracking files in wwwroot/lib/ and node_modules/ folders. Make sure they are excluded in .gitignore.

Tried solving this problem with a .gitattributes file. No luck. Gave up due to lacking documentation, syntax, samples and all of that you are unable to find when you need it. Changing core.autocrlf is a no-no. Save it for another day when someone else is paying for it :-) Today we stick with the John Cleese solution and hope that someone with a PhD in Windoze-Git comes up with a solution.