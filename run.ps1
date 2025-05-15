$script:MSGs = DATA { ConvertFrom-StringData -StringData @'
# English strings
1=Downloading Selected StevenBlack host file
2=Reading downloaded file
3=Getting Header data
4=Clearing text ( Removing comments, empty lines)
5=Writing Header to file 'hosts'
6=Grouping entries together ( 9 per row )
7=Writing entries
8=Entry {0}
NoUAC=Admin Rights required. Re-execute the program with elevated permissions

Yes=Yes
No=No
'@}
Import-LocalizedData -BindingVariable "MSGs" -BaseDirectory "$($PSScriptRoot)\Langs" -FileName "Msgs.psd1" -ErrorAction:SilentlyContinue
Switch (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
	$True {
		Clear-Host
		PUSH-Location $PSScriptRoot
		Write-Host $MSGs.'1'
		curl -L "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts" -o StevenBlack_hosts
		Write-Host $MSGs.'2'
		$OG_file = Get-Content -Path ".\StevenBlack_hosts"
		Write-Host $MSGs.'3'
		$Header = @{}
		$Leer = $true
		$OG_file | ForEach-Object {
			if ($Leer) {
				if ($_ -match "^0\.0\.0\.0" -and $_ -ne "0.0.0.0 0.0.0.0") {
					$Leer = $false
				} else {
					$entry = $_.Trim()
					switch -Regex ($entry){
						"^# Title:\s*(.+)" {
							if (-not $Header["Title"]) {
								$Header["Title"] = ($matches[1] -Split " ")[0].Trim()
							}
						}
						"^# Date:\s*(.+)" { $Header["Date"] = "# Date`t`t`t: $($matches[1])" }
						"^# Extensions added to this file:\s*(.+)" { $Header["Extensions"] = $matches[1] }
						"^# Fetch the latest version of this file:\s*(.+)" { $Header["Latest"] = "# Latest Version`t: $($matches[1])" }
						"^# Project home page:\s*(.+)" { $Header["Project_page"] = "# Github Repo`t`t: $($matches[1])" }
						"^# (http://.+)" { $Header["Personal_page"] = "# OG File Author Page`t: $($matches[1])" }
						"^[0-9A-Fa-f:]" { $Header["Local_Def"] += ,@($entry -Split " ")}
					}
				}
			}
		}
		$HLD_Group = @()
		foreach ($entry in $Header["Local_Def"]) {
			$existingEntry = $HLD_Group | Where-Object { $_[0] -eq $entry[0] }
			if ($existingEntry) { $existingEntry[1] += $entry[1] } else { $HLD_Group += ,@($entry[0], @($entry[1])) }
		}
		$Header["Local_Def"] = $HLD_Group
		$i = 0
		foreach ($line in $OG_file) {
			if ($line -match "^0\.0\.0\.0" -and $line -ne "0.0.0.0 0.0.0.0") {
				break
			}
			$i++
		}
		if ($i -ge 0) {
			$FilteredFile = $OG_file[$i..$OG_file.Length]
		}
		Write-Host $MSGs.'4'
		$CleanFile=@()
		$FilteredFile | ForEach-Object {
			$entry=($_.replace('`t','')).Trim()
			if ($entry -notmatch "^[\t ]*#" -and $entry -ne "") {
				$entry = ($entry -Split "0.0.0.0")[1].Trim()
				if ($entry -match "#"){
					$CleanFile += ($entry -Split "#")[0].Trim()
				} else {
					$CleanFile += $entry
				}
			}
		}
		Remove-Variable OG_file
		Remove-Variable HLD_Group
		Remove-Variable FilteredFile
		Write-Host $MSGs.'5'
		Out-File "hosts" -InputObject "# Title`t`t`t: $($Header["Title"]) ( $($Header["Extensions"]) )"
		Out-File "hosts" -Append -InputObject $Header["Date"]
		Out-File "hosts" -Append -InputObject $Header["Project_page"]
		Out-File "hosts" -Append -InputObject $Header["Latest"]
		Out-File "hosts" -Append -InputObject $Header["Personal_page"]
		Out-File "hosts" -Append -InputObject "# ======================"
		Write-Host $MSGs.'6'
		$i=1
		Write-Host $MSGs.'7'
		for ($x = 0; $x -lt $CleanFile.Count; $x=$x+9) {
			Write-Host $([string]::Format($MSGs.'8', "$i / $([math]::ceiling(($CleanFile.Count) / 9)) ( $( [math]::Round((($i / [math]::ceiling($CleanFile.Count / 9)) * 100),2))% )"))
			$var = "$($CleanFile[$x]) $($CleanFile[$($x+1)]) $($CleanFile[$($x+2)]) $($CleanFile[$($x+3)]) $($CleanFile[$($x+4)]) $($CleanFile[$($x+5)]) $($CleanFile[$($x+6)]) $($CleanFile[$($x+7)]) $($CleanFile[$($x+8)])".Trim()
			if (100 -eq $( [math]::Round((($i / [math]::ceiling($CleanFile.Count / 9)) * 100),2))) {
				Out-File "hosts" -Append -InputObject "0.0.0.0 $($var)" -NoNewline
			} else {
				Out-File "hosts" -Append -InputObject "0.0.0.0 $($var)"
			}
			$i++
		}
		$ACL_Sys = Get-Acl -Path "$([System.Environment]::SystemDirectory)\drivers\etc\hosts"
		$ACL_New = Get-Acl -Path ".\hosts"
		Copy-Item -Path "$([System.Environment]::SystemDirectory)\drivers\etc\hosts" -Destination ".\hosts_BackUp" -Force
		Set-Acl -path ".\hosts_BackUp" -AclObject ($ACL_New)
		Set-Acl -path ".\hosts" -AclObject ($ACL_Sys)
		Copy-Item -Path ".\hosts" -Destination "$([System.Environment]::SystemDirectory)\drivers\etc\hosts" -Force
		Set-Acl -path "$([System.Environment]::SystemDirectory)\drivers\etc\hosts" -AclObject ($ACL_Sys)
		Remove-Variable Header
		Remove-Variable CleanFile
		Remove-Variable i
	}
	$False {
		Write-Host $MSGs.'NoUAC'
	}
}
