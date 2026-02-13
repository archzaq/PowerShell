# PowerShell Scripts
A collection of PowerShell scripts for device management, reporting, and administration.

## Folders
- **BitLocker/** - BitLocker recovery key export and reporting
- **Device/** - Device detail reports (bulk CSV import or single PC lookup)
- **User/** - AD user account lookups
- **WindowsCompliance/** - Windows version tracking and unsupported build reporting

## Scripts
### set_autoLogon.ps1
Configures Windows auto-logon by setting registry keys. Backs up the registry before making changes and verifies the configuration after.

### grab_SMSTSLogs.ps1
Collects SCCM task sequence (SMSTS) log files from all known locations on a device and copies them to a shared drive or USB.
