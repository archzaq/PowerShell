 
# Dear Windows,

$date = Get-Date -Format "MM-dd_hh-mm"
[int32]$count = 0
$output = @()
$stuff = Get-ADObject -Filter {objectClass -like "msFVE-RecoveryInformation"} -Properties whenCreated,msFVE-RecoveryPassword,CanonicalName,DistinguishedName

foreach ($device in $stuff) {
    $devInfo = $null
    $admInfo = $null
    $name = $null
    $serial = $null
    #$bitID = $null
    $bitKey = $null
    $bitDate = $null
    $lastUser = $null
    $lastActive = $null
    $admCreds = $null
    $admDate = $null
    $ou = $null
    $desc = $null
    
    $count += 1
    $name = $($device.CanonicalName.Split('/')[-2])
    try {
        $devInfo = Get-CMDevice -Fast -Name $name | Select-Object SerialNumber,LastActiveTime,LastLogonUser
    } catch {
        $devInfo = "Not in SCCM"
    }
    try {
        $admInfo = Get-ADComputer -Identity $name -Properties msSVSAdmPwd,msSVSAdmPwdLastSet,Description
    } catch {
        $admInfo = "Not in AD"
    }

    $serial = $($devInfo.SerialNumber)
    #$bitID = $($device.'msFVE-RecoveryGuid')
    $bitKey = $($device.'msFVE-RecoveryPassword')
    $bitDate = $($device.whenCreated)
    $lastUser = $($devInfo.LastLogonUser)
    $lastActive = $($devInfo.LastActiveTime)
    $admCreds = $($admInfo.msSVSAdmPwd)
    $fileTime = [System.DateTime]::FromFileTime($admInfo.msSVSAdmPwdLastSet)
    $admDate = $fileTime.ToString("yyyy-MM-dd HH:mm:ss")
    $ou = $($device.CanonicalName.Split('/')[0..$($device.CanonicalName.Split('/').Length - 3)] -join '/')
    $desc = $($admInfo.Description)

    if ($serial -is [array]) {$serial = $serial[0]}
    if ($bitKey -is [array]) {$bitKey = $bitKey[0]}
    if ($lastUser -is [array]) {$lastUser = $lastUser[0]}
    if ($lastActive -is [array]) {$lastActive = $lastActive[0]}

    if ($serial -eq $null) {$serial = "No serial"}
    if ($lastUser -eq $null) {$lastUser = "No last active user"}
    if ($lastActive -eq $null) {$lastActive = "No last active date"}
    if ($admCreds -eq $null) {$admCreds = "No admin credentials"}
    if ($admDate -eq $null) {$admDate = "No admin date"}
    if ($ou -eq $null) {$ou = "No OU"}

    $obj = [PSCustomObject]@{
        'Device Name' = $name;
        'Serial Number' = [String]$serial;
        'BitLocker Key' = $bitKey;
        'Date Key Created' = $bitDate;
        'Last Logon User' = $lastUser;
        'Last Active Date' = $lastActive;
        'Admin Credentials' = $admCreds;
        'Credentials Last Set' = $admDate;
        'OU' = $ou;
        'Description' = $desc
    }
    $output += $obj
}

$output | Export-Csv -Path "FILEPATH" -NoTypeInformation

Send-MailMessage -From 'REDACTED' -To 'REDACTED' -Subject 'BitLocker Key Export' -Body "Attached is a CSV with some keys." -Attachments "FILEPATH" -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -SmtpServer 'MAILRELAY' 