
Function Invoke-AzInfoHcTaskVMMissingTag {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        $VMDetails,
        [parameter(mandatory = $true)]
        $MissingTag
    )
    
    Process {

        $VMMissingTag = $VMDetails | Where-Object {$_.$($MissingTag) -like ""}

        $Props = @{
            TaskShortName = "MissingTag$($MissingTag)"
            TaskName = "VMs Missing Tag $($MissingTag)"
            TaskDescription = "Simple Check on VMs for the existance of a Tag named $($MissingTag)"
            Results = $VMMissingTag
        }
        
        Return (New-Object psobject -Property $Props)

    }
}

