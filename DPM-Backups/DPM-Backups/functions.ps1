Function Menu 
{
	CLS
	Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
	$Global:DPMServer = Read-Host "Please enter DPM Server name"
	#need to add the PSSession script to connect to required server. All scripts should then run under Invoke-Command
	
	Write-Host "Please Select an option. . ." 
	Write-Host `n
	Write-Host "For Tape Inventory type " -NoNewline; Write-Host "1" -ForegroundColor black -backgroundcolor white
	Write-Host "To start backup to tape job type " -NoNewline; Write-Host "2" -ForegroundColor black -backgroundcolor white
	Write-Host "For emergency copy to tape jobs type " -NoNewline; Write-Host "3" -ForegroundColor black -backgroundcolor white

	$input = Read-Host "Enter your selection . . ." 
}


Function LibrarySelection ($libraries)
{
	[array]$libraryArray = @()

	$i = 0
	foreach ($library in $libraries)
	{
		$tempArray = @()
		$tempArray = "" | Select Number, LibraryName

		$tempArray.Number = $i
		$tempArray.LibraryName = $library.UserFriendlyName

		$libraryArray += $tempArray
		$i++
	}

	Write-Output $libraryArray
	Write-Host `n
	Write-Host "Please select a library: " -ForegroundColor Red -BackgroundColor White -NoNewline
	$librarySelect = Read-Host

	While (($librarySelect -gt $libraries.count -1))
	{
		if ($library = " ")
		{
			Write-Host "You have not selected a valid library" -ForegroundColor Red
			Start-Sleep -Seconds 2
			CLS
			Write-Output $libraryArray
			Write-Host `n
			$librarySelect = Read-Host "Please select a library"
		}
	}

	$library = $(Get-DPMLibrary -DPMServername $Global:DPMServer)[$librarySelect]
	Write-Host "You have selected " $libraryArray.UserFriendlyName
	$Global:library = $library
}

Function CopytoTape
{
	$library = $Global:library
	[array]$PGArray = @()
	
	$PGs = Get-ProtectionGroup -DPMServer $Global:DPMServer | Sort Name
		$i = 0
		foreach ($PG in $PGs)
		{
			$tempArray = @()
			$tempArray = "" | Select Number, ProtectionGroup

			$tempArray.Number = $i
			$tempArray.ProtectionGroup = $PG.Name

			$PGArray += $tempArray
			$i++
		}
	Write-Output $PGArray
	Write-Host `n
	Write-Host "Please select a Protection Group. 'Back' to reselect. 'Home' for main menu." -ForegroundColor Red -BackgroundColor White -NoNewline
	$PGSelect = Read-Host 

	if ($PGSelect -eq "Back")
	{
        Write-Host "Copy to Tape Menu"		
	} 
	elseif ($PGSelect -eq "home" -or $PGSelect -eq "menu")
    {
        Write-Host "Main Menu"
    }
    else
	{
		$PG = $PGs[$PGSelect]
	}

	$DSs = Get-DataSource -ProtectionGroup $PG | Sort Name
	foreach ($DS in $DSs)
	{
		$RPs = Get-RecoveryPoint -DataSource $ds | ?{$_.DataLocation -eq "Disk" -and $_.IsIncremental -eq $false}
		$RP = $($RPs | sort BackupTime)[0]
		Write-Host "Backup for " $DS -ForegroundColor Yellow
		Write-Host "on date " $rp.BackupTime -ForegroundColor Red
		Write-Host "Triggering Backup to Tape Job"
		ConfirmSelection ("Confirm emergency backup","Initiates emergency tape backup","Cancel")
		if ($Global:result -eq 0)
		{
		Write-Host "Triggering Backup to Tape Job " $($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)
		#Copy-DPMTapeData $RP -SourceLibrary $library -TapeLabel "$($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)" -TapeOption 2 -TargetLibrary $library
		}
		else 
		{
			Write-Host "Cancelling . . . "
			Start-Sleep -Seconds 3
			CopytoTape
		}
	}
}


Function ConfirmSelection ($title,$YesText, $NoText)
{
	$message = "Are you sure you want to proceed?"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $YesText
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", $NoText
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$result = $Host.UI.PromptForChoice($title, $message, $options, 0)
	$Global:result = $result
}