  
# Dear Windows,

$supported10 = 0
$unsupported10 = 0
$win11 = 0
$win8 = 0
$win7 = 0
$all = Get-CMDevice -CollectionId ABC123 | Select-Object DeviceOSBuild

foreach ($computer in $all) {
    if (($computer.DeviceOSBuild).Length -ne 0) {$buildNum = ($computer.deviceosbuild).Split('.')[0..2] -join '.'}
    if ($buildNum -eq '6.1.7600' -or $buildNum -eq '6.1.7601') { $win7 += 1;
    } elseif ($buildNum -eq '6.2.9200' -or $buildNum -eq '6.3.9600') { $win8 += 1;
    } elseif ($buildNum -gt '10.0.19045') { $win11 += 1;
    } elseif ($buildNum -ge '10.0.10240' -and $buildNum -le '10.0.19043') { $unsupported10 += 1;
    } elseif ($buildNum -eq '10.0.19044' -or $buildNum -eq '10.0.19045') { $supported10 += 1;
    } else {"$computer with build number, $buildNum, not in list"}
}

''
'WSUS - All WKS minus Exclusions + WSUS - Classrooms'
"Supported Windows 10: $supported10`nUnsupported Windows 10: $unsupported10"
"Windows 11: $win11`nWindows 8: $win8`nWindows 7: $win7" 