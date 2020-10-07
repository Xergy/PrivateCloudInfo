<#
    .SYNOPSIS
        Gathers selected cross subscription Azure configuration details by resource group, and outputs to csv, html, and zip

    .NOTES
        AzureInfo allows a user to pick specific Subs/RGs in out-gridview 
        and export info to CSV and html report.

        It is designed to be easily edited to for any specific purpose.

        It writes temp data to C:\temp. It also zips up the final results.

#>

$ScriptDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 
Set-Location $ScriptDir

#Reload AzureInfo Module
If (get-module AzureInfo) {Remove-Module AzureInfo}
Import-Module .\Modules\AzureInfo

#if not logged in to Azure, start login
if ($Null -eq (Get-AzContext).Account) {
Connect-AzAccount -Environment AzureUSGovernment | Out-Null}

#region Build Config File
$subs = Get-AzSubscription | Out-GridView -OutputMode Multiple -Title "Select Subscriptions"
$RGs = @()

foreach ( $sub in $subs )
{

    Set-AzContext -SubscriptionId $sub.SubscriptionId | Out-Null
    
    $SubRGs = Get-AzResourceGroup |  
        Select-Object *,
            @{N='Subscription';E={
                    $sub.Name
                }
            },
            @{N='SubscriptionId';E={
                    $sub.Id
                }
            } |        
        Out-GridView -OutputMode Multiple -Title "Select Resource Groups"

    foreach ( $SubRG in $SubRGs )
    {

    $RGs = $RGS + $SubRg

    }
}

#endregion

Get-AzureInfo -Subscription $Subs -ResourceGroup $RGs -LocalPath "C:\temp" 

