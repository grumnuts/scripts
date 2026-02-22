# Checks for udpates in the background while LucidLink is running then schedules a task to install udpate on next logon

# Function to display message box
Add-Type -AssemblyName System.Windows.Forms
function Show-MessageBox {
    param (
        [string]$Message,
        [string]$Title,
        [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )
    return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon)
}

# Function to write a timestamped message to the log
$logFile = "C:\Program Files\Lucid\update.log"
function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"

    try {
        Add-Content -Path $logFile -Value $logEntry
    } catch {
        Write-Host "Failed to write to log: $_"
    }
}

Write-Log "Starting Lucid update check..."

# Check for updates
try {
    $updateCheck = & "C:\Program Files\Lucid\resources\lucid.exe" update --check 2>&1
    Write-Log "Update check completed."
} catch {
    Write-Log "Update check failed: $_, exiting."
    exit 1
}

if ($updateCheck | Select-String -Pattern "There is a newer version available.") {
# --- 3. Parse versions for display ---
$installedLine = $updateCheck | Select-String "Installed version"
$latestLine    = $updateCheck | Select-String "Latest version"

if (-not $installedLine -or -not $latestLine) {
    Write-Log "Could not parse version information from update check, exiting."
    exit 1
}

$installed = $installedLine.ToString().Split(":")[1].Trim()
$latest    = $latestLine.ToString().Split(":")[1].Trim()
	Write-Log "Installed version: $installed"
    Write-Log "Available version: $latest, Proceeding with download..."
} else {
    Write-Log "Lucidlink not running or no update available. Exiting."
    exit 0
}

# Download update
try {
    $downloadOutput = & "C:\Program Files\Lucid\resources\lucid.exe" update --download 2>&1
    Write-Log "Download completed."
} catch {
    Write-Log "Download failed: $_, exiting"
    exit 1
}

# Extract the MSI path safely
$msiPathLine = $downloadOutput | Select-String -Pattern "File downloaded:"
if (-not $msiPathLine) {
    Write-Log "MSI path not found in download output, exiting."
    exit 1
}

$msiPath = ($msiPathLine.ToString() -replace "^.*File downloaded:\s*", "").Trim()
Write-Log "MSI path: $msiPath"

if (-not (Test-Path $msiPath)) {
    Write-Log "Downloaded MSI file not found at path: $msiPath, exiting"
    exit 1
}

# Prompt user to update
$msg = "A new version of LucidLink is available, update now?`n`nUpdating will restart LucidLink."
$response = Show-MessageBox $msg "LucidLink Update" YesNo Question

if ($response -ne [System.Windows.Forms.DialogResult]::Yes) {
    # Create scheduled task to install on next startup
    $action1 = New-ScheduledTaskAction -Execute "msiexec.exe" -Argument "/i `"$msiPath`" /qn /norestart"
    $action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument 'Unregister-ScheduledTask -TaskName "LucidLinkUpdate" -Confirm:$false'
    Register-ScheduledTask -TaskName "LucidLinkUpdate" -Action @($action1, $action2) -Trigger (New-ScheduledTaskTrigger -AtLogon) -RunLevel Highest -User "SYSTEM"
    Write-Log "User declined update, scheduled for next logon"
    exit 0 
}

# User clicked "Yes", install update now
Stop-Process -Name LucidApp -ErrorAction SilentlyContinue
$installResult = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait -PassThru
if ($installResult.ExitCode -ne 0) {
    Show-MessageBox "LucidLink update failed during installation.`nExit Code: $($installResult.ExitCode)" "LucidLink Update" OK Error
    Start-Process "C:\Program Files\Lucid\LucidApp.exe"
    Write-Log "Update failed, exiting"
    exit 1
}
Write-Log "Update successful, starting LucidLink"
Start-Process "C:\Program Files\Lucid\LucidApp.exe"

# Notify User
Show-MessageBox "LucidLink has been updated successfully to version $latest." "LucidLink Update Complete"