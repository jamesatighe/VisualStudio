Function DPMMenu
{
	CLS
	Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
	$Global:DPMServer = Read-Host "Please enter DPM Server name"
    Connect-DPMServer -DPMServerName $Global:DPMServer
	#need to add the PSSession script to connect to required server. All scripts should then run under Invoke-Command
}
Function Menu
{
	CLS
	Write-Host "Please Select an option. . ." 
	Write-Host `n
	Write-Host "For Tape Inventory type " -NoNewline; Write-Host "1" -ForegroundColor black -backgroundcolor white
	Write-Host "To start backup to tape job type " -NoNewline; Write-Host "2" -ForegroundColor black -backgroundcolor white
	Write-Host "For emergency copy to tape jobs type " -NoNewline; Write-Host "3" -ForegroundColor black -backgroundcolor white

	$Global:Choice = Read-Host "Enter your selection . . ." 

}

Function LibrarySelection
{
    CLS
	[array]$libraryArray = @()
    $libraries = Get-DPMLibrary
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

	Write-Output $libraryArray | FT
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

	$library = $(Get-DPMLibrary -DPMServername)[$librarySelect]
	Write-Host "You have selected " $library.UserFriendlyName
	$Global:library = $library
}

Function CopytoTape
{
    CLS
	$library = $Global:library
	[array]$PGArray = @()
	[array]$RPArray = @()
	
	$PGs = Get-ProtectionGroup | Sort Name
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
	Write-Output $PGArray | FT
	Write-Host `n
	$PGSelect = Read-Host "Please select a Protection Group. 'Home' for main menu "

	if ($PGSelect -eq "Back")
	{
        Write-Host "Returning to Protection Group Selection . . ."	
        Start-Sleep -seconds 2
        CopytoTape
	} 
	elseif ($PGSelect -eq "home" -or $PGSelect -eq "menu")
    {
        Write-Host "Returning to Main Menu . . ."
        Disconnect-DPMServer
        Start-Sleep -Seconds 2
        Menu
    }
    elseif ($PGSelect -notmatch "[0-9]")
	{
		Write-Host "You must enter a valid number" -Foregroundcolor Red -BackgroundColor White
		Start-Sleep -Seconds 2
		CopytoTape
	}
	else 
	{
		
		$PG = $PGs[$PGSelect]
	}

	Write-Host "To automatically backup the oldest avaiable backup type 'Auto' or type continue: " -NoNewline
	$Autoselect = Read-Host
	
	$DSs = Get-DataSource -ProtectionGroup $PG | Sort Name
	foreach ($DS in $DSs)
	{
		$RPs = Get-RecoveryPoint -DataSource $ds | ?{$_.DataLocation -eq "Disk" -and $_.IsIncremental -eq $false} | Sort BackupTime
		$i = 0
		foreach ($RP in $RPs)
		{
			$tempArray = @()
			$tempArray = "" | Select Number, Name, Datasource, BackupTime

			$tempArray.Number = $i
			$tempArray.Name = $PG.Name
			$tempArray.Datasource = $RP.DataSource
			$tempArray.BackupTime = $RP.BackupTime

			$RPArray += $tempArray
			$i++
		}
		if ($Autoselect -eq "auto")
		{
			$RP = ($RPArray | Sort BackupTime)[0]
			Write-Host "Backup for " $DS -ForegroundColor Yellow -NoNewline; Write-Host " on date " $rp.BackupTime -ForegroundColor Red
			#Write-Host "Triggering Backup to Tape Job"
			$YesText = "Do wish to proceed with emergency backup?"
			$NoText = "Cancel"
			ConfirmSelection ("Confirm emergency backup")
			if ($Global:result -eq 0)
			{
				Write-Host "Triggering Backup to Tape Job " $($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)
				#Copy-DPMTapeData $RP -SourceLibrary $library -TapeLabel "$($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)" -TapeOption 2 -TargetLibrary $library
			}
			else 
			{
				Write-Host "Cancelling . . . "
				Start-Sleep -Seconds 3
				#CopytoTape
			}

		}
		else
		{
			
			Write-Output $RPArray
			$RPSelect = Read-Host "Select backup point. . (Enter back to return to previous menu)"

			if ($RPSelect -eq "back")
			{
				Write-Host "Returning to Protection Group Selection . . ."	
				Start-Sleep -seconds 2
				CopytoTape
			} 
			#elseif ($RPSelect -eq "multiple")
			#{
			#	$MultipleRP = @()
			#	$MultipleRP = Read-Host "Select which Recovery Points to use separate with comma"
			#	$MultipleRP = $MultipleRP.Split(",")
			#	Write-Host $MultipleRP.count

			#	foreach ($Point in $MultipleRP)
			#	{
			#		$RP = $RPS[$Point]
			#		Write-Host "Backup for " $DS -ForegroundColor Yellow -NoNewline; Write-Host " on date " $RP.BackupTime -ForegroundColor Red
			#		#Write-Host "Triggering Backup to Tape Job"
			#		$YesText = "Do wish to proceed with emergency backup?"
			#		$NoText = "Cancel"
			#		ConfirmSelection ("Confirm emergency backup")
			#		if ($Global:result -eq 0)
			#		{
			#			Write-Host "Triggering Backup to Tape Job " $($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)
			#			#Copy-DPMTapeData $RP -SourceLibrary $library -TapeLabel "$($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)" -TapeOption 2 -TargetLibrary $library
			#		}
			#		else 
			#		{
			#			Write-Host "Moving to next Recovery Point . . ."
			#			Start-Sleep -Seconds 1
			#			#CopytoTape
			#		}
			#	}
			#}
			else
			{
				$RP = $RPs[$RPSelect]
			}
			Write-Host $RP.count
			Write-Host "Backup for " $DS -ForegroundColor Yellow -NoNewline; Write-Host " on date " $rp.BackupTime -ForegroundColor Red
			#Write-Host "Triggering Backup to Tape Job"
			$YesText = "Do wish to proceed with emergency backup?"
			$NoText = "Cancel"
			ConfirmSelection ("Confirm emergency backup")
			if ($Global:result -eq 0)
			{
				Write-Host "Triggering Backup to Tape Job " $($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)
				#Copy-DPMTapeData $RP -SourceLibrary $library -TapeLabel "$($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)" -TapeOption 2 -TargetLibrary $library
			}
			else 
			{
				Write-Host "Cancelling . . . "
				Start-Sleep -Seconds 3
				#CopytoTape
			}
		}
	}
}


Function ConfirmSelection ([string]$title,[string]$YesText, [string]$NoText)
{
	$message = "Are you sure you want to proceed?"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $YesText
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", $NoText
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$result = $Host.UI.PromptForChoice($title, $message, $options, 0)
	$Global:result = $result
}