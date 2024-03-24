  
# Dear Windows,

$ver = @{
    '6.1.7600' = 'Windows 7';
    '6.1.7601' = 'Windows 7 Service Pack 1';
    '6.2.9200' = 'Windows 8';
    '6.3.9600' = 'Windows 8.1';
    '10.0.10240' = 'Windows 10 - 1507';
    '10.0.10586' = 'Windows 10 - 1511';
    '10.0.14393' = 'Windows 10 - 1607';
    '10.0.15063' = 'Windows 10 - 1703';
    '10.0.16299' = 'Windows 10 - 1709';
    '10.0.17134' = 'Windows 10 - 1803';
    '10.0.17763' = 'Windows 10 - 1809';
    '10.0.18362' = 'Windows 10 - 1903';
    '10.0.18363' = 'Windows 10 - 1909';
    '10.0.19041' = 'Windows 10 - 2004';
    '10.0.19042' = 'Windows 10 - 20H2';
    '10.0.19043' = 'Windows 10 - 21H1';
    '10.0.19044' = 'Windows 10 - 21H2';
    '10.0.19045' = 'Windows 10 - 22H2';
    '10.0.22000' = 'Windows 11 - 21H2';
    '10.0.22621' = 'Windows 11 - 22H2'
}
            
# empty array for output
$output = @()

# dates to compare to
$yesterday = (Get-Date).AddDays(-1)
$twodays = (Get-Date).AddDays(-2)

# grab collection
$computers = Get-CMDevice -CollectionId ABC1234D | Select-Object LastActiveTime, LastLogonUser, IsClient, CNIsOnline, MACAddress, DeviceOSBuild, SerialNumber, Name, PrimaryUser

# for loop to lookup each PC name
foreach ($computer in $computers) {

    # gathering most of the information to storing in variables
    $name = $computer.Name

    # checks duplicate records for the one with client installed
    if ($computer.Length -gt 1) {
        if (($computer[0].IsClient) -and (!$computer[1].IsClient)){$computer = $computer[0]}
        elseif ((!$computer[0].IsClient) -and ($computer[1].IsClient)) {$computer = $computer[1]}
        else {$computer = $computer[0]}
    }

    if (($computer.CNIsOnline) -or ($computer.LastActiveTime -le $yesterday) -and ($computer.LastActiveTime -ge $twodays)) {
        try {
            $ipAddress = Resolve-DNSName -QuickTimeout -Name $name -ErrorAction Stop | Select-Object -Last 1 -ExpandProperty IPAddress
        } catch {
            $ipAddress = ''
        }

        try {
            $deviceOU = Get-ADComputer -Identity $name -Properties canonicalname | Select-Object -ExpandProperty canonicalname
        } catch {
            $deviceOU = ''
        }

        # formatting the OU output
        $canonicalSplit = $deviceOU.Split('/')
        $ouLength = $canonicalSplit.Length - 2
        if ($deviceOU -eq '') {$newOU = ''}
        else {$newOU = $deviceOU.Split('/')[1..$ouLength] -join '/'}

        # grabs a single mac address, if multiple
        if (($computer.MACAddress).Length -gt 17) {$macAddress = ($computer.MACAddress).Split(', ')[-1]}
        else {$macAddress = $computer.MACAddress}

        # catches any devices not in SCCM
        try {
            # if/else to change the TRUE/FALSE to Yes/No
            if ($computer.CNIsOnline) {$cnIsOnline = 'Yes'} 
            else {$cnIsOnline = 'No'}
        } catch [System.Management.Automation.RuntimeException]{}

        if (($computer.DeviceOSBuild).Length -ne 0) {$buildNum = ($computer.deviceosbuild).Split('.')[0..2] -join '.'}
        else {$buildNum = ''}

        if (($computer.LastActiveTime).Length -ne 0) {$lastActive = ($computer.LastActiveTime).ToLocalTime()}
        else {$lastActive = ''}

         $obj = [PSCustomObject]@{
            'Hostname' = $name;
            'Primary User' = $computer.PrimaryUser;
            'Last Logon User' = $computer.LastLogonUser;
            'Last Logon Date' = $lastActive;
            'Online' = $cnIsOnline;
            'IP Address' = $ipAddress;
            'MAC Address' = $macAddress;
            'Serial Number' = $computer.SerialNumber;
            'OS Version' = $ver[$buildNum];
            'OU Path' = $newOU
        }
        # add psCO to array
        $output += $obj
    } 
}

$output | Export-Csv -Path 'FILEPATH' -NoTypeInformation

Send-MailMessage -From 'REDACTED' -To 'REDACTED' -Subject 'Windows 10 Old: Currently/Recently Online' -Body "Attached is a CSV with any Windows 10 device currently online or last online within 24 hours." -Attachments 'FILEPATH' -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -SmtpServer 'MAILRELAY' 