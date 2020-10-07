<#
    .SYNOPSIS
        Run Server OS Info Focused Script Blocks with Thottled Jobs
#>

$Servers = Import-Csv -Path "Servers.csv" # Reqiures "ComputerName" Property

$HostInput = Read-Host "Filter Servers (Y,N)"
If ($HostInput -eq "Y") {
    $Servers = $Servers | Out-Gridview -Title "Select Servers to Filter..." -OutputMode Multiple
}

If (!$Servers ) {
    Write-host "No Servers Found Exiting!"
}

$HostInput = Read-Host "$($Servers.count) Servers Selected, Proceed (Y,N)"
If ($HostInput -ne "Y") {
    Write-host "Exiting!"
    Exit
}

# Start Timer
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()

$NowString = (get-date -Format s) -replace ":","."

$maxConcurrentJobs = 4 

$Jobs = @()

foreach($Server in $Servers) { #Where $Objects is a collection of objects to process. It may be a computers list, for example.
    Write-Host "$(get-date -Format s) Processing $($Server.ComputerName)..."
    $Check = $false #Variable to allow endless looping until the number of running jobs will be less than $maxConcurrentJobs.
    while ($Check -eq $false) {
        if ((Get-Job -State 'Running').Count -lt $maxConcurrentJobs) {
            $ScriptBlock = {
                Param($Server)                

                $RemoteScript = {
                    Param($Server)
                
                    $ConfigLabel = "PrivateCloudInfo"
                
                    $Nics = @()
                    $Disks = @()
                
                    Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Processing Info for $($Server) Nics" 
                    $Nics = Get-NetIPConfiguration -Detailed |
                        Select-Object *,
                        @{N='Name';E={
                            $_.InterfaceAlias
                            } 
                        },
                        @{N='Description';E={
                                $_.InterfaceDescription
                                } 
                        },
                        @{N='IPAddress';E={
                            $_.IPv4Address[0]
                            } 
                        },
                        @{N='Mac';E={
                            (Get-NetAdapter -Name $_.InterfaceAlias | Select-Object MacAddress | ForEach-Object {$_.MacAddress} )
                            } 
                        },
                        @{N='Status';E={
                            (Get-NetAdapter -Name $_.InterfaceAlias | Select-Object Status | ForEach-Object {$_.Status} )
                            } 
                        },
                        @{N='LinkSpeed';E={
                            (Get-NetAdapter -Name $_.InterfaceAlias  | Select-Object LinkSpeed | ForEach-Object {$_.LinkSpeed} )
                            } 
                        },
                        @{N='ConnectionState';E={
                            (Get-NetAdapter -Name $_.InterfaceAlias  | Select-Object MediaConnectionState | ForEach-Object {$_.MediaConnectionState} )
                            } 
                        },
                        @{N='DriverVersion';E={
                            (Get-NetAdapter -Name $_.InterfaceAlias  | Select-Object DriverVersion | ForEach-Object {$_.DriverVersion} )
                            } 
                        },
                        @{N='DHCPEnabled';E={
                            (Get-NetIPInterface -AddressFamily IPv4 -InterfaceAlias $_.InterfaceAlias | Select-Object DHCP | ForEach-Object {$_.DHCP} )
                            } 
                        },
                        @{N='DNS';E={
                            $_.DNSServer -join ";"
                            } 
                    }
                
                    Write-Verbose "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Processing Info for $($Server) Nics" 
                    $Disks = Get-PSDrive -PSProvider Filesystem  |
                        Select-Object *,
                        @{N='ComputerName';E={
                            $env:computername
                            } 
                        },
                        @{N='UsedGB';E={
                            "{0:#.##}" -f ($_.Used/1GB)
                            } 
                        },
                        @{N='FreeGB';E={
                                "{0:#.##}" -f ($_.Free/1GB)
                                } 
                        },
                        @{N='SizeGB';E={
                            "{0:#.##}" -f (($_.Free+$_.Used)/1GB)
                            } 
                        } | where-object {$_.FreeGB -and $_.UsedGB } 
                
                    #Filtering 
                    $Nics_Filtered = $Nics | Select-Object ComputerName,Name,Description,IPAddress,Mac,Status,LinkSpeed,DriverVersion,DHCPEnabled
                    $Disks_Filtered = $Disks | Select-Object ComputerName,Name,SizeGB,UsedGB,FreeGB        
                
                    $NowStr = (Get-Date -Format s) -replace ":","."
                
                    $Props = @{
                        OSInfo = @{
                            Nics = $Nics_Filtered
                            Disks = $Disks_Filtered
                        }
                        RunTime = $NowStr 
                        ConfigLabel = $ConfigLabel
                    }
                
                    $OSResults = New-Object psobject -Property $Props
                    $RemoteResult = $OSResults
                    $RemoteResult
                
                }
                
                $RemoteResult = Invoke-Command -ComputerName $Server.ComputerName -ScriptBlock $RemoteScript -ArgumentList $Server 
                $RemoteResult             

            }
            Write-Host "$(get-date -Format s) Starting New Job... "
            $JobObject = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Server 
            $Job = "" | Select-Object -Property @{N='ComputerName';E={
                    $Server.ComputerName
                    }
                },
                @{N='Job';E={
                    $JobObject
                    }
                }                
            $Check = $true #To stop endless looping and proceed to the next object in the list.            
        } Else {
            Write-Host "$(get-date -Format s) Waiting for Jobs to finish..."
            Start-Sleep -s 2
        }
     }

     $Jobs += $Job 
}

Write-Host "$(get-date -Format s) Waiting for ALL Jobs to Complete..."
$Jobs | Wait-Job | Out-Null

Write-Host "$(get-date -Format s) Processing ALL Results..."
$JobsResults = $Jobs | ForEach-Object {

    $obj = [PSCustomObject]@{
        Job = $_.Job
        State = $_.Job.State
        Results = $_.Job | Receive-Job
        ComputerName = $_.ComputerName
        }
    
    $obj
}

$NowString = (get-date -Format s) -replace ":","."

$JobsResults | Export-Clixml -Path "$($NowString)_JobsResults.xml"

$JobsResults | ForEach-Object {
    "`n====================================" | Out-File -FilePath "$($NowString)_JobsResultsLogstream.txt" -Append 
    "RemoteServer = $($_.ComputerName)" | Out-File -FilePath "$($NowString)_JobsResultsLogstream.txt" -Append
    "State = $($_.State)" | Out-File -FilePath "$($NowString)_JobsResultsLogstream.txt" -Append     
    "====================================" | Out-File -FilePath "$($NowString)_JobsResultsLogstream.txt" -Append 
    $CurrentResults = $_.Results

    $CurrentResults | ForEach-Object {
        "$($_)" | Out-File -FilePath "$($NowString)_JobsResultsLogstream.txt" -Append 
    }    
}

Write-Host "$(get-date -Format s) Done! Total Elapsed Time: $($elapsed.Elapsed.ToString())" 
$elapsed.Stop()

<#
$JobsResults | ogv
$JobsResults.Results | ogv
$JobsResults.Results.OSInfo.Nics | ogv
$JobsResults.Results.OSInfo.Disks | ogv
#>


