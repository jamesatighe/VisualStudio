#	Author: James Tighe
#	DOM-RPToTape.ps1
#	Date: 24/09/2015


$libType = Read-Host "Which Library? Quantum or MSL?"
if ($libType -match "Quantum" -or "i500") {
	$libType = "ADIC Scalar i500 Tape Library"
}
elseif ($libType -match "MSL" -or "HP") {
	$libType = "Hewlett Packard MSL G3 Series library (x64 based)"
}
else {
	Write-Host "No such library"
}

$library = Get-DPMLibrary -DPMServer THMANDPM09 | ?{$_.UserFriendlyName -match $libType}

Start-DPMLibraryInventory -DPMLibrary $library -DetailedInventory -whatif

$PGs = Get-ProtectionGroup -DPMServer THMANDPM09


