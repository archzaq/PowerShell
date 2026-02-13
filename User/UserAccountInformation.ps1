
# Dear Windows,

$date = Get-Date -Format "MM-dd_hh-mm"

# semi-crusty way to loop until a valid path is provided
$flow = $true
while ($flow) {
    ''
    $filePath = Read-Host -Prompt "Enter the filepath of the CSV"
    $csv = $filePath.Split(".")[1]
    if ($filePath -eq '') {$flow = $false}
    else {
        # check the provided filepath is valid and ends in csv
        if ((Test-Path -Path $filePath) -and ($csv -eq 'csv')) {
            try {
                $users = Import-Csv -ErrorAction Stop -Path $filePath
            } catch {
                ''
                Write-Warning -Message "Unable to import CSV at $filePath. Check CSV file."
                ''
            }

            $obj = foreach ($user in $users) {
                $none = $false
                $out = $null
                try {
                    $info = Get-ADUser $user.Name -Properties CanonicalName,Department,SamAccountName,employeeid,givenname,surname,lastlogondate,title       
                } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                    $info = "no user found"
                    $none = $true
                }
    
                if (!$none) {
                    $out = [PSCustomObject]@{
                        'Name' = $user.Name;
                        'Given Name' = $info.GivenName;
                        'Surname' = $info.Surname;
                        'Department' = $info.Department;
                        'Title' = $info.Title;
                        'SAM Account Name' = $info.SamAccountName;
                        'Employee ID' = [String]$info.EmployeeID;
                        'Last Logon Date' = $info.LastLogonDate;
                        'Canonical Name' = $info.CanonicalName;
                        'Crafted Email' = "$($info.SamAccountName)@slu.edu"
                    }
                } else {
                    $out = [PSCustomObject]@{
                        'Name' = $user.Name;
                        'Given Name' = "Unable to locate user"
                    }
                }
    
                $out
            }
            $obj | Export-Csv -Path "C:\Users\USER\Documents\Reports\UsernameInformation$($date).csv" -NoTypeInformation
            $flow = $false
        }
    }
}