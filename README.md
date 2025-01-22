# phpIPAM to Homepage
Powershell script to grab hostnames from the phpIPAM API and create a services.yaml for [Homepage](https://gethomepage.dev/)

## How to run

### Option 1: Container

Download the pre-configured container configure the required environment variables and run it.

### Option 2: Run in PowerShell/PowerCLI

Set the environment variables and run the script

**NOTE: Ouput for the services.yaml file is set to /homepage**

## Environment Variables

`$Env:phpIPAMURL`         # Note: The URL should end with a trailing slash

`$Env:AppID` set to the App id in the phpIPAM API via **Administration -> API -> Create API Key**. Create an App id with App security: SSL with App code token. phpIPAMtoHomepage only requires READ permissions.

![screenshot](https://github.com/h0bbel/phpIPAMtoHomepage/raw/master/img/phpipamapi01.png)

`$Env:Token` set to the "App code" created in the phpIPAM API settings.

## Docker Volumes

/homepage should be mapped to a location where [Homepage](https://gethomepage.dev/) can read the services.yaml from.
