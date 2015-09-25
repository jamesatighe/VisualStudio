#	Author: James Tighe
#	DOM-RPToTape.ps1
#	Date: 24/09/2015


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

$DSs = @()
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
		Copy-DPMTapeData $RP -SourceLibrary $library -TapeLabel "$($DSs.Computer + "\" + $DS.Name + " " + $RP.BackupTime)" -TapeOption 2 -TargetLibrary -whatif
	}
}







		$RPs = Get-RecoveryPoint -DataSource $ds | ?{$_.DataLocation -eq "Disk" -and $_.IsIncremental -eq $false}

			$RPInfo += New-Object PSObject -Property @{
		DataSource = Get-DataSource -ProtectionGroup $PG
		}

#Need to add Job info.
