### Lists all distribution groups and their members to a CSV

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com -ShowProgress $true

# Get all distribution lists
$distributionLists = Get-DistributionGroup

# Initialize an array to store the results
$results = @()

# Loop through each distribution list and get the members
foreach ($list in $distributionLists) {
    $members = Get-DistributionGroupMember -Identity $list.PrimarySmtpAddress
    foreach ($member in $members) {
        $results += [PSCustomObject]@{
            DistributionList = $list.PrimarySmtpAddress
            Member = $member.PrimarySmtpAddress
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "C:\temp\DistributionListMembers.csv" -NoTypeInformation

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false

Write-Output "Audit completed. The results are saved in DistributionListMembers.csv"
