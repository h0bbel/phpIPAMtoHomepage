# Declare Variables

# TODO:
# * Output files to a specific directory outside of the container
# * Autobuild container
# * How to run it on a schedule? Just make the container run it on startup and then exit? Schedule it externally? or do it like this? https://brendg.co.uk/2022/04/27/dockerizing-a-powershell-script/


$version = "0.0.5"  # Version of the script

# Get variables from environment variables
$BaseURL = $Env:phpIPAMURL + "api/"         # Note: The URL should end with a trailing slash
$AppID = $Env:AppID
$Token = $Env:Token

#Debugging: Check the values of the environment variables
Write-Host "BaseUrl: " $BaseURL
Write-Host "AppID: " $AppID
Write-Host "Token" $Token

# Define the endpoint to get all addresses
$Endpoint = "$BaseURL/$AppID/addresses/"

# Define headers for API authentication
$Headers = @{
    "Content-Type"  = "application/json"
    "token"         = $Token
}

Write-Host "phpIPAM to Homepage v$version" -ForegroundColor Green

# Function to retrieve all addresses
function Get-AllAddresses {
    param (
        [string]$Endpoint
    )

    try {
        # Make the API call to retrieve addresses
        $Response = Invoke-RestMethod -Uri $Endpoint -Headers $Headers -Method Get -SkipCertificateCheck

        if ($Response) {
            Write-Host "Successfully retrieved addresses from $BaseURL." -ForegroundColor Green
            return $Response.data
        } else {
            Write-Host "No data returned from the API." -ForegroundColor Yellow
            return $null
        }
    } catch {
        Write-Host "Failed to retrieve addresses: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to run nmap on the IP address and discover open ports with status output
function Get-NmapOpenPorts {
    param (
        [string]$IpAddress
    )

    try {
        # Output status message to indicate nmap scan is starting
        Write-Host "Starting nmap scan on $IpAddress..." -ForegroundColor Cyan

        # Run nmap to discover only specified open ports (22, 80, 443, 3389)
        $nmapResult = & nmap -p 22,80,443,3389 -T4 $IpAddress 2>&1

        # Display scanning status (e.g., scanning each port)
        $totalPorts = 4  # We are only scanning 4 ports
        $portCounter = 0
        Write-Host "Scanning ports on $IpAddress..." -ForegroundColor Yellow

        # Use a loop to simulate scanning ports and update progress
        foreach ($line in $nmapResult) {
            if ($line -match "open") {
                $portCounter++
                $progress = ($portCounter / $totalPorts) * 100
                Write-Progress -PercentComplete $progress -Status "Scanning $IpAddress" -Activity "Scanning open ports..." 
            }
        }

        # Parse the nmap output to find open ports
        $openPorts = $nmapResult | Select-String -Pattern "open" | ForEach-Object { 
            $_.Line -match "(\d+)/tcp" | Out-Null
            $matches[1] 
        }

        # Display scan completion message
        Write-Host "Nmap scan completed for $IpAddress." -ForegroundColor Green
        Write-Progress -PercentComplete 100 -Status "Scan complete" -Activity "Completed scanning open ports"

        return $openPorts
    } catch {
        Write-Host "Failed to run nmap on ${$IpAddress}: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Function to convert data to YAML format manually
function Convert-ToYaml {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Data,
        [Parameter(Mandatory = $true)]
        [string]$OutputFile,
        [bool]$IncludeOnlyValidHostnames = $false
    )

    try {
        # Filter data if IncludeOnlyValidHostnames is true
        if ($IncludeOnlyValidHostnames) {
            $Data = $Data | Where-Object { $_.hostname -and ($_.hostname -match '^[a-zA-Z0-9.-]+$') }
            Write-Host "Filtered results to include only entries with valid hostnames." -ForegroundColor Green
        }

        # Build YAML content
        $YamlContent = ""
        foreach ($Item in $Data) {
            $YamlContent += "-`n" # Start a new YAML object
            foreach ($Key in $Item.PSObject.Properties.Name) {
                $Value = $Item.$Key
                if ($Value -is [System.Collections.IEnumerable] -and $Value -notlike '*String*') {
                    $YamlContent += "  $($Key):`n"
                    foreach ($SubItem in $Value) {
                        $YamlContent += "    - $($SubItem)`n"
                    }
                } else {
                    $YamlContent += "  $($Key): $($Value)`n"
                }
            }
        }

        # Write the YAML content to the specified file
        Set-Content -Path $OutputFile -Value $YamlContent -Force
        Write-Host "Addresses exported to YAML file: $OutputFile" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to convert to YAML: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to convert discovered hosts to a specific format for services.yaml with dynamic href based on open ports
function Convert-DiscoveredHostsToYaml {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Data,
        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    try {
        # Filter data for valid hostnames
        $DiscoveredHosts = $Data | Where-Object { $_.hostname -and ($_.hostname -match '^[a-zA-Z0-9.-]+$') }

        # Build YAML content for discovered hosts in the requested format
        $YamlContent = "- Discovered Hosts:`n"  # Add dash before the heading
        foreach ($DiscoveredHost in $DiscoveredHosts) {
            # Get open ports using nmap
            $OpenPorts = Get-NmapOpenPorts -IpAddress $DiscoveredHost.ip

            # For each open port, create a separate entry in services.yaml
            foreach ($Port in $OpenPorts) {
                # Add hostname with port appended (e.g., hostname:22)
                $YamlContent += "  - $($DiscoveredHost.hostname):$($Port):`n"
                
                # Determine href based on open ports
                $href = ""
                if ($Port -eq "443") {
                    $href = "https://$($DiscoveredHost.hostname)"
                } elseif ($Port -eq "80") {
                    $href = "http://$($DiscoveredHost.hostname)"
                } elseif ($Port -eq "22") {
                    $href = "ssh://$($DiscoveredHost.hostname)"
                } elseif ($Port -eq "3389") {
                    $href = "rdp://$($DiscoveredHost.hostname)"
                }

                # Add href with additional indentation (four spaces total)
                if ($href) {
                    $YamlContent += "      href: $href`n"
                    
                    # Add icon based on open port
                    if ($Port -eq "22") {
                        $YamlContent += "      icon: mdi-ssh`n"
                    } elseif ($Port -eq "443") {
                        $YamlContent += "      icon: mdi-web`n"
                    } elseif ($Port -eq "3389") {
                        $YamlContent += "      icon: mdi-remote-desktop`n"
                    } elseif ($Port -eq "80") {
                        $YamlContent += "      icon: mdi-web`n"
                    }
                }
            }
        }

        # Write the YAML content for services.yaml to the specified file
        Set-Content -Path $OutputFile -Value $YamlContent -Force
        Write-Host "Discovered Hosts exported to $OutputFile file" -ForegroundColor Green
    } catch {
        Write-Host "Failed to convert to services.yaml: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Call the function to get all addresses
$Addresses = Get-AllAddresses -Endpoint $Endpoint

# Debugging: Check the content of $Addresses
if ($null -eq $Addresses -or $Addresses.Count -eq 0) {
    Write-Host "No addresses were retrieved. Exiting." -ForegroundColor Yellow
    return
}

# Export discovered hosts to a services.yaml file
$ServicesYamlOutputFile = "services.yaml" # Add proper path?
Convert-DiscoveredHostsToYaml -Data $Addresses -OutputFile $ServicesYamlOutputFile 

# Finish!
Write-Host "Script execution completed 🎉" -ForegroundColor Green
