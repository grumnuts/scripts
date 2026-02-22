# Install the Teams PowerShell module if not already installed
# Install-Module -Name MicrosoftTeams -Force -AllowClobber

# Connect to Microsoft Teams
Connect-MicrosoftTeams

# Define the user to be added as owner
$userToAdd = "elevate@plaiscamphill.com.au"  # Replace with the actual UPN of the user

# Get all Teams
$teams = Get-Team

foreach ($team in $teams) {
    $groupId = $team.GroupId
    $teamName = $team.DisplayName

    try {
        # Add the user as a member first (required before promoting to owner)
        Add-TeamUser -GroupId $groupId -User $userToAdd -Role Member -ErrorAction SilentlyContinue

        # Promote the user to owner
        Add-TeamUser -GroupId $groupId -User $userToAdd -Role Owner

        Write-Host "Added $userToAdd as Owner to Team: $teamName"
    } catch {
        Write-Host "Failed to add $userToAdd to Team: $teamName. Error: $_"
    }

    # Get all channels in the Team
    $channels = Get-TeamChannel -GroupId $groupId

    foreach ($channel in $channels) {
        if ($channel.MembershipType -eq "Private") {
            try {
                # Add the user to the private channel
                Add-TeamChannelUser -GroupId $groupId -DisplayName $channel.DisplayName -User $userToAdd -Role Owner
                Write-Host "Added $userToAdd as Owner to Private Channel: $($channel.DisplayName) in Team: $teamName"
            } catch {
                Write-Host "Failed to add $userToAdd to Private Channel: $($channel.DisplayName) in Team: $teamName. Error: $_"
            }
        }
    }
}
