
$Server = "Localhost"
$ConfigLabel = "PrivateCloudInfo"

$OSNics = @()
$OSDisks = @()

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
    Results = @{
        Nics = $OSNics_Filtered
        Disks = $Disks_Filtered
    }
    RunTime = $NowStr 
    ConfigLabel = $ConfigLabel
}


$OSResults = New-Object psobject -Property $Props
$OSResults

