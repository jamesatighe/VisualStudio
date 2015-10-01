Function LibrarySelection ($libraries)
{
	[array]$libraryArray = @()

		$i = 1
		foreach ($library in $libraries)
		{
			$tempArray = @()
			$tempArray = "" | Select Number, LibraryName

			$tempArray.Number = $i
			$tempArray.LibraryName = $library

			$libraryArray += $tempArray
			$i++
		}

		Write-Output $libraryArray
		Write-Host `n
		Write-Host "Please select a library" -ForegroundColor Black -BackgroundColor White -NoNewline
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

		switch ($librarySelect)
		{
			0 {$library = $(Get-DPMLibrary -DPMServerName $DPMServer)[0]}
			1 {$library = $(Get-DPMLibrary -DPMServerName $DPMServer)[1]}
			2 {$library = $(Get-DPMLibrary -DPMServerName $DPMServer)[2]}
			3 {$library = $(Get-DPMLibrary -DPMServerName $DPMServer)[3]}
			4 {$library = $(Get-DPMLibrary -DPMServerName $DPMServer)[4]}
			5 {$library = $(Get-DPMLibrary -DPMServerName $DPMServer)[5]}
			6 {$library = $(Get-DPMLibrary -DPMServerName $DPMServer)[6]}
			7 {$library = $(Get-DPMLibrary -DPMServerName $DPMServer)[7]}
		}
$Global:library = $library
}

librarySelection($libraries)