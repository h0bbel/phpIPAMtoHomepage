# phpIPAM to Homepage
Powershell script to grab hostnames from the phpIPAM API and create a services.yaml for [Homepage](https://gethomepage.dev/)

## How to run

### Option 1: Container

Download the pre-configured container, configure the required environment variables and run it. The container exits after it's finished.

### Option 2: Run in PowerShell/PowerCLI

Set the environment variables and run the script

**NOTE: Ouput for the services.yaml file is set to /homepage**

## Environment Variables

`$Env:phpIPAMURL` set to the URL for [phpIPAM](https://phpipam.net/) instance.

**Note: The URL must end with a trailing slash**

`$Env:AppID` set to the App id created in the phpIPAM API via **Administration -> API -> Create API Key**. Create an App id with App security: SSL with App code token. phpIPAMtoHomepage only requires READ permissions.

![screenshot](https://github.com/h0bbel/phpIPAMtoHomepage/blob/main/img/phpipamapi01.png)

`$Env:Token` set to the "App code" created in the phpIPAM API settings.

### Example

docker run -e phpIPAMURL=http://phpipam.example.com -e AppID=myAppID -e Token=123456 {container}

## Docker Volumes

/homepage should be mapped to a location where this container can write the services.yaml file to, and [Homepage](https://gethomepage.dev/) can read it from.

