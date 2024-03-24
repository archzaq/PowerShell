UnsupportedWindows10Builds.ps1:
    This script looks at a collection in SCCM that contains devices on unsupported versions of Windows, with that, it checks for any of those devices to have been online within the last 24 hours. The script runs daily, so any device that turns on will be added to a csv and sent in an email the following day.

WindowsVersionCompliance.ps1:
    This script looks at a collection in SCCM that contains all the devices we push updates to then returns a count of the supported and unsupported versions of Windows that are out there.