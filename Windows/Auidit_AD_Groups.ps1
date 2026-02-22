$Groups = Get-ADGroup -Filter "GroupCategory -eq 'security'" 

$Results = foreach( $Group in $Groups ){

    Get-ADGroupMember -Identity $Group | foreach {

        [pscustomobject]@{

            GroupName = $Group.Name

            Name = $_.Name

            }

        }

    }

$Results| Export-Csv -Path c:\temp\groups.csv -NoTypeInformation