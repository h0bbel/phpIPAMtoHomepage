# phpIPAM to Homepage

Powershell script to grab hostnames from the phpIPAM API, run [nmap](https://nmap.org/) against those hosts (scanning for port 22/80/443/3389 only) and create a `services.yaml` for [Homepage](https://gethomepage.dev/) with entries for all hosts have those ports open. If a host has more than one open port, one entry per open port is added.

The generated `services.yaml` file can be copied to a running [Homepage](https://gethomepage.dev/) install, thus creating an automated way of adding all known hosts.

## How to run

### Option 1: Container

Download the pre-configured container, configure the required environment variables and run it. The container exits after it's finished, and the result is saved in `services.yaml`

### Option 2: Run in PowerShell/PowerCLI

Set the environment variables and run the script

**NOTE: Ouput for the `services.yaml` file is hard coded to /homepage**. 

## Environment Variables

`$Env:phpIPAMURL` set to the URL for [phpIPAM](https://phpipam.net/) instance.

**Note: The URL must end with a trailing slash**

`$Env:AppID` set to the App id created in the phpIPAM API via **Administration -> API -> Create API Key**. Create an App id with App security: SSL with App code token. phpIPAMtoHomepage only requires READ permissions.

![screenshot](https://github.com/h0bbel/phpIPAMtoHomepage/blob/main/img/phpipamapi01.png)

`$Env:Token` set to the "App code" created in the phpIPAM API settings.

## Docker Volumes

/homepage should be mapped to a location where this container can write the `services.yaml` file, and [Homepage](https://gethomepage.dev/) can read it from.

## Example

`docker run -v .:/homepage -e phpIPAMURL=https://ipam.example.com/api/ -e AppID=chmo-test -e Token=QWDb36x4M893mFBHuQKZyp3WmiOCyeje ghcr.io/h0bbel/phpipamtohomepage:latest`

This runs the container and the generated output `services.yaml` file is saved in the current working directory.
