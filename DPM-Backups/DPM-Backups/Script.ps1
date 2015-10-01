#	Author: James Tighe
#	DOM-RPToTape.ps1
#	Date: 24/09/2015

#Get current library list from file

$libraries = Get-Content "C:\TEMP\Librarylist.txt"


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
	$DPMServer = Read-Host "Which DPM Server?"
	#$libType = Read-Host "Which Library? Quantum or MSL or Quantum (DPM)?"
    
    while (($libType = Read-Host "Which Library? Quantum or MSL or Quantum (DPM)?") -notin $libraries) 
    {
    Write-Host "No active library found . . "
	Start-Sleep -Seconds 2
	CLS
    }

	if ($libType -match "Quantum" -or "i500") {
		#$libType = "ADIC Scalar i500 Tape Library"
		$libType = "Dell ML6000 Tape Library"
	}
	elseif ($libType -match "MSL" -or "HP") {
		$libType = "Hewlett Packard MSL G3 Series library (x64 based)"
	}
	elseif ($libType -match "DPM") {
		$libType = "Dell ML6000 Tape Library"
	}
	else {
		Write-Host "No such library"
	}

	$library = Get-DPMLibrary -DPMServer $DPMServer | ?{$_.UserFriendlyName -match $libType}

	#Start-DPMLibraryInventory -DPMLibrary $library -DetailedInventory -whatif
}

$libType = Read-Host "Which Library? Quantum or MSL or QuantumDPM11?"

$DPMServer = Read-Host "Which DPM Server?"

if ($libType -match "Quantum" -or "i500") {
	#$libType = "ADIC Scalar i500 Tape Library"
	$libType = "Dell ML6000 Tape Library"
}
elseif ($libType -match "MSL" -or "HP") {
	$libType = "Hewlett Packard MSL G3 Series library (x64 based)"
}
elseif ($libType -match "DPM") {
	$libType = "Dell ML6000 Tape Library"
}
else {
	Write-Host "No such library"
}

$library = Get-DPMLibrary -DPMServer $DPMServer | ?{$_.UserFriendlyName -match $libType}

#Start-DPMLibraryInventory -DPMLibrary $library -DetailedInventory -whatif


$PGs = Get-ProtectionGroup -DPMServer THMANDPM11 | ?{$_.Name -match "THHS2E12BE2X"} | Sort Name

foreach ($PG in $PGs)
{
	$DSs = Get-DataSource -ProtectionGroup $PG | Sort Name
	foreach ($DS in $DSs)
	{
		$RPs = Get-RecoveryPoint -DataSource $ds | ?{$_.DataLocation -eq "Disk" -and $_.IsIncremental -eq $false}
		$RP = $($RPs | sort BackupTime)[0]
		Write-Host "Backup for " $DS -ForegroundColor Yellow
		Write-Host "on date " $rp.BackupTime -ForegroundColor Red
		Write-Host "Triggering Backup to Tape Job"
		Copy-DPMTapeData $RP -SourceLibrary $library -TapeLabel "$($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)" -TapeOption 2 -TargetLibrary $library
	}
}


#To get last datasource can you $DS = $DSS[$($DSS.count)-1] 


#Need to consolidate the library commands into a function that can be called.
