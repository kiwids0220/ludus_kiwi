# Enroll in Canary Channel via PowerShell (Silent, No User Interaction)
$ErrorActionPreference = 'Stop'

function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Type,
        [object]$Value
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
}

function Delete-RegistryKeys {
    $keys = @(
        "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Account",
        "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Applicability",
        "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Cache",
        "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\ClientState",
        "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI",
        "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Restricted",
        "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\ToastNotification",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\WUMUDCat",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\RingExternal",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\RingPreview",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\RingInsiderSlow",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\RingInsiderFast"
    )
    foreach ($key in $keys) {
        Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
    }

    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "BranchReadinessLevel" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\Setup\WindowsUpdate" -Name "AllowWindowsUpdate" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassRAMCheck" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassSecureBootCheck" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassStorageCheck" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassTPMCheck" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\PCHC" -Name "UpgradeEligibility" -ErrorAction SilentlyContinue
}

function Enroll-CanaryChannel {
    Delete-RegistryKeys

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator" -Name "EnableUUPScan" -Type DWord -Value 1
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\RingExternal" -Name "Enabled" -Type DWord -Value 1
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SLS\Programs\WUMUDCat" -Name "WUMUDCATEnabled" -Type DWord -Value 1

    $applicability = "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Applicability"
    Set-RegistryValue -Path $applicability -Name "EnablePreviewBuilds" -Type DWord -Value 2
    Set-RegistryValue -Path $applicability -Name "IsBuildFlightingEnabled" -Type DWord -Value 1
    Set-RegistryValue -Path $applicability -Name "IsConfigSettingsFlightingEnabled" -Type DWord -Value 1
    Set-RegistryValue -Path $applicability -Name "IsConfigExpFlightingEnabled" -Type DWord -Value 0
    Set-RegistryValue -Path $applicability -Name "TestFlags" -Type DWord -Value 32
    Set-RegistryValue -Path $applicability -Name "RingId" -Type DWord -Value 11
    Set-RegistryValue -Path $applicability -Name "Ring" -Type String -Value "External"
    Set-RegistryValue -Path $applicability -Name "ContentType" -Type String -Value "Mainline"
    Set-RegistryValue -Path $applicability -Name "BranchName" -Type String -Value "CanaryChannel"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" -Name "UIRing" -Type String -Value "External"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" -Name "UIContentType" -Type String -Value "Mainline"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" -Name "UIBranch" -Type String -Value "CanaryChannel"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 3
    Set-RegistryValue -Path "HKLM:\SYSTEM\Setup\WindowsUpdate" -Name "AllowWindowsUpdate" -Type DWord -Value 1
    Set-RegistryValue -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Type DWord -Value 1
    Set-RegistryValue -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassRAMCheck" -Type DWord -Value 1
    Set-RegistryValue -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassSecureBootCheck" -Type DWord -Value 1
    Set-RegistryValue -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassStorageCheck" -Type DWord -Value 1
    Set-RegistryValue -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassTPMCheck" -Type DWord -Value 1
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\PCHC" -Name "UpgradeEligibility" -Type DWord -Value 1
}

# Apply changes and enable flight signing
Enroll-CanaryChannel
Start-Process -FilePath "bcdedit.exe" -ArgumentList "/set {current} flightsigning yes" -WindowStyle Hidden -Wait
Write-Output "Enrollment to Canary Channel applied successfully."