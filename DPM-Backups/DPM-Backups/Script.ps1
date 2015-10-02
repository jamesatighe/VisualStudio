#	Author: James Tighe
#	DOM-RPToTape.ps1
#	Date: 24/09/2015

#Load function script (change to script location)
. C:\TEMP\Scripts\functions.ps1


#Get current library list from DPM
#$libraries = Get-DPMLibrary -DPMServer $DPMServer 

#Run Menu Function
Menu

if ($Choice -eq "1")
{
    CLS
	LibrarySelection ($libraries)
	Start-DPMLibraryInventory -DPMLibrary $library -DetailedInventory -whatif
	Write-Host "Tape inventory started for library " $library.UserFriendlyName -ForegroundColor Black -BackgroundColor White
}
if  ($Choice -eq "3")
{
	Write-Host "Emergency Tape Backup" -ForegroundColor Black -BackgroundColor White
	Write-Host "This will copy a specified recovery point onto tape"
	Write-Host "For emergency purposes only. For normal backups use other backup option" -ForegroundColor red
    Write-Host "Please Select library to use for backup"
	LibrarySelection ($libraries)
    CopytoTape

}


