$Nics =$Nics -Detailed

Get-NetIPConfiguration | fl *

$Nics.IPv4DefaultGateway

Get-NetIPAddress

$Nics.Name

Get-NetIPAddress -InterfaceAlias Ethernet -AddressFamily IPv4 | fl *


$OSNics

Get-NetAdapter | fl *

Get-NetIPInterface -AddressFamily IPv4 -Name 

Get-NetIPInterface -AddressFamily IPv4 -InterfaceAlias Ethernet | Select-Object DHCP

Get-NetIPInterface -AddressFamily IPv4 -InterfaceAlias Ethernet | fl *

Get-NetIPConfiguration -InterfaceAlias "Ethernet" | fl *

get-netipaddress | where-object {$_.IPAddress -eq $ipaddress} | select -ExpandProperty InterfaceIndex
$Log = 'c:\windows\options\gateway\gatewaychange.log'
$gateway = get-netroute -DestinationPrefix '0.0.0.0/0' | select -ExpandProperty NextHop

Get-PSDrive -PSProvider Filesystem | Select-Object Name,


Get-DiskFree 

Get-PSDrive -PSProvider Filesystem | fl *


$OSDisks = Get-PSDrive -PSProvider Filesystem  |
    Select-Object *,
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
    }

    $OSDisks | fl *

$OSDisks_Filtered = $OSDisks | where-object {$_.FreeGB -and $_.UsedGB } |Select-Object Name,SizeGB,UsedGB,FreeGB
$OSDisks_Filtered 