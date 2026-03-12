############# STEP 1 - EOP Whitelisting Rule #############

try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop

    New-TransportRule -Name "Elevate SAT - Bypass Spam Filter" -Priority 0 -HeaderMatchesMessageHeader "X-PHISHTEST-Curricula" -HeaderMatchesPatterns "Phishing security test delivered by Curricula" -SetSCL "-1" -Comments "Enforce to bypass spam filtering for Curricula phishing test" -Enabled $true -StopRuleProcessing $false -ErrorAction Stop
    New-TransportRule -Name "Elevate SAT - Bypass ATP Links" -Priority 1 -HeaderMatchesMessageHeader "X-PHISHTEST-Curricula" -HeaderMatchesPatterns "Phishing security test delivered by Curricula" -SetSCL "-1" -Comments "Enforce to bypass spam filtering for Curricula phishing test" -Enabled $true -StopRuleProcessing $false -ErrorAction Stop

    Write-Output "[STEP 1] EOP transport rules created successfully."
} catch {
    Write-Error "[STEP 1] error: $_"
    throw
}

############# STEP 2 - Safe Links #############

try {
    $policyName = 'Elevate SAT Safe Links'
    $policy = Get-SafeLinksPolicy | Where-Object { $_.Name -eq $policyName }

    if (-not $policy) {
        Write-Output "Safe Links policy '$policyName' not found. Creating new policy."
        $policy = New-SafeLinksPolicy -Name $policyName -DoNotRewriteUrls @() -ErrorAction Stop
        $policy = Get-SafeLinksPolicy | Where-Object { $_.Name -eq $policyName }
    }

    $exclusions = @(
        'amazonsecurity.org',
        'breach-notice.com',
        'employee-services.org',
        'feedback-collect.com',
        'filesharingnow.com',
        'fraud-assistance.com',
        'invite-meeting.com',
        'mailbox-quota.com',
        'news-article.com',
        'passwordsnotification.com',
        'payment-process.com',
        'securelinkedin.com',
        'security-updater.com',
        'securitynotifications.org',
        'notificationservices.org',
        'databoxonline.com',
        'emailtransaction.com',
        'electronic-hr.com',
        'mycurricula.com',
        'alerts.mycurricula.com',
        'phish.mycurricula.com',
        'businessnotice.org',
        'governmentnotice.org'
    )

    $current = @()
    if ($policy.DoNotRewriteUrls) { $current += $policy.DoNotRewriteUrls }
    $updated = ($current + $exclusions | Sort-Object -Unique)

    if ($policy -ne $null) {
        Set-SafeLinksPolicy -Identity $policyName -DoNotRewriteUrls $updated -AllowClickThrough $True -DisableUrlRewrite $True -ErrorAction Stop
        Write-Output "[STEP 2] Safe Links policy '$policyName' updated successfully."
    } else {
        Throw "Safe Links policy '$policyName' could not be found or created."
    }
} catch {
    Write-Error "[STEP 2] error: $_"
    throw
}

$exclusions = @(
    'amazonsecurity.org',
    'breach-notice.com',
    'employee-services.org',
    'feedback-collect.com',
    'filesharingnow.com',
    'fraud-assistance.com',
    'invite-meeting.com',
    'mailbox-quota.com',
    'news-article.com',
    'passwordsnotification.com',
    'payment-process.com',
    'securelinkedin.com',
    'security-updater.com',
    'securitynotifications.org',
    'notificationservices.org',
    'databoxonline.com',
    'emailtransaction.com',
    'electronic-hr.com',
    'mycurricula.com',
    'alerts.mycurricula.com',
    'phish.mycurricula.com',
    'businessnotice.org',
    'governmentnotice.org'
)

$current = @()
if ($policy.DoNotRewriteUrls) {
    $current += $policy.DoNotRewriteUrls
}

$updated = ($current + $exclusions | Sort-Object -Unique)

if ($policy -ne $null) {
    Set-SafeLinksPolicy -Identity $policyName -DoNotRewriteUrls $updated -AllowClickThrough $True -DisableUrlRewrite $True
    Write-Output "Safe Links policy '$policyName' updated with required SAT exclusions (propagation may take time)."
} else {
    Write-Error "Safe Links policy '$policyName' could not be found or created. Aborting update."
}


############# STEP 3 - Allowlist Phishing Emails in Microsoft Office 365 Defender Basic and Advanced #############

# Add domains to allow list (idempotent, ignore duplicate entries)
try {
    $allowEntries = @(
        'amazonsecurity.org/*','breach-notice.com/*','employee-services.org/*','feedback-collect.com/*','filesharingnow.com/*','fraud-assistance.com/*','invite-meeting.com/*','mailbox-quota.com/*','news-article.com/*','passwordsnotification.com/*','payment-process.com/*','securelinkedin.com/*','security-updater.com/*','securitynotifications.org/*','notificationservices.org/*','databoxonline.com/*','emailtransaction.com/*','electronic-hr.com/*'
    ) | Sort-Object -Unique

    New-TenantAllowBlockListItems -Allow -ListType Url -ListSubType AdvancedDelivery -Entries $allowEntries -NoExpiration -ErrorAction Stop
    Write-Output "[STEP 3] URL allowlist entries added successfully."
} catch {
    if ($_.Exception.Message -match 'Invalid value to add.*Duplicate value') {
        Write-Warning "[STEP 3] Duplicate value in allowlist; this can be ignored."
    } else {
        Write-Error "[STEP 3] New-TenantAllowBlockListItems error: $_"
        throw
    }
}

#Get Phishing rule
try {
    Connect-IPPSSession -ErrorAction Stop

    $rule = Get-ExoPhishSimOverrideRule
    if (-not $rule) {
        Write-Output 'PhishSim override rule not found, creating rule'
        $initialSenderIpRanges = @('18.205.140.116','168.245.36.66')
        New-ExoPhishSimOverrideRule -Name PhishSimOverrideRule -Policy "PhishSimOverridePolicy" -SenderIpRanges $initialSenderIpRanges -ErrorAction Stop

        $rule = Get-ExoPhishSimOverrideRule
        if (-not $rule) {
            Throw 'PhishSim override rule could not be created.'
        }
    }

    $ruleId = $rule.Id
    if (-not $ruleId) {
        Throw 'PhishSim override rule ID is null.'
    }

    # Remove Aware domains and IPs if needed
    $awareDomains = @(
        'office-email.com.au','account-secure-login.com','app-gemail.com','app-g-secure.com','secure-g-accounts.com','login-gapps.com','securelogin-gservices.com','accounts-secure.com','securesystem-login.com','securelogin-account.com','accounts-moffice.com','accounts-office.com','secure-login-office.com','msoft-services.com','office-securelogin.com','securelogin-bank.com','app-finance.com','fraudteam-finance.com','corporatesecurityalert.com','networkprotectionteam.com','itsecurity-alerts.com','employeeverification-system.com','datasecurity-notice.com','corporatealert-system.com','usercompliance-check.com','dataprotection-service.com','emailverificationdesk.com','corporateit-support.com','office-email.co.za'
    )
    if ($awareDomains.Count -gt 0) {
        Set-ExoPhishSimOverrideRule -Id $ruleId -RemoveDomains $awareDomains -RemoveSenderIpRanges 159.112.246.73,159.135.224.107 -ErrorAction Stop
    }

    # Add Elevate SAT domains and IPs to phishing rule
    $elevateDomains = @(
        'mycurricula.com','alerts.mycurricula.com','phish.mycurricula.com','securitynotifications.org','security-updater.com','amazonsecurity.org','breach-notice.com','filesharingnow.com','mailbox-quota.com','passwordsnotification.com','securelinkedin.com','fraud-assistance.com','payment-process.com','news-article.com','invite-meeting.com','feedback-collect.com','businessnotice.org','databoxonline.com','electronic-hr.com','emailtransaction.com','employee-services.org','governmentnotice.org','notificationservices.org'
    )

    $senderIpRangesOnDisk = @('18.205.140.116','168.245.36.66')
    $currentSenderIpRanges = @($rule.SenderIpRanges)
    $senderIpRangesToAdd = $senderIpRangesOnDisk | Where-Object { $_ -notin $currentSenderIpRanges }

    Set-ExoPhishSimOverrideRule -Id $ruleId -AddDomains $elevateDomains -ErrorAction Stop
    if ($senderIpRangesToAdd.Count -gt 0) {
        Set-ExoPhishSimOverrideRule -Id $ruleId -AddSenderIpRanges $senderIpRangesToAdd -ErrorAction Stop
    }

    Write-Output "[STEP 3] PhishSim override policy updated successfully."
} catch {
    Write-Error "[STEP 3] error: $_"
    throw
}

