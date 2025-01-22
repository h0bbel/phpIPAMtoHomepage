# phpIPAM to Homepage
Powershell script to grab hostnames from the phpIPAM API and create a services.yaml for [Homepage](https://gethomepage.dev/)

## How to run

### Option 1: Container

Download the pre-configured container configure the required environment variables and run it.

### Option 2: Run in PowerShell/PowerCLI

Set the environment variables and run the script

## Environment Variables

`$Env:phpIPAMURL`         # Note: The URL should end with a trailing slash
`$Env:AppID`
`$Env:Token`

## Volumes

/homepage should be mapped to a location where [Homepage](https://gethomepage.dev/) can read the services.yaml from.
