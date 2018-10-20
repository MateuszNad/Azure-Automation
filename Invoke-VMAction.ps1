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
# W celu testowania skryptu lokalnie z stacji
# Connect-AzureRmAccount | Out-Null

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $Conn.TenantID `
    -ApplicationID $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint | Out-Null

# Pobranie listy maszyn VM
$ErrorActionPreference = 'Stop'
if ($NameVM) {
    try {
        $VMs = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $NameVM -Status
        Create-Log -Message "Get-AzureRMVM;$($VMs.Name);$ResourceGroupName;$($VMs.Statuses[1].DisplayStatus)"
    }
    catch {
        Create-Log -Message "Get-AzureRMVM;$($_.Exception.Message)"
        exit
    }
}
else {
    try {
        $VMs = Get-AzureRmVM -Status
        $VMs | ForEach-Object {
            Create-Log -Message "Get-AzureRMVM;$($_.Name);$($_.PowerState)"
        }
    }
    catch {
        Create-Log -Message "Get-AzureRMVM;$($_.Exception.Message)"
        exit
    }
}

# On/Off
$ErrorActionPreference = 'Continue'
if ($Action -eq 'Off') {
    Foreach($VM in $VMs) {
        $VM | Stop-AzureRmVM -Force -OutVariable StatusAction | Out-Null
        Create-Log -Message "Stop-AzureRmVM;$($VM.Name);$($StatusAction.Status)" 
    }
}
elseif ($Action -eq 'On') {
    Foreach($VM in $VMs) {
        $VM | Start-AzureRmVM -OutVariable StatusAction | Out-Null
        Create-Log -Message "Start-AzureRmVM;$($VM.Name);$($StatusAction.Status)" 
    }
}

# Sprawdzenie stanu VM
if ($NameVM) {
    $VMs = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $NameVM -Status
    Create-Log -Message "Get-AzureRMVM;$($VMs.Name);$ResourceGroupName;$($VMs.Statuses[1].DisplayStatus)"
}
else {
    $VMs = Get-AzureRmVM -Status
    $VMs | ForEach-Object {
        Create-Log -Message "Get-AzureRMVM;$($_.Name);$($_.PowerState)"
    }
}