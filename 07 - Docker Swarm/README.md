[Docker swarm tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/)

[Docker Hyper-v driver](https://docs.docker.com/machine/drivers/hyper-v/)


### Running the swarm on Windows 10 Hyper-V
All commands must be run from an elevated PowerShell console (Run as administrator). Shortcut: Win-X A.

The scripts rely on a hyper-v external switch named "MySwarmExternalSwitch". If you are clueless,  create one with the two PS commands:
```
$netadaptername = $(Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Select-Object -First(1)).Name
New-VMSwitch "MySwarmExternalSwitch" -NetAdapterName $netadaptername -AllowManagementOS $true
```

#### Create hyper-v images
Creating the five images will take some time. Issue:
```
.\hyperv-setup.ps1
```
### Create local registry, int db, build/push image, etc.
```
.\manager-setup.ps1
```
Watch out for the last line wich will give you the http address to run the sample.

#### Cleanup
```
.\hyperv-teardown.ps1
Remove-VMSwitch "MySwarmExternalSwitch"
```
