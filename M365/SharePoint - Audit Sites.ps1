# -----------------------------
# SharePoint Permission Audit
# -----------------------------

# CONFIGURATION
$TenantName = "your-tenant"  # <-- CHANGE THIS
$TenantAdminUrl = "https://$TenantName-admin.sharepoint.com"
$OutputFile = "$TenantName - SharePoint Permission Audit.csv"

# ----------------------------------------
# STEP 1: Install & Import Required Modules
# ----------------------------------------
$modules = @("PnP.PowerShell", "Microsoft.Online.SharePoint.PowerShell")

foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing module: $module" -ForegroundColor Yellow
        Install-Module $module -Force -Scope CurrentUser
    }
    Import-Module $module -Force
}

# -------------------------------
# STEP 2: Connect to SPO & PnP
# -------------------------------
Write-Host "Connecting to SharePoint Online Admin..." -ForegroundColor Cyan
Connect-SPOService -Url $TenantAdminUrl

# Get all sites
$AllSites = Get-SPOSite -Limit All

# Initialize results array
$Results = @()

foreach ($site in $AllSites) {
    Write-Host "`nScanning site: $($site.Url)" -ForegroundColor Green

    try {
        # Connect to each site with PnP
        Connect-PnPOnline -Url $site.Url -Interactive
    }
    catch {
        Write-Warning "Failed to connect to $($site.Url). Skipping..."
        continue
    }

    # STEP 3: Get Members (Non-admins)
    try {
        $groups = Get-PnPGroup
        $memberGroup = $groups | Where-Object { $_.Title -match "Member" }

        if ($memberGroup) {
            $members = Get-PnPGroupMembers -Identity $memberGroup | Where-Object {
                $_.PrincipalType -eq "User" -and
                $_.LoginName -notmatch "admin"
            }

            foreach ($member in $members) {
                $Results += [PSCustomObject]@{
                    SiteUrl    = $site.Url
                    Type       = "Site Member"
                    Object     = "Site"
                    User       = $member.Title
                    LoginName  = $member.LoginName
                    IsGuest    = ($member.LoginName -like "*#ext#*") -or ($member.IsShareByEmailGuestUser)
                }
            }
        }
    }
    catch {
        Write-Warning "Could not retrieve members for $($site.Url)"
    }

    # STEP 4: Check for Unique Permissions in Document Libraries
    try {
        $lists = Get-PnPList | Where-Object { $_.BaseType -eq "DocumentLibrary" -and $_.Hidden -eq $false }

        foreach ($list in $lists) {
            $items = Get-PnPListItem -List $list.Title -PageSize 100 -Fields "FileRef" -ErrorAction SilentlyContinue

            foreach ($item in $items) {
                if ($item.HasUniqueRoleAssignments) {
                    $itemUrl = "$($site.Url)/$($item.FieldValues.FileRef)"

                    $roleAssignments = Get-PnPProperty -ClientObject $item -Property RoleAssignments
                    foreach ($role in $roleAssignments) {
                        $member = Get-PnPProperty -ClientObject $role -Property Member

                        if ($member.PrincipalType -eq "User" -and $member.LoginName -notmatch "admin") {
                            $Results += [PSCustomObject]@{
                                SiteUrl    = $site.Url
                                Type       = "Unique File/Folder Permission"
                                Object     = $itemUrl
                                User       = $member.Title
                                LoginName  = $member.LoginName
                                IsGuest    = ($member.LoginName -like "*#ext#*")
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Could not check list items in $($site.Url)"
    }
}

# -----------------------
# STEP 5: Export Results
# -----------------------
Write-Host "`nExporting results to $OutputFile..." -ForegroundColor Cyan
$Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
Write-Host "Audit complete. ✅ Results saved to: $OutputFile" -ForegroundColor Green