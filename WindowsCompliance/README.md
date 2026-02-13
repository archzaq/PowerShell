# Windows Version Compliance

## UnsupportedWindows10Builds.ps1
Runs daily against an SCCM collection of devices on unsupported Windows versions. Finds any that were online in the last 24 hours and emails a CSV report.

## WindowsVersionCompliance.ps1
Counts devices in an SCCM collection and breaks them down by supported vs unsupported Windows versions (7, 8, 10, 11).
