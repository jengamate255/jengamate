# Check CPU virtualization support
$cpu = Get-WmiObject -Class Win32_Processor
$isVTxEnabled = $cpu.VirtualizationFirmwareEnabled
$isVTxSupported = $cpu.VirtualizationFirmwareEnabled -ne $null

# Check if Hyper-V is enabled
$hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
$isHyperVEnabled = $hyperV.State -eq 'Enabled'

# Check if Windows Hypervisor Platform is enabled
$hyperVPlatform = Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -ErrorAction SilentlyContinue
$isHyperVPlatformEnabled = $hyperVPlatform.State -eq 'Enabled'

# Check if HAXM is installed
$haxmService = Get-Service -Name "intelhaxm" -ErrorAction SilentlyContinue
$isHAXMInstalled = $haxmService -ne $null

# Output results
Write-Host "=== Virtualization Support Check ==="
Write-Host "CPU Virtualization Supported: $($isVTxSupported)"
Write-Host "CPU Virtualization Enabled: $($isVTxEnabled)"
Write-Host "Hyper-V Installed: $($isHyperVEnabled)"
Write-Host "Windows Hypervisor Platform: $($isHyperVPlatformEnabled)"
Write-Host "HAXM Service Installed: $($isHAXMInstalled)"
