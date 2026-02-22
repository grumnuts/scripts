# Import Active Directory module
Import-Module ActiveDirectory

# Define the output CSV file path
$outputFile = "C:\temp\AD_Users.csv"

# Retrieve all user accounts in the domain
$users = Get-ADUser -Filter * -Property DisplayName, SamAccountName

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
