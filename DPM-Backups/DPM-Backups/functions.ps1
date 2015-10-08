#########################################
#	Initial DPM Server Function     #
#########################################
Function DPMMenu
{
	CLS
	Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
	$Global:DPMServer = Read-Host "Please enter DPM Server name"
    	Connect-DPMServer -DPMServerName $Global:DPMServer
	#need to add the PSSession script to connect to required server. All scripts should then run under Invoke-Command
}

#########################################
#	Main Menu Function		#
#########################################
Function Menu
{
	CLS
	Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
	Write-Host "Please Select an option. . ." 
	Write-Host `n
	Write-Host "For Tape Inventory type " -NoNewline; Write-Host "1" -ForegroundColor black -backgroundcolor white
	Write-Host "To start backup to tape job type " -NoNewline; Write-Host "2" -ForegroundColor black -backgroundcolor white
	Write-Host "For emergency copy to tape jobs type " -NoNewline; Write-Host "3" -ForegroundColor black -backgroundcolor white
	Write-Host "To see last Tape Backups type " -NoNewline; Write-Host "4" -ForegroundColor Black -BackgroundColor White

	$Global:Choice = Read-Host "Enter your selection" 
	
	#Run Library Inventory
	if ($Choice -eq "1")
	{
	LibrarySelection
	Start-DPMLibraryInventory -DPMLibrary $library -DetailedInventory -whatif
	Write-Host "Tape inventory started for library " $library.UserFriendlyName -ForegroundColor Black -BackgroundColor White
	Start-Sleep -Seconds 2
	menu
	}
	#Run Standard Backups to Tape
	elseif ($choice -eq "2")
	{
		CLS
		Write-Host "Standard Backup to Tape Recovery Points" -ForegroundColor Black -BackgroundColor White
		Write-Host "This is trigger normal DPM Backup to Tape jobs"
		Start-Sleep -Seconds 2
		LibrarySelection
		BackuptoTape
	}
	elseif  ($Choice -eq "3")
	{
		CLS
		Write-Host "Emergency Tape Backup" -ForegroundColor Black -BackgroundColor White
		Write-Host "This will copy a specified recovery point onto tape"
		Write-Host "For emergency purposes only. For normal backups use other backup option" -ForegroundColor Red
		Start-Sleep -Seconds 2
		LibrarySelection
		CopytoTape

	}
	elseif  ($Choice -eq "4")
	{
		CLS
		Write-Host "Tape Backup Information" -ForegroundColor Black -BackgroundColor White
		Write-Host "This will display the last Tape Backup for each datasource"
		Start-Sleep -Seconds 2
		LastTapeBackup

	}
	elseif ($Choice -eq "home")
	{
		DPMenu
	}
	
}

#########################################
#	Get Library Function		#
#########################################
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
	Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
	Write-Output $libraryArray | FT
	Write-Host `n
	Write-Host "Please select a library: "  -NoNewline
	$librarySelect = Read-Host

	While (($librarySelect -gt $libraries.count -1))
	{
		if ($library = " ")
		{
			Write-Host "You have not selected a valid library" -ForegroundColor Red
			Start-Sleep -Seconds 2
			CLS
			Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
			Write-Output $libraryArray | Select Number, LibraryName
			Write-Host `n
			$librarySelect = Read-Host "Please select a library"
		}
	}

	$library = $(Get-DPMLibrary -DPMServername $DPMServerName)[$librarySelect]
	Write-Host "You have selected " $library.UserFriendlyName
	$Global:library = $library
}

#########################################
#	Copy to Tape Function		#
#########################################
Function CopytoTape
{
    CLS
	$library = $Global:library
	[array]$PGArray = @()
	
	#Create Protection Group selection array
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
	Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
	Write-Output $PGArray | FT
	Write-Host `n
	$PGSelect = Read-Host "Please select a Protection Group. 'Home' for main menu "

	#Various options
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
	# If selection does not include any of the above or a number then request.
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

	# Set autoselect and autoconfirm variables.
	Write-Host "To automatically backup the oldest avaiable backup type 'Auto' or type continue: " -NoNewline
	$Autoselect = Read-Host
	Write-Host "To auto confirm the backups type 'Yes'" -NoNewline
	$autoconfirm = Read-Host
	
	#Loop through each Datasource to select the relevant Recovery Points.
	$DSs = Get-DataSource -ProtectionGroup $PG | Sort Name
	foreach ($DS in $DSs)
	{
		[array]$RPArray = @()
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
		# Code to auto select the oldest Recovery Point available if required.
		if ($Autoselect -eq "auto")
		{
			$RP = ($RPs | Sort BackupTime)[0]
			Write-Host "Backup for " $DS -ForegroundColor Yellow -NoNewline; Write-Host " on date " $rp.BackupTime -ForegroundColor Red
			if ($autoconfirm -match "yes")
			{
				$Global:result = 0
			}
			else 
			{
				ConfirmSelection ("Confirm emergency backup")
			}
			if ($Global:result -eq 0)
				{
					Write-Host "Triggering Backup to Tape Job " $($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)
					
					Copy-DPMTapeData $RP -SourceLibrary $library -TapeLabel "$($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)" -TapeOption 2 -TargetLibrary $library
				}
				else 
				{
					Write-Host "Skipping Recovery Point . . . "
				}
			}
		# If auto select is not selected then give user options to choice
		else
		{
			Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
			Write-Output $RPArray | FT
			$RPSelect = Read-Host "Select backup point. . (Enter back to return to previous menu)"

			if ($RPSelect -eq "back")
			{
				Write-Host "Returning to Protection Group Selection . . ."	
				Start-Sleep -seconds 2
				CopytoTape
			} 
			else
			{
				$RP = $RPs[$RPSelect]
			}
			Write-Host $RP.count
			Write-Host "Backup for " $DS -ForegroundColor Yellow -NoNewline; Write-Host " on date " $rp.BackupTime -ForegroundColor Red
			#Write-Host "Triggering Backup to Tape Job"
			if ($autoconfirm -match "yes")
			{
				$Global:result = 0
			}
			else 
			{
				ConfirmSelection ("Confirm emergency backup")
			}
			if ($Global:result -eq 0)
			{
				Write-Host "Triggering Backup to Tape Job " $($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)
				Copy-DPMTapeData $RP -SourceLibrary $library -TapeLabel "$($DS.Computer + "\" + $DS.Name + " " + $RP.BackupTime)" -TapeOption 2 -TargetLibrary $library
			}
			else 
			{
				Write-Host "Cancelling . . . "
				Start-Sleep -Seconds 2
			}
		}
	}
	CopytoTape
}


#########################################
#	Confirm Selection Function	#
#########################################
Function ConfirmSelection ([string]$title,[string]$YesText, [string]$NoText)
{
	$message = "Are you sure you want to proceed?"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $YesText
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", $NoText
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$result = $Host.UI.PromptForChoice($title, $message, $options, 0)
	$Global:result = $result
}

#########################################
#	Backup to Tape Function	        #
#########################################
Function BackuptoTape 
{
	CLS
	$library = $Global:library
	[array]$PGArray = @()
	
	#Create Protection Group selection array
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
	Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
	Write-Output $PGArray | FT
	Write-Host `n
	$PGSelect = Read-Host "Please select a Protection Group. 'Home' for main menu, 'All' to trigger backups for all Protection Groups"

	#Various options
	if ($PGSelect -eq "Back")
	{
        Write-Host "Returning to Protection Group Selection . . ."	
        Start-Sleep -seconds 2
        BackuptoTape
	} 
	elseif ($PGSelect -eq "home" -or $PGSelect -eq "menu")
    {
        Write-Host "Returning to Main Menu . . ."
        Disconnect-DPMServer
        Start-Sleep -Seconds 2
        Menu
    }

	elseif ($PGSelect -match "All")
	{
		Foreach ($PG in $PGS)
		{
			ConfirmSelection("Backup all Protection Groups and Members?")
			if ($Global:result -eq 0)
			{
				foreach ($PG in $PGS)
				{
					$DSs = Get-Datasource -ProtectionGroup $PG
					foreach ($DS in $DSs)
					{
						#$j = New-RecoveryPoint -Datasource $DS -Tape -ProtectionType Longterm
						#Write-Host "Triggered Backup to Tape for datasource " $j.DataSources " from Protection Group " $j.ProtectionGroupName
						Write-Host "TEST  (All PG and Members) Triggering backup for" $DS.Computer\$DS.Name 
						Start-Sleep -Seconds 2
					}
				}
			}
			else
			{
				Write-Host "Cancelling . . ."
				BackuptoTape
			}
		}
		Write-Host "All Protection Group Members scheduled for Tape backups . . ."
		Start-Sleep -Seconds 2
		Menu
	}
	# If selection does not include any of the above or a number then request.
    elseif ($PGSelect -notmatch "[0-9]")
	{
		Write-Host "You must enter a valid number" -Foregroundcolor Red -BackgroundColor White
		Start-Sleep -Seconds 2
		BackuptoTape
	}

	else
	{
		
		$PG = $PGs[$PGSelect]
	}
	Write-Host `n
	Write-Host "Do you wish to automatically backup all members of Protection Group"
	Write-Host $PG.Name "? " -NoNewline
	$BackupSelection = Read-Host
		
	# Run all backups if required
	if ($BackupSelection -match "Yes")
	{
		$DSs = Get-Datasource -ProtectionGroup $PG
		foreach ($DS in $DSs)
		{
			#$j = New-RecoveryPoint -Datasource $DS -Tape -ProtectionType Longterm
			#Write-Host "Triggered Backup to Tape for datasource " $j.DataSources " from Protection Group " $j.ProtectionGroupName
			Write-Host "Backing up " $DS
			Write-Host "TEST  (All backups fro PG) Triggering backup for" $DS.Computer\$DS.Name 
		}
	Write-Host `n
	Write-Host "Tape backups scheduled. Returning to main menu . . ."
	Start-Sleep -Seconds 2
	Menu
	}

	
	else 
	{
		[array]$DSArray = @()
	
		#Create Protection Group selection array
		$DSs = Get-Datasource $PG | Sort Name
		$i = 0
		foreach ($DS in $DSs)
		{
			$tempArray = @()
			$tempArray = "" | Select Number, Name, Computer

			$tempArray.Number = $i
			$tempArray.Name = $DS.Name
			$tempArray.Computer = $DS.Computer

			$DSArray += $tempArray
			$i++
		}
		Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
		Write-Output $DSArray
		Write-Host "Please select the relevant Protection Group Member to backup " -NoNewline
		$DSSelection =	Read-host
		$DS = $DSs[$DSSelection]
		
		#$j = New-RecoveryPoint -Datasource $DS -Tape -ProtectionType Longterm
		#Write-Host "Triggered Backup to Tape for datasource " $j.DataSources " from Protection Group " $j.ProtectionGroupName
		Write-Host "Backing up " $DS
		Write-Host "TEST  (Single PG Member) Triggering backup for" $DS.Computer\$DS.Name 
		
		Write-Host `n
		Write-Host "Tape backups scheduled. Returning to main menu . . ."
		Start-Sleep -Seconds 2
		Menu
	}

}

#########################################
#	Get Last Tape Backup Function   	#
#########################################
Function LastTapeBackup
{
	$DPMServer = ($DPMServerName.Split("."))[0]
	$filename = "TapeList"
	$filepath = "C:\TEMP"
	$file = $filepath+"\"+$filename+$DPMServer+".csv"
	Write-Host "DPM Backup Automation Script" -ForegroundColor Black -BackgroundColor White
	Write-Host "Collecting list of last Tape backup for each Datasource"
	Write-Host "List will be saved to "$file
		
	$DSs = (Get-ProtectionGroup | Sort Name) | Get-Datasource
	$TapeArray = @()
	$i = 0

	foreach ($DS in $DSs) 
	{
		$i++
		$RP = (Get-RecoveryPoint -Datasource $ds | ?{$_.Location -eq "Media"} | Sort Backuptime)[0]
		 
		$obj = New-Object -TypeName PSObject -Property @{
			DatasourceName = $DS.Name
			SourceComputer = $DS.Computer
			BackupTime = $RP.BackupTime
			}
         
		$TapeArray+=$obj
		Write-Progress -Activity "Creating last Tape Backup List" -Status "Percent Complete: " -PercentComplete (($i / $DSs.length) * 100)
	}
	$TapeArray | Sort Name | Export-Csv -Path $file -NoTypeInformation
	Copy $file \\THMANMON01.cobwebmanage.local\C$\TEMP\
	menu
}


$DPMServerName = Hostname
$DPMServerName = $DPMServerName+".cobwebmanage.local"
Disconnect-DPMServer
Connect-DPMServer -DPMServerName $DPMServerName

menu