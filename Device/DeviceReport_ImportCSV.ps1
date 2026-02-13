 
# Dear Windows,

 # grab date/time for the filename
$date = Get-Date -Format "yyyy-MM-dd_hh-mm"

# create reports folder in documents if it doesnt exist
if (Test-Path -Path C:\Users\$env:UserName\Documents\Reports -PathType Container) {}
else {
    New-Item -Path C:\Users\$env:UserName\Documents\Reports -ItemType directory | Out-Null;
    "Reports folder created at C:\Users\$env:UserName\Documents\Reports"
}

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
    '10.0.22621' = 'Windows 11 - 22H2';
    '10.0.22631' = 'Windows 11 - 23H2';
    '10.0.26100' = 'Windows 11 - 24H2'
}

# output file path
$outputPath = "C:\Users\$env:UserName\Documents\Reports\DeviceReport_$($date).csv"

# semi-crusty way to loop until a valid path is provided
$flow = $True
while ($flow) {
    ''
    $filePath = Read-Host -Prompt "Enter the filepath of the CSV"
    $csv = $filePath.Split(".")[1]
    if ($filepath -eq '') {$flow = $False}
    else {
        # check the provided filepath is valid and ends in csv
        if ((Test-Path -Path $filePath) -and ($csv -eq 'csv')) {
            try {
                $computers = Import-Csv -ErrorAction Stop -Path $filePath
            } catch {
                ''
                Write-Warning -Message "Unable to import CSV at $filePath. Check CSV file."
                ''
            }
            
            ''
            Write-Host 'Please be patient' -ForegroundColor Cyan
            ''

            # for loop to lookup each PC name
            $output = foreach ($computer in $computers) {
            
                # gathering most of the information to storing in variables
                $name = $computer.Hostname
                if (!$name) {
                    Write-Host "Ensure the import CSV has 'Hostname' as the header" -ForegroundColor Red
                }

                $info = Get-CMDevice -Fast -Name $name | Select-Object LastActiveTime, LastLogonUser, IsClient, CNIsOnline, MACAddress,DeviceOSBuild,SerialNumber,PrimaryUser

                # checks duplicate records for the one with client installed
                if ($info.Length -gt 1) {
                    if (($info[0].IsClient) -and (!$info[1].IsClient)){$info = $info[0]}
                    elseif ((!$info[0].IsClient) -and ($info[1].IsClient)) {$info = $info[1]}
                    else {$info = $info[0]}
                }

                try {
                    $ipAddress = Resolve-DNSName -QuickTimeout -Name $name -ErrorAction Stop | Select-Object -Last 1 -ExpandProperty IPAddress
                } catch {
                    $ipAddress = ''
                    "$name is unreachable to gather IP address."
                }

                try {
                    $deviceOU = Get-ADComputer -Identity $name -Properties canonicalname | Select-Object -ExpandProperty canonicalname
                } catch {
                    $deviceOU = ''
                    "$name not in Active Directory."
                }
            
                # formatting the OU output
                $canonicalSplit = $deviceOU.Split('/')
                $ouLength = $canonicalSplit.Length - 2
                if ($deviceOU -eq '') {$newOU = ''}
                else {$newOU = $deviceOU.Split('/')[1..$ouLength] -join '/'}
            
                # grabs a single mac address, if multiple
                if (($info.MACAddress).Length -gt 17) {$macAddress = ($info.MACAddress).Split(', ')[-1]}
                else {$macAddress = $info.MACAddress}

                # catches any devices not in SCCM
                try {
                    # two if/else to change the TRUE/FALSE to Yes/No
                    if ($info.IsClient) {$isClient = 'Yes'} 
                    else {$isClient = 'No'}
                    if ($info.CNIsOnline) {$cnIsOnline = 'Yes'} 
                    else {$cnIsOnline = 'No'}
                } catch [System.Management.Automation.RuntimeException]{
                    "$name is not in SCCM."
                }

                if (($info.DeviceOSBuild).length -ne 0) {$buildNum = ($info.deviceosbuild).Split('.')[0..2] -join '.'}
                else {$buildNum = ''}

                if (($info.LastActiveTime).length -ne 0) {$lastActive = ($info.LastActiveTime).ToLocalTime()}
                else {$lastActive = ''}
            
                # psCO to store/output the information gathered
                [PSCustomObject]@{
                    'Hostname' = $name;
                    'Primary User' = $info.PrimaryUser;
                    'Last Logon User' = $info.LastLogonUser;
                    'SCCM Client' = $isClient;
                    'Online' = $cnIsOnline;
                    'Last Logon Date' = $lastActive;
                    'IP Address' = $ipAddress;
                    'MAC Address' = $macAddress;
                    'Serial Number' = $info.SerialNumber;
                    'OS Version' = $ver[$buildNum];
                    'OU Path' = $newOU
                }
                
            }
            # output the output
            $output | Export-Csv -Path $outputPath -NoTypeInformation
            ''
            Write-Host "New report created at $outputPath"
            $flow = $False

        } else {
            ''
            Write-Warning -Message "$filePath invalid. Provide the filepath to a CSV file."
            ''
        }
    }
} 

