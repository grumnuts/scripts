
# Install the Teams PowerShell module if not already installed
#Install-Module -Name MicrosoftTeams -Force -AllowClobber

# Connect to Microsoft Teams
Connect-MicrosoftTeams

# Create a list to store audit results
$auditResults = @()

# Get all Teams
$teams = Get-Team

foreach ($team in $teams) {
    $teamName = $team.DisplayName
    $groupId = $team.GroupId

    # Get members of the Team
    $teamMembers = Get-TeamUser -GroupId $groupId
    foreach ($member in $teamMembers) {
        $auditResults += [PSCustomObject]@{
            TeamName = $teamName
            GroupId = $groupId
            ChannelName = ""
            ChannelType = ""
            MemberName = $member.User
            MemberRole = $member.Role
            Scope = "Team"
        }
    }

    # Get channels in the Team
    $channels = Get-TeamChannel -GroupId $groupId
    foreach ($channel in $channels) {
        $channelName = $channel.DisplayName
        $channelType = $channel.MembershipType

        # For private channels, list members
        if ($channelType -eq "Private") {
            $channelMembers = Get-TeamChannelUser -GroupId $groupId -DisplayName $channelName
            foreach ($channelMember in $channelMembers) {
                $auditResults += [PSCustomObject]@{
                    TeamName = $teamName
                    GroupId = $groupId
                    ChannelName = $channelName
                    ChannelType = $channelType
                    MemberName = $channelMember.User
                    MemberRole = $channelMember.Role
                    Scope = "Channel"
                }
            }
        } else {
            # For standard channels, just record the channel info
            $auditResults += [PSCustomObject]@{
                TeamName = $teamName
                GroupId = $groupId
                ChannelName = $channelName
                ChannelType = $channelType
                MemberName = ""
                MemberRole = ""
                Scope = "Channel"
            }
        }
    }
}

# Export results to CSV
$auditResults | Export-Csv -Path "C:\temp\TeamsAuditReport.csv" -NoTypeInformation -Encoding UTF8
