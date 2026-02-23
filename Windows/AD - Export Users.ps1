### Exports all Active Directory users' names to C:\temp\userexport.csv

Get-ADUser -Filter * -SearchBase ",OU=Users,DC=ad,DC=cougarmg,DC=com,DC=au" -Properties * | Select-Object name | export-csv -path c:\temp\userexport.csv