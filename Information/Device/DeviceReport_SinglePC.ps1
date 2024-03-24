
# Dear Windows,

# cant use get-wmiobject so this is the alternative method
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

$flow = $true
while ($flow -eq $true) {
    # gathering most of the information to storing in variables
    ''
    $name = Read-Host -Prompt 'Enter PC name'
    if ($name -eq '') {$flow = $false}
    else {
        $noOU = 0
        $noIP = 0
        $noSCCM = 0
        $obj = @()

        $info = Get-CMDevice -Fast -Name $name | Select-Object LastActiveTime, LastLogonUser, IsClient, CNIsOnline, MACAddress, DeviceOSBuild, SerialNumber, PrimaryUser

        try {
            $deviceOU = Get-ADComputer -Identity $name -Properties canonicalname | Select-Object -ExpandProperty canonicalname
        } catch {
            $deviceOU = "$name not in Active Directory."
            $noOU = 1
        }
        
        try {
            $ipAddress = Resolve-DNSName -QuickTimeout -Name $name -ErrorAction Stop | Select-Object -Last 1 -ExpandProperty IPAddress
        } catch {
            $ipAddress = "$name offline."
            $noIP = 1
        }
        
        # display multiple records, if any, then choose the first one
        if ($info.Length -eq 0) {
            ''
            $noSCCM = 1
            if (($noOU -eq 1) -and ($noIP -eq 1) -and ($noSCCM -eq 1)) {
                'No records found in AD or SCCM. Check device name.';
                exit
             }
            'Check device name, no SCCM records found.';
        }
        
        if ($info.Length -gt 1) {
            ''
            'Multiple Records:';
            $info;
            ''
            ''
            if (($info[0].IsClient) -and (!$info[1].IsClient)) {$info = $info[0]}
            elseif ((!$info[0].IsClient) -and ($info[1].IsClient)) {$info = $info[1]}
            else {$info = $info[0]}
        }
        
        if (($info.DeviceOSBuild).Length -ne 0) {$buildNum = ($info.deviceosbuild).Split('.')[0..2] -join '.'}
        
        if (($info.LastActiveTime).Length -ne 0) {$info.LastActiveTime = ($info.LastActiveTime).ToLocalTime()}

        # grabs a single mac address, if multiple
        if (($info.MACAddress).Length -gt 17) {$macAddress = ($info.MACAddress).Split(', ')[-1]}
        else {$macAddress = $info.MACAddress}
       
        $obj = [PSCustomObject]@{
            'Hostname' = $name;
            'Primary User' = $info.PrimaryUser;
            'Last Logon User' = $info.LastLogonUser;
            'SCCM Client' = $info.IsClient;
            'Online' = $info.CNIsOnline;
            'Last Logon Date' = $lastActive;
            'IP Address' = $ipAddress;
            'MAC Address' = $macAddress;
            'Serial Number' = $info.SerialNumber;
            'OS Version' = $ver[$buildNum];
            'OU Path' = $deviceOU
        }
        $obj
    }
}