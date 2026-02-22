# Install the Teams PowerShell module if not already installed
# Install-Module -Name MicrosoftTeams -Force -AllowClobber

# Connect to Microsoft Teams
Connect-MicrosoftTeams

# Define the user to be added as owner
$userToAdd = "elevate@plaiscamphill.com.au"  # Replace with the actual UPN of the user

# Get all Teams
$teams = Get-Team

foreach ($team in $teams) {
    try {
        # Add the user as a member first (required before promoting to owner)
        Add-TeamUser -GroupId $team.GroupId -User $userToAdd -Role Member -ErrorAction SilentlyContinue

        # Promote the user to owner
        Add-TeamUser -GroupId $team.GroupId -User $userToAdd -Role Owner

        Write-Host "Added $userToAdd as Owner to Team: $($team.DisplayName)"
    } catch {
        Write-Host "Failed to add $userToAdd to Team: $($team.DisplayName). Error: $_"
    }
}
