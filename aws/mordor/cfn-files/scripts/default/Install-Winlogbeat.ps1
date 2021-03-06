# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$WinlogbeatConfigUrl
)

$WinlogbeatURL = "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-7.4.0-windows-x86_64.zip"

$OutputFile = Split-Path $WinlogbeatURL -leaf
$ZipFile = "c:\cfn\scripts\$outputFile"

# Download Zipped File
write-Host "Downloading $OutputFile .."
$wc = new-object System.Net.WebClient
$wc.DownloadFile($WinlogbeatUrl, $ZipFile)
if (!(Test-Path $ZipFile)){ write-Host "File $ZipFile does not exists.. "; break }

# Unzip file
write-Host "Decompressing $OutputFile .."
$file = (Get-Item $ZipFile).Basename
expand-archive -path $Zipfile -DestinationPath "C:\Program Files\"
if (!(Test-Path "C:\Program Files\$file")){ write-Host "$ZipFile could not be decompressed successfully.. "; break }

# Renaming Folder & File
write-Host "Renaming folder from C:\Program Files\$file to C:\Program Files\Winlogbeat .."
Rename-Item "C:\Program Files\$file" "C:\Program Files\Winlogbeat" -Force

# Backing up default Winlogbeat configuration
write-Host "Renaming file from C:\Program Files\Winlogbeat\winlogbeat.yml to C:\Program Files\Winlogbeat\winlogbeat.backup .."
Rename-Item "C:\Program Files\Winlogbeat\winlogbeat.yml" "C:\Program Files\Winlogbeat\winlogbeat.backup" -Force

# Download WInlogbeat Config
write-Host "Downloading Winlogbeat config.."
$WinlogbeatFile = "C:\Program Files\Winlogbeat\winlogbeat.yml"
$wc.DownloadFile($WinlogbeatConfigUrl, $WinlogbeatFile)
if (!(Test-Path $WinlogbeatFile)){ write-Host "File $WinlogbeatFile does not exists.. "; break }

# Installing Winlogbeat Service
write-Host "Installing Winlogbeat Service.."
& "C:\Program Files\Winlogbeat\install-service-winlogbeat.ps1"

write-Host "Starting Winlogbeat service.."
Start-Service winlogbeat

write-Host "Verifying if Winlogbeat is running.."
$ServiceName = 'winlogbeat'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    write-host $arrService.status
    write-host 'Service starting'
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host 'Service is now Running'
    }
}
write-Host "Winlogbeat is running.."