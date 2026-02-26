###Monitors LucidLink and schedules an update task if a newer version is found

# Path to the log file
$logFile = "C:\Program Files\Lucid\update.log"

# Function to write a timestamped message to the log
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
    Write-Log "Update check failed: $_"
    exit 1
}

if ($updateCheck | Select-String -Pattern "There is a newer version available.") {
    Write-Log "New version available. Proceeding with download..."
} else {
    Write-Log "No update available. Exiting."
    exit 0
}
# Download update
try {
    $downloadOutput = & "C:\Program Files\Lucid\resources\lucid.exe" update --download 2>&1
    Write-Log "Download completed."
} catch {
    Write-Log "Download failed: $_"
    exit 1
}
# Extract the MSI path safely
$msiPathLine = $downloadOutput | Select-String -Pattern "File downloaded:"
if (-not $msiPathLine) {
    Write-Log "MSI path not found in download output."
    exit 1
}
# Extract file path
$msiPath = ($msiPathLine.ToString() -replace "^.*File downloaded:\s*", "").Trim()
Write-Log "MSI path extracted: $msiPath"

# Check if file exists
if (-not (Test-Path $msiPath)) {
    Write-Log "Downloaded MSI file not found at path: $msiPath"
    exit 1
}
# Define task name
$taskName = "LucidLinkUpdate"

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($null -eq $existingTask) {
    # Create scheduled task to install on next startup, deletes itself after run
    $action1 = New-ScheduledTaskAction -Execute "msiexec.exe" -Argument "/i `"$msiPath`" /qn /norestart"
    $action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "Unregister-ScheduledTask -TaskName `"$taskName`" -Confirm:`$false"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName $taskName -Action @($action1, $action2) -Trigger $trigger -RunLevel Highest -User "SYSTEM"
    Write-Log "Update scheduled on next startup."
}
else {
    Write-Log "Scheduled task '$taskName' already exists. Skipping creation."
}