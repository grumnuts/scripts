### Exports all Active Directory users' names to C:\temp\userexport.csv

Get-ADUser -Filter * -SearchBase "OU=Users,DC=domain,DC=com" -Properties * | Select-Object name | export-csv -path c:\temp\userexport.csv