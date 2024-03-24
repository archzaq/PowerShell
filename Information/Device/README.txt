DeviceReport_ImportCSV.ps1:
    This script allows for importing a large csv full of device hostnames and it will return another csv with information such as:
        Last logged in user
        Is the SCCM client installed
        Is it online
        Last login date
        IP address
        MAC address
        Serial number
        Windows build
        OU

DeviceReport_SinglePC.ps1:
    Use this script for a quick way to return relevant information for a single device rather than export to a csv.