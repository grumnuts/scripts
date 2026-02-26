### Finds delegates with full access on shared mailboxes and outputs to CSV

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com -ShowProgress $true

# Get all shared mailboxes
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox

# Initialize an array to store the results
$results = @()

# Loop through each shared mailbox and get the delegates
foreach ($mailbox in $sharedMailboxes) {
    $delegates = Get-MailboxPermission -Identity $mailbox.PrimarySmtpAddress | Where-Object { $_.User -ne "NT AUTHORITY\SELF" -and $_.AccessRights -eq "FullAccess" }
    foreach ($delegate in $delegates) {
        $results += [PSCustomObject]@{
            SharedMailbox = $mailbox.PrimarySmtpAddress
            Delegate = $delegate.User
            AccessRights = $delegate.AccessRights
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "C:\temp\SharedMailboxDelegates.csv" -NoTypeInformation

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false

Write-Output "Audit completed. The results are saved in SharedMailboxDelegates.csv"
