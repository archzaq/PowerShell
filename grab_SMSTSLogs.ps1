 
##########################
### Author: Zac Reeves ###
### Created: 09-18-25  ###
### Version: 2.0       ###
##########################
### Contributions:     #####################
### Mike Martin (SLU): log deduplication ###
### Last Updated: 01-15-26               ###
############################################

# Dear Windows,

$beforeDiskFormat = 'X:\windows\temp\smstslog\smsts.log'
$afterDiskFormat = 'X:\smstslog\smsts.log'
$beforeClientInstalled = 'C:\_SMSTaskSequence\Logs\Smstslog\smsts.log'
$afterClientInstalled = 'C:\windows\ccm\logs\Smstslog\smsts.log'
$afterTaskSequence = 'C:\windows\ccm\logs\smsts.log'
$logFiles = @($beforeDiskFormat, $afterDiskFormat, $beforeClientInstalled, $afterClientInstalled, $afterTaskSequence)
$uncLogPath = '\\ds.slu.edu\dep\ITS\ITS-EVERYONE\For SCCM Team\_Logs'
$driveRoot = '\\ds.slu.edu\dep'
$serialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber.Trim()
$hostname = "$env:COMPUTERNAME`_$serialNumber"
$validPaths = @()
$filesFound = 0
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDrive = (Get-Item $scriptPath).PSDrive.Name
$driveInfo = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "$scriptDrive`:"}

function Get-LogLabel {
    param(
        [string]$Path
    )
    $mappings = @{
        'x:\windows\temp\smstslog\smsts.log'          = 'WinPE_BeforeFormat'
        'x:\smstslog\smsts.log'                       = 'WinPE_AfterFormat'
        'c:\_smstasksequence\logs\smstslog\smsts.log' = 'OS_BeforeClient'
        'c:\windows\ccm\logs\smstslog\smsts.log'      = 'OS_AfterClient'
        'c:\windows\ccm\logs\smsts.log'               = 'OS_AfterTS'
    }
    
    $lowerPath = $Path.ToLower()
    if ($mappings.ContainsKey($lowerPath)) {
        return $mappings[$lowerPath]
    }
    return 'UnknownPath'
}

function Check-LogFile {
    param (
        [string]$Path
    )
    if (Test-Path -Path $Path) {
        Write-Host "Found: $Path" -ForegroundColor Green
        return $Path
    } else {
        Write-Host "Unable to locate: $Path" -ForegroundColor Red
        return $null
    }
}

function Show-DiskSpace {
    Write-Host ''
    Write-Host "Available Drives:"
    $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3 -or $_.DriveType -eq 2}
    foreach ($drive in $drives) {
        $sizeGB = [math]::Round($drive.Size / 1GB, 2)
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $label = if ($drive.VolumeName) { $drive.VolumeName } else { "No Label" }
        Write-Host "  $($drive.DeviceID) $label - Size: $sizeGB GB, Free: $freeGB GB"
    }
}

function Get-OutputPath {
    do {
        Write-Host ''
        $filePath = Read-Host -Prompt "Enter the output path, or type 'exit' to quit"

        if ([string]::IsNullOrWhiteSpace($filePath)) {
            Write-Host ''
            Write-Host "Path cannot be empty. Please enter a valid path." -ForegroundColor Yellow
            Show-DiskSpace
            continue
        }
        
        try {
            $filePath = $filePath.Trim()
            if ($filePath -eq 'exit') {
                return $null
            } elseif (Test-Path -Path $filePath -PathType Container) {
                return $filePath
            } elseif (Test-Path -Path $filePath -PathType Leaf) {
                Write-Host ''
                Write-Host "Error: '$filePath' is a file, not a directory. Please enter a directory path." -ForegroundColor Red
                Show-DiskSpace
            } else {
                Write-Host ''
                Write-Host "Invalid directory path: $filePath" -ForegroundColor Red
                Write-Host "Path does not exist. Please check the path and try again." -ForegroundColor Yellow
                Show-DiskSpace
            }
        } catch {
            Write-Host ''
            Write-Host "Error with file path: $_" -ForegroundColor Red
            Show-DiskSpace
        }
    } while ($true)
}

function Check-SharedDrive {
    param (
        [string]$UNCPath,
        [string]$DriveRoot,
        [string]$Hostname
    )
    Write-Host ''
    Write-Host 'Checking for shared drive access'
    
    try {
        if (Test-Path $UNCPath -ErrorAction Stop) {
            Write-Host "Path is accessible: $UNCPath" -ForegroundColor Green
        } else {
            Write-Host 'Path not accessible, attempting to map T: drive' -ForegroundColor Yellow
            $tDrive = Get-PSDrive -Name "T" -ErrorAction SilentlyContinue
            if ($tDrive) {
                try {
                    Remove-PSDrive -Name "T" -Force -ErrorAction Stop
                } catch {
                    Write-Host "Failed to remove existing T: drive: $_" -ForegroundColor Red
                }
            }
        
            try {
                New-PSDrive -Name "T" -PSProvider FileSystem -Root $DriveRoot -Persist -Scope Global -ErrorAction Stop | Out-Null
                if (!(Test-Path $UNCPath -ErrorAction Stop)) {
                    return $null
                }
            } catch {
                Write-Host "Failed to map T: drive: $_" -ForegroundColor Red
                return $null
            }
        }
    } catch [System.UnauthorizedAccessException] {
        Write-Host 'Access denied' -ForegroundColor Red
        return $null
    } catch {
        Write-Host "Error accessing shared drive: $_" -ForegroundColor Red
        return $null
    }
    
    $outputUNCPath = "$UNCPath\$Hostname"
    
    try {
        if (!(Test-Path $outputUNCPath)) {
            New-Item -Path $outputUNCPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Host "Created hostname directory: $outputUNCPath" -ForegroundColor Cyan
        } else {
            Write-Host "Hostname directory already exists: $outputUNCPath" -ForegroundColor Cyan
        }
        
        return $outputUNCPath
    } catch {
        Write-Host "Failed to create hostname directory: $_" -ForegroundColor Red
        return $null
    }
}

#############
### START ###
#############

Clear-Host
Write-Host ''
Write-Host 'Checking for SCCM SMSTS log files'

foreach ($logFile in $logFiles) {
    $result = Check-LogFile -Path $logFile
    if ($result) {
        $validPaths += $result
        $filesFound++
    }
}

if ($driveInfo.DriveType -eq 2) {
    Write-Host ''
    Write-Host "Running from removable drive: $scriptDrive`:" -ForegroundColor Cyan
    $defaultUSBPath = "$($scriptPath)CollectedLogs\$hostname"
    Write-Host "USB collection path available: $defaultUSBPath" -ForegroundColor Cyan
}

if ($filesFound -gt 0) {
    if ($driveInfo.DriveType -eq 2) {
        Write-Host ''
        $useUSB = Read-Host "Save logs to USB drive at $scriptDrive`:? (Y/N)"
        if ($useUSB -eq 'Y' -or $useUSB -eq 'y') {
            if (!(Test-Path $defaultUSBPath)) {
                New-Item -Path $defaultUSBPath -ItemType Directory -Force | Out-Null
            }
            $finalOutputPath = $defaultUSBPath
            Write-Host "Saving to USB: $finalOutputPath" -ForegroundColor Green
        } else {
            $outputPath = Check-SharedDrive -UNCPath $uncLogPath -DriveRoot $driveRoot -Hostname $hostname
            if ($outputPath) {
                $finalOutputPath = $outputPath
            } else {
                Write-Host 'Shared drive not accessible, please provide an alternative path' -ForegroundColor Yellow
                $finalOutputPath = Get-OutputPath
            }
        }
    } else {
        $outputPath = Check-SharedDrive -UNCPath $uncLogPath -DriveRoot $driveRoot -Hostname $hostname
        if ($outputPath) {
            $finalOutputPath = $outputPath
        } else {
            Write-Host 'Shared drive not accessible, please provide an alternative path' -ForegroundColor Yellow
            $finalOutputPath = Get-OutputPath
        }
    }

    if ($finalOutputPath -ne $null) {
        $successCount = 0
        $failCount = 0
        Write-Host ''
        Write-Host 'Copying'
        
		foreach ($path in $validPaths) {
		    try {
                $fileNameOnly = Split-Path -Path $path -Leaf
		        $baseName     = [System.IO.Path]::GetFileNameWithoutExtension($fileNameOnly)
		        $ext          = [System.IO.Path]::GetExtension($fileNameOnly)

                $label = Get-LogLabel -Path $path

                $stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
                $fileName = "{0}_{1}_{2}{3}" -f $baseName, $label, $stamp, $ext

                $destination = Join-Path -Path $finalOutputPath -ChildPath $fileName
                Copy-Item -Path $path -Destination $destination -Force -ErrorAction Stop

                Write-Host "Successfully copied '$fileName' to '$finalOutputPath'" -ForegroundColor Green
                $successCount++
            } catch {
                Write-Host "Unable to copy '$path' to '$finalOutputPath' - $_" -ForegroundColor Red
                $failCount++
            }
        }
        
        Write-Host ''
        Write-Host "Copy Summary:"
        Write-Host "  Successfully copied $successCount of $filesFound" -ForegroundColor White
        if ($failCount -gt 0) {
            Write-Host "  Failed: $failCount of $filesFound" -ForegroundColor White
        }
        Write-Host "  Destination: $finalOutputPath" -ForegroundColor White
        Write-Host ''
        
        if ($successCount -eq $filesFound) {
            Write-Host 'Process completed successfully!' -ForegroundColor Green
        } elseif ($successCount -gt 0) {
            Write-Host 'Process completed with some errors' -ForegroundColor Yellow
        } else {
            Write-Host 'Process failed - no files were copied' -ForegroundColor Red
        }
    } else {
        Write-Host 'No output path selected, exiting' -ForegroundColor Yellow
    }
} else {
    Write-Host ''
    Write-Host 'No log files found to copy' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Press any key to exit' -ForegroundColor White
try {
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} catch {
    pause
} 

