### Retrieves all shared mailboxes and exports their SMTP address/display name to CSV

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com -ShowProgress $true

# Get all shared mailboxes
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox

# Initialize an array to store the results
$results = @()

# Loop through each shared mailbox and add to the results
foreach ($mailbox in $sharedMailboxes) {
    $results += [PSCustomObject]@{
        SharedMailbox = $mailbox.PrimarySmtpAddress
        DisplayName = $mailbox.DisplayName
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "C:\temp\SharedMailboxes.csv" -NoTypeInformation

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false

Write-Output "Audit completed. The results are saved in SharedMailboxes.csv"
