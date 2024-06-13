# DVSI

This repository contains all Information needed for installing the DVSI - System

## Before Installing 

Before you can install the DVSI System the following is needed:

### SwarmGuard Account
You need an SwarmGuard Account with the SwarmGuard App for the System to work. If you don't have any you can sing up here: [https://swarmguard.com/setup-guide/](https://swarmguard.com/setup-guide/)

### DVSI Account
You will also need an DVSI Account, which you can get by contacting me personally. 
You will get a User for the DVSI Authentication Service (https://auth.dvsi.ch/) and also a `username` and an `access token` which is needed for the install-scripts. 

### Docker 
You need to have Docker installed on your device you want to use. You can install Docker by the instructions on this site: [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/).

## Install Media-Server

The Media-Server can be installed on all Linux device with amd64 or arm64 architecture:

You can install the media server with the following command:
```shell
curl -fsSL https://raw.githubusercontent.com/Tandoraz/dvsi/main/install.sh > install.sh && sudo chmod +x install.sh && sudo ./install.sh
```

## Install Gateway
The Gateway can be installed on a Linux device with amd64 architecture. Make sure that the Gateway has a public IP or else it doesn't work.

you can install the gateway with the following command:
```shell
curl -fsSL https://raw.githubusercontent.com/Tandoraz/dvsi/main/install-gateway.sh > install-gateway.sh && sudo chmod +x install-gateway.sh && sudo ./install-gateway.sh
```
