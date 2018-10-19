# Prosty skrypt do włączania/wyłączania wszystkich bądź wybranej maszyny VM 
param(
    # Type of action for script
    [Parameter(Mandatory)]
    [ValidateSet('On', 'Off')]
    [string]$Action,
    # Name VM
    [string]$NameVM,
    [string]$ResourceGroupName
)

function Create-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )
    return "$(Get-Date);$Message"
}

#$Credential = Add-AzureRmAccount 
#Get-AzureRmAutomationAccount

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $Conn.TenantID `
    -ApplicationID $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint | Out-Null

# Pobranie listy maszyn VM
if ($NameVM) {
    $VMs = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $NameVM -Status
    Create-Log -Message "Get-AzureRMVM;$($VMs.Name);$ResourceGroupName;$($VMs.Statuses[1].DisplayStatus)"
}
else {
    $VMs = Get-AzureRmVM -Status
    $VMs | Foreach {
        Create-Log -Message "Get-AzureRMVM;$($_.Name);$($_.PowerState)"
    }
}

# Wykonanie włączenie/wyłączenia
if ($Action -eq 'Off') {
    $VMs | Stop-AzureRmVM -Force -OutVariable StatusAction | Out-Null
    Create-Log -Message "Stop-AzureRmVM;$($StatusAction.Status)" 

}
elseif ($Action -eq 'On') {
    $VMs | Start-AzureRmVM -OutVariable StatusAction | Out-Null
    Create-Log -Message "Start-AzureRmVM;$($StatusAction.Status)" 
}

# Sprawdzenie stanu po akcji
if ($NameVM) {
    $VMs = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $NameVM -Status
    Create-Log -Message "Get-AzureRMVM;$($VMs.Name);$ResourceGroupName;$($VMs.Statuses[1].DisplayStatus)"
}
else {
    $VMs = Get-AzureRmVM -Status
    $VMs | Foreach {
        Create-Log -Message "Get-AzureRMVM;$($_.Name);$($_.PowerState)"
    }
}

