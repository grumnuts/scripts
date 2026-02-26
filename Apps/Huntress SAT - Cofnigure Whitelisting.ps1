



### STEP 3 - Allowlist Phishing Emails in Microsoft Office 365 Defender Basic and Advanced ###

#Install-Module ExchangeOnlineManagement

Import-Module ExchangeOnlineManagement

Connect-ExchangeOnline

New-TenantAllowBlockListItems -Allow -ListType Url -ListSubType AdvancedDelivery -Entries "amazonsecurity.org/*","breach-notice.com/*","employee-services.org/*","feedback-collect.com/*","filesharingnow.com/*","fraud-assistance.com/*","invite-meeting.com/*","mailbox-quota.com/*","news-article.com/*","passwordsnotification.com/*","payment-process.com/*","securelinkedin.com/*","security-updater.com/*","securitynotifications.org/*","notificationservices.org/*","databoxonline.com/*","emailtransaction.com/*","electronic-hr.com/*" -NoExpiration

Connect-IPPSSession

New-PhishSimOverridePolicy -Name PhishSimOverridePolicy

New-ExoPhishSimOverrideRule -Name PhishSimOverrideRule -Policy "PhishSimOverridePolicy" -Domains "mycurricula.com","alerts.mycurricula.com","phish.mycurricula.com","securitynotifications.org","security-updater.com","amazonsecurity.org","breach-notice.com","filesharingnow.com","mailbox-quota.com","passwordsnotification.com","securelinkedin.com","fraud-assistance.com","payment-process.com","news-article.com","invite-meeting.com","feedback-collect.com","businessnotice.org","databoxonline.com","electronic-hr.com","emailtransaction.com","employee-services.org","governmentnotice.org","notificationservices.org" -SenderIpRanges 18.205.140.116,168.245.36.66