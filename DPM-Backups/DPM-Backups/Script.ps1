#	Author: James Tighe
#	DPM-RPToTape.ps1
#	Date: 24/09/2015

CLS
Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
$DPMServers = Get-Content D:\PowerShellScripts\ContentFiles\DPMServers.txt
[array]$DPMArray = @()

	$i = 0
	foreach ($Server in $DPMServers)
	{
		$tempArray = @()
		$tempArray = "" | Select Number, ServerName

		$tempArray.Number = $i
		$tempArray.ServerName = $Server

		$DPMArray += $tempArray
		$i++
	}
Write-Output $DPMArray | FT
Write-Host "Please select the DPM Server to connect to: " -Nonewline
$DPMSelection = Read-Host 
$DPMServer = $DPMServers[$DPMSelection]

#Import MANMON Task Scheduler account credentials
$Cred = Import-Clixml D:\PowerShellScripts\ContentFiles\EncryptedPassword.xml
$Cred.Password = $Cred.Password | ConvertTo-SecureString
$Credential = New-Object System.Management.Automation.PSCredential($Cred.Username, $Cred.Password)

#Initiate connection to required DPM server.
$Session = New-PSSession -ComputerName $DPMServer -Credential $Credential -Authentication Credssp

#Run the main DPM Backup Script
Invoke-Command -Session $Session -FilePath D:\PowerShellScripts\ContentFiles\DPMFunctions.ps1


