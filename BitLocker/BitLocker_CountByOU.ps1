 
# Dear Windows,

[int32]$count = 0
$ouCounts = @{}

$stuff = Get-ADObject -Filter {objectClass -like "msFVE-RecoveryInformation"} -Properties CanonicalName

foreach ($device in $stuff) {
    $count += 1
    $ou = $($device.CanonicalName.Split('/')[1..$($device.CanonicalName.Split('/').Length - 3)] -join '/')
    if ($ouCounts.ContainsKey($ou)) {
        $ouCounts[$ou] += 1
    } else {
        $ouCounts[$ou] = 1
    }
}

$ouCounts.GetEnumerator() | Sort-Object Value -Descending | Format-Table @{l='OU';e={$_.name}}, @{l='Count';e={$_.value}}
"Total Records: $count"
#Read-Host 