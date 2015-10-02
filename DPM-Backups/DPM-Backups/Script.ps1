#	Author: James Tighe
#	DOM-RPToTape.ps1
#	Date: 24/09/2015

#Load function script (change to script location)
. C:\Users\james.tighe\Documents\GitHubVisualStudio\VisualStudio\DPM-Backups\DPM-Backups\functions.ps1


#Get current library list from DPM
#$libraries = Get-DPMLibrary -DPMServer $DPMServer 

CLS
Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
Write-Host "Please Select an option. . ." 
Write-Host `n
Write-Host "For Tape Inventory type " -NoNewline; Write-Host "1" -ForegroundColor black -backgroundcolor white
Write-Host "To start backup to tape job type " -NoNewline; Write-Host "2" -ForegroundColor black -backgroundcolor white
Write-Host "For emergency copy to tape jobs type " -NoNewline; Write-Host "3" -ForegroundColor black -backgroundcolor white

$input = Read-Host "Enter your selection . . ." 

if ($input -eq "1")
{
    CLS
	LibrarySelection ($libraries)
	Start-DPMLibraryInventory -DPMLibrary $library -DetailedInventory -whatif
	Write-Host "Tape inventory started for library " $library.UserFriendlyName -ForegroundColor Black -BackgroundColor White
}
if  ($input -eq "3")
{
	Write-Host "Emergency Tape Backup" -ForegroundColor Black -BackgroundColor White
	Write-Host "This will copy a specified recovery point onto tape"
	Write-Host "For emergency purposes only. For normal backups use other backup option" -ForegroundColor red
	LibrarySelection ($libraries)
}

$libType = Read-Host "Which Library? Quantum or MSL or QuantumDPM11?"

$DPMServer = Read-Host "Which DPM Server?"

$library = Get-DPMLibrary -DPMServer $DPMServer | ?{$_.UserFriendlyName -match $libType}

#Start-DPMLibraryInventory -DPMLibrary $library -DetailedInventory -whatif

