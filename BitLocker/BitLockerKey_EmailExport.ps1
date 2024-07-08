 
# Dear Windows,

$date = Get-Date -Format "MM-dd_hh-mm"
[int32]$count = 0
$output = @()
$stuff = Get-ADObject -Filter {objectClass -like "msFVE-RecoveryInformation"} -Properties whenCreated,msFVE-RecoveryPassword,CanonicalName,DistinguishedName

foreach ($device in $stuff) {
    $devInfo = $null; $admInfo = $null; $name = $null; $serial = $null; $bitID = $null; $bitIDCreated = $null; $bitKey = $null; $bitDate = $null; $lastUser = $null; $lastActive = $null; $admCreds = $null; $admDate = $null; $ou = $null; $desc = $null
    
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
    $bitID = $($device.Name.split('{')[1].TrimEnd('}'))
    $bitIDCreated = $($device.Name.split('{')[0])
    $bitKey = $($device.'msFVE-RecoveryPassword')
    $bitDate = $($device.whenCreated)
    $lastUser = $($devInfo.LastLogonUser)
    $lastActive = $($devInfo.LastActiveTime)
    $admCreds = $($admInfo.msSVSAdmPwd)
    $fileTime = [System.DateTime]::FromFileTime($admInfo.msSVSAdmPwdLastSet)
    $admDate = $fileTime.ToString("yyyy-MM-dd HH:mm:ss")
    $ou = $($device.CanonicalName.Split('/')[0..$($device.CanonicalName.Split('/').Length - 3)] -join '/')
    $desc = $($admInfo.Description)

    if ($serial -is [array]) {
        if ($serial.Count -gt 1) {
            $serial = $serial -join ', '
        } else {
            $serial = $serial[0]
        }
    }
    if ($bitID -is [array]) {
        if ($bitID.Count -gt 1) {
            $bitID = $bitID -join ', '
        } else {
            $bitID = $bitID[0]
        }
    }
    if ($bitKey -is [array]) {
        if ($bitKey.Count -gt 1) {
            $bitKey = $bitKey -join ', '
        } else {
            $bitKey = $bitKey[0]
        }
    }
    if ($lastUser -is [array]) {
        if ($lastUser.Count -gt 1) {
            $lastUser = $lastUser -join ', '
        } else {
            $lastUser = $lastUser[0]
        }
    }
    if ($lastActive -is [array]) {
        if ($lastActive.Count -gt 1) {
            $lastActive = $lastActive  -join ', '
        } else {
            $lastActive = $lastActive[0]
        }
    }

    if ($serial -eq $null) {$serial = "No serial"}
    if ($lastUser -eq $null) {$lastUser = "No last active user"}
    if ($lastActive -eq $null) {$lastActive = "No last active date"}
    if ($admCreds -eq $null) {$admCreds = "No admin credentials"}
    if ($admDate -eq $null) {$admDate = "No admin date"}
    if ($ou -eq $null) {$ou = "No OU"}

    $obj = [PSCustomObject]@{
        'Device Name' = $name;
        'Serial Number' = $serial;
        'Recovery Key Created' = $bitIDCreated;
        'Recovery Key ID' = $bitID;
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
