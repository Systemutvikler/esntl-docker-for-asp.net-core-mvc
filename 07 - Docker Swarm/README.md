[Docker swarm tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/)

[Docker Hyper-v driver](https://docs.docker.com/machine/drivers/hyper-v/)


### Running the swarm on Windows 10 Hyper-V with local registry
All commands must be run from an elevated PowerShell console (Run as administrator). Shortcut: Win-X A.

The scripts rely on a hyper-v external switch named "MySwarmExternalSwitch" that is connected to a physical adapter. 
If you are clueless,  create one with the following two PS commands:
```
$netadaptername = $(Get-NetAdapter -Physical | ? Status -eq 'up' | Select-Object -First 1).Name
New-VMSwitch "MySwarmExternalSwitch" -NetAdapterName $netadaptername -AllowManagementOS $true
```
You may alter hyperv-setup.ps1 to use an existing hyper-v switch as log as it is external.
#### Create hyper-v images
Creating the five images may take some time. Issue:
```
.\hyperv-setup.ps1
```
### Create local registry, init db, build/push image, etc.
```
.\manager-setup.ps1
```
Watch out for the last line wich will give you the http address to run the sample. 
Also make sure the log output above do not contain any errors.

#### Cleanup
```
.\hyperv-teardown.ps1
Remove-VMSwitch "MySwarmExternalSwitch"
```
