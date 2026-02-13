# BitLocker Scripts
## bitlocker_ExportKeysEmail.ps1
Looks in Active Directory for all available BitLocker recovery keys and adds other device info from SCCM and AD. Exports everything to a CSV and emails it out. Intended to run on a monthly basis.

## bitlocker_KeyCountByOU.ps1
Counts all BitLocker recovery keys in Active Directory and displays a summary table of key counts broken down by OU.
