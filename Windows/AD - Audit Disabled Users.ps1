### Exports disabled AD user accounts to CSV

# Import Active Directory module
Import-Module ActiveDirectory

# Define the output CSV file path
$outputFile = "C:\temp\Disabled_AD_Users.csv"

# Ensure the output directory exists
$dir = Split-Path -Path $outputFile -Parent
if (-not (Test-Path $dir)) {
    New-Item -Path $dir -ItemType Directory | Out-Null
}

# Retrieve only disabled user accounts in the domain
# Note: Using server-side filter for efficiency
$users = Get-ADUser -Filter 'Enabled -eq $false' -Property DisplayName, SamAccountName

# Create an array to store user details
$userData = foreach ($user in $users) {
    [PSCustomObject]@{
        DisplayName    = $user.DisplayName
        SamAccountName = $user.SamAccountName
    }
}

# Export the data to a CSV file
$userData | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Export complete. CSV file saved to: $outputFile"