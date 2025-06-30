
# Dear Windows,

# Receive username and password as external parameters
param(
    [Parameter(HelpMessage="Username for auto-logon")]
    [string]$Username,
    
    [Parameter(HelpMessage="Password for auto-logon")]
    [string]$Password
)

$keyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

# Check the script is being ran as Admin
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Backup registry location where changes are being made
function Backup-Registry {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $backupDir = "$env:USERPROFILE\Desktop\RegistryBackups"
    
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }
    
    $backupFile = "$backupDir\Winlogon_Backup_$timestamp.reg"
    $keyToBackup = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    
    try {
        reg export "$keyToBackup" "$backupFile" /y 2>&1 | Out-Null
        Write-Host "Registry backup saved to: $backupFile" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create registry backup: $_" -ForegroundColor Red
        pause
        exit 1
    }
}
# Ensure a username and password is set
function Get-Credentials {
    if (-not $Username) {
        $Username = Read-Host "Enter username for auto-logon"
    }
    
    if (-not $Password) {
        $Password = Read-Host "Enter password for auto-logon"
    }
    
    return @{
        Username = $Username
        Password = $Password
    }
}

function Get-RegistryStatus {
    param(
        [hashtable]$Credentials
    )

    Write-Host "`n"
    $regValues = Get-ItemProperty -Path $keyPath
    $userDone = $false
    $passDone = $false
    $logonDone = $false

    Write-Host "===== Registry Status =====" -ForegroundColor Cyan
    if ($Credentials -and $regValues.DefaultUserName -eq $Credentials.Username) {
        Write-Host "Username: $($regValues.DefaultUserName)" -ForegroundColor Green
        $userDone = $true
    } elseif ($regValues.DefaultUserName) {
        Write-Host "Username: $($regValues.DefaultUserName)" -ForegroundColor Yellow
    } else {
        Write-Host "Username: [Not Set]" -ForegroundColor Red
    }

    if ($Credentials -and $regValues.DefaultPassword -eq $Credentials.Password) {
        Write-Host "Password: [Configured Correctly]" -ForegroundColor Green
        $passDone = $true
    } elseif ($regValues.DefaultPassword) {
        Write-Host "Password: [Configured]" -ForegroundColor Yellow
    } else {
        Write-Host "Password: [Not Set]" -ForegroundColor Red
    }

    if ($regValues.AutoAdminLogon -eq "1") {
        Write-Host "AutoAdminLogon: Enabled" -ForegroundColor Green
        $logonDone = $true
    } else {
        Write-Host "AutoAdminLogon: Disabled" -ForegroundColor Red
    }
    Write-Host "`n"

    return ($userDone -and $passDone -and $logonDone)
}

# Change registry properties to desired settings
function Set-AutoLogon {
    param(
        [hashtable]$Credentials
    )
    
    Write-Host "===== Configuring Registry =====" -ForegroundColor Cyan
    try {
        Set-ItemProperty -Path $keyPath -Name "DefaultUserName" -Value $Credentials.Username -ErrorAction Stop
        Write-Host "DefaultUserName configured" -ForegroundColor Green
        
        Set-ItemProperty -Path $keyPath -Name "DefaultPassword" -Value $Credentials.Password -ErrorAction Stop
        Write-Host "DefaultPassword configured" -ForegroundColor Green
        
        Set-ItemProperty -Path $keyPath -Name "AutoAdminLogon" -Value "1" -ErrorAction Stop
        Write-Host "AutoAdminLogon configured" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Host "Failed to configure auto-logon: $_" -ForegroundColor Red
        return $false
    }
}

### MAIN ###
function Start-Main {
    if (-not (Test-IsAdmin)) {
        Write-Host "`n"
        Write-Host "Please run this script as Administrator." -ForegroundColor Red
        Write-Host "`n"
        pause
        exit 1
    }

    if (Test-Path $keyPath) {
        Backup-Registry

        $creds = Get-Credentials
        $isConfigured = Get-RegistryStatus -Credentials $creds

        if (-not $isConfigured) {
            if (Set-AutoLogon -Credentials $creds) {
                Get-RegistryStatus -Credentials $creds | Out-Null
                $creds.Password = $null
                Write-Host "Process completed!" -ForegroundColor Green
                pause
            } else {
                Write-Host "Process failed!" -ForegroundColor Red
                pause
                exit 1
            }
        } else {
            Write-Host "Auto-logon is already properly configured!" -ForegroundColor Green
            pause
        }
    } else {
        Write-Output "Registry key path does not exist"
        pause
        exit 1
    }

    exit
}

Start-Main
