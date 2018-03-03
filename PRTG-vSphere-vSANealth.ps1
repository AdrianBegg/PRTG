###############################################################################################
# Name: PRTG-vSphere-vSANealth.ps1
# Author: Adrian Begg (adrian.begg@ehloworld.com.au)
#
# Date: 03/03/2018
# Purpose: The purpose of the script is to provide a simple VSAN Health Check sensor
# for PRTG Network Monitoring.
#
# Requires: Roman Gelman (@rgelman75) VSAN.psm1 available at https://github.com/rgel/PowerCLi
###############################################################################################
[CmdletBinding()]
Param(
    [ValidateNotNullorEmpty()] [Parameter(Mandatory=$True)] [string] $vCenterServer,
    [ValidateNotNullorEmpty()] [Parameter(Mandatory=$True)] [string] $vSANCluster
)

#Functions
Function Write-PRTGError{
    <#
    .SYNOPSIS
    Returns an error which can be read by PRTG.

    .DESCRIPTION
    Returns an error which can be read by PRTG.

    .PARAMETER ErrorMessage
    A string which will be displayed to the user as an error message in PRTG.

    .EXAMPLE
    Write-PRTGError -ErrorMessage "An error occured running the sensor against the machine LABADDS1."

    Returns XML formated as requried by PRTG with the error message "An error occured running the sensor against the machine LABADDS1."

	.NOTES
	  NAME: Write-PRTGError
	  AUTHOR: Adrian Begg
	  LASTEDIT: 2018-01-22
	#>
    Param(
        [ValidateNotNullorEmpty()] [Parameter(Mandatory=$True)] [string] $ErrorMessage
    )
    Write-host "<?xml version=`"1.0`" encoding=`"Windows-1252`" ?>"
    write-host "<prtg>"
    Write-Host "<error>1</error>"
    Write-Host "<text>$ErrorMessage</text>"
    write-host "</prtg>"
    Break
    #Exit
}
function Write-PRTGSensor(){
    <#
    .SYNOPSIS
    Returns a PRTG Sensor constructed from channels created using the New-PRTGChannel cmdlet

    .DESCRIPTION
    Long description

    .PARAMETER PRTGChannels
    A collection of strings created using the New-PRTGChannel cmdlet

    .PARAMETER Message
    An option message to display with the channel (eg. "SMTP/tLS connection Successful with 200.")

    .EXAMPLE
    Write-PRTGSensor -PRTGChannels $prtgChannels

    Will output a correctly formed PRTG sensor formed from the PRTG Channels in the String collection $prtgChannels

    .NOTES
	  NAME: Write-PRTGSensor
	  AUTHOR: Adrian Begg
	  LASTEDIT: 2018-02-09
	#>
    #>
    Param(
        [ValidateNotNullOrEmpty()] [Parameter(Mandatory=$true)] [string[]] $PRTGChannels,
        [Parameter(Mandatory=$false)] [string] $Message
    )

    # Write the header for the PRTG sensor
    [string] $strPRTGOutput = "<?xml version=`"1.0`" encoding=`"Windows-1252`" ?>`n<prtg>`n"
    $strPRTGOutput += "<text>$Message</text>`n"

    # Construct from each of the provided channels the output
    foreach($strChannel in $PRTGChannels){
        $strPRTGOutput += $strChannel
    }
    # Write the trailer for the sensor
    $strPRTGOutput += "</prtg>"
    # Outputs the PRTG sensor to the console
    Write-Host $strPRTGOutput
}

function New-PRTGChannel(){
    <#
    .SYNOPSIS
    Returns a channel in XML format for a PRTG Sensor

    .DESCRIPTION
    Creates a channel for a PRTG Advanced XML/EXE sensor with the custom data provided.

    .PARAMETER Name
    The name of the channel

    .PARAMETER Value
    The Interger Value of the channel

    .PARAMETER ValueLookup
    A valid PRTG Lookup Type eg. oid.paessler.custom.windows.scheduledTaskStatus

    .PARAMETER LimitErrorMsg
    The error message to display when the channel exceeds the defined error limits. WARNING: This can not be set dynamically; the first set value is retained in PRTG

    .PARAMETER LimitWarningMsg
    The warning message to display when the channel exceeds the defined warning limits. WARNING: This can not be set dynamically; the first set value is retained in PRTG

    .PARAMETER LimitMaxError
    If the "Value" is higher then the "LimitMaxError" the channel will be marked as in an Error state and the defined LimitErrorMsg will be displayed for this sensor. The parent sensor will also go into an error state.

    NOTE: This value is not dynamic; if this value is provided the first value that PRTG recieves when the channel is created is the value that will persist forever. Generally it is recommended that instead of using these parameters that the channel settings are manually set.

    .PARAMETER LimitMinError
    If the "Value" is lower then the "LimitMinError" the channel will be marked as in an Error state and the defined LimitErrorMsg will be displayed for this sensor. The parent sensor will also go into an error state.

    NOTE: This value is not dynamic; if this value is provided the first value that PRTG recieves when the channel is created is the value that will persist forever. Generally it is recommended that instead of using these parameters that the channel settings are manually set.

    .PARAMETER LimitMaxWarn
    If the "Value" is higher then the "LimitMaxWarn" the channel will be marked as in an Warning state and the defined LimitWarningMsg will be displayed for this sensor. The parent sensor will also go into an Warning state.

    NOTE: This value is not dynamic; if this value is provided the first value that PRTG recieves when the channel is created is the value that will persist forever. Generally it is recommended that instead of using these parameters that the channel settings are manually set.

    .PARAMETER LimitMinWarn
    If the "Value" is lower then the "LimitMinWarn" the channel will be marked as in an Warning state and the defined LimitWarningMsg will be displayed for this sensor. The parent sensor will also go into an Warning state.

    NOTE: This value is not dynamic; if this value is provided the first value that PRTG recieves when the channel is created is the value that will persist forever. Generally it is recommended that instead of using these parameters that the channel settings are manually set.

    .EXAMPLE
    New-PRTGChannel -Name "Disk Status" -Value 20 -ValueLookup "oid.paessler.custom.hardware.diskstatus"

    Returns a PRTG Channel named "Disk Status" with a custom lookup type of "oid.paessler.custom.hardware.diskstatus" and a value of 20.

   .EXAMPLE
    New-PRTGChannel -Name "Disk Status" -Value 20 -ValueLookup "oid.paessler.custom.hardware.diskstatus" -LimitErrorMsg "The disk status is bad." -LimitWarningMsg "The disk status is getting bad." -LimitMaxError 25 -LimitMinError -1 -LimitMaxWarn 21 -LimitMinWarn 0

    Returns a PRTG Channel named "Disk Status" with a custom lookup type of "oid.paessler.custom.hardware.diskstatus" and a value of 20. The channel also has the channel Warning/Error limits set. These will be addative with the limits defined in the Custom Lookup. It is not recommended that these are defined unless required; the Error/Warning state can be controlled using the Custom Lookup type metadata.

    .EXAMPLE
    New-PRTGChannel -Name "Disk Status" -Value 10
    Returns a PRTG Channel named "Disk Status" with a value of 20.

    .EXAMPLE
    New-PRTGChannel -Name "Disk Status" -Value 10
    Returns a PRTG Channel named "Disk Status" with a value of 20.

    .NOTES
	  NAME: New-PRTGChannel
	  AUTHOR: Adrian Begg
	  LASTEDIT: 2018-02-09
	#>
    Param(
		[Parameter(Mandatory=$True,ParameterSetName = "ValueLookup")]
        [Parameter(Mandatory=$True,ParameterSetName = "Default")]
            [ValidateNotNullorEmpty()] [string] $Name,
            [ValidateRange(0,2147483647)] [int] $Value,
        [Parameter(Mandatory=$True,ParameterSetName = "ValueLookup")]
            [ValidateNotNullorEmpty()] [string] $ValueLookup,
        [Parameter(Mandatory=$False,ParameterSetName = "Default")]
            [ValidateNotNullorEmpty()] [string] $LimitErrorMsg,
        [Parameter(Mandatory=$False,ParameterSetName = "Default")]
            [ValidateNotNullorEmpty()] [string] $LimitWarningMsg,
        [Parameter(Mandatory=$False,ParameterSetName = "Default")]
            [ValidateRange(0,2147483647)] [int] $LimitMaxError,
        [Parameter(Mandatory=$False,ParameterSetName = "Default")]
            [ValidateRange(0,2147483647)] [int] $LimitMinError,
        [Parameter(Mandatory=$False,ParameterSetName = "Default")]
            [ValidateRange(0,2147483647)] [int] $LimitMaxWarn,
        [Parameter(Mandatory=$False,ParameterSetName = "Default")]
            [ValidateRange(0,2147483647)] [int] $LimitMinWarn
    )
    # Initalise the XML
    [string] $strPRTGChannel += "<result>`n<channel>$Name</channel>`n<unit>Custom</unit>`n<showChart>1</showChart>`n<showTable>1</showTable>"
    if($PSCmdlet.ParameterSetName -in ("ValueLookup")){
        $strPRTGChannel += "<value>$Value</value>`n<ValueLookup>$ValueLookup</ValueLookup>`n"
    } else {
        if($PSBoundParameters.ContainsKey("LimitMaxError")){
            $strPRTGChannel += "<LimitMaxError>$LimitMaxError</LimitMaxError>`n"
        }
        if ($PSBoundParameters.ContainsKey("LimitMinError")){
            $strPRTGChannel += "<LimitMinError>$LimitMinError</LimitMinError>`n"
        }
        if ($PSBoundParameters.ContainsKey("LimitMaxWarn")){
            $strPRTGChannel += "<LimitMaxWarning>$LimitMaxWarn</LimitMaxWarning>`n"
        }
        if ($PSBoundParameters.ContainsKey("LimitMinWarn")){
            $strPRTGChannel += "<LimitMinWarning>$LimitMinWarn</LimitMinWarning>`n"
        }
        if(!([string]::IsNullOrEmpty($LimitErrorMsg))){
            $strPRTGChannel += "<LimitErrorMsg>$LimitErrorMsg</LimitErrorMsg>`n"
        }
        if(!([string]::IsNullOrEmpty($LimitWarningMsg))){
            $strPRTGChannel += "<LimitWarningMsg>$LimitWarningMsg</LimitWarningMsg>`n"
        }
        # Add the values
        $strPRTGChannel += "<float>0</float>`n<value>$Value</value>`n"
    }
    # Write the trailer and return the string
    $strPRTGChannel += "</result>"
    $strPRTGChannel
}
Function Main{
    # Decalre a Hashtable for the Lookup Table Translations
    [HashTable] $prtgStatus = @{
        Green = 1
        Yellow  = 2
        Red = 3
        Unknown = 0
    }
    # Check if PowerCLI is installed on the machine running the cmdlet
    try {
        #Check installedmodule
        If ((Get-module -Name VMware.PowerCLI -ErrorAction SilentlyContinue) -eq $null){
            Import-Module VMware.PowerCLI -ErrorAction Stop
        }
    } catch {
        Write-PRTGError -ErrorMessage "Unable to load PowerCLI Modules. Please ensure PowerCLI is installed on the Probe running the sensor."
    }
        # Check if the VSAN Modile is installed in the current directory
    try {
        Import-Module "$PSScriptRoot\VSAN.psm1" -ErrorAction Stop
    } catch {
        Write-PRTGError -ErrorMessage "Unable to load Roman Gelman's VSAN Module. Please ensure that the file is in the working directory of the script."
    }

    # Attempt the connect to vCenter, uses the account of the Windows Credentials running the cmdlet
    try {
        Connect-VIServer $vCenterServer -WarningAction SilentlyContinue -ErrorAction Stop | out-null
    } catch {
        Write-PRTGError -ErrorMessage "Failed to connect to vCentre server $($vCenterServer)"
    }

    # Next try and query the vCenter for the VSAN Cluster
    try {
        $objCluser = Get-Cluster -Name $vSANCluster
    } catch {
        Write-PRTGError -ErrorMessage "An error occured when querying the Cluster $($vSANCluster) on vCenter $($server)"
    }
    try{
        # Get the Health Summary
        $objvSANSummary = Get-VSANHealthSummary -Cluster $objCluser
        $colVSANHealthTest = Invoke-VSANHealthCheck -Cluster $objCluser -Level "Test"
        $colVSANHealthOverview = Invoke-VSANHealthCheck -Cluster $objCluser
        $colvSANDisks = Get-VsanDiskGroup -Cluster $objCluser
        $vSANFreeSpace = Get-VsanSpaceUsage -Cluster $objCluser
    } catch {
        Write-PRTGError -ErrorMessage "An error occured when querying the VSAN Objects for Health Status"
    }

    # Construct the Channels for the cluster
    [System.Collections.ArrayList] $arrChannels = New-object System.Collections.Arraylist
    [string] $strSensorMessage = ""

    $channelFreeDiskSpace = New-PRTGChannel -Name "$($objvSANSummary.Cluster) - Free Disk Space (GB)" -Value $vSANFreeSpace.FreeSpaceGB
    $arrChannels.Add($channelFreeDiskSpace) > $null
    $channelDiskTotal = New-PRTGChannel -Name "$($objvSANSummary.Cluster) - VSAN Capacity (GB)" -Value $vSANFreeSpace.CapacityGB
    $arrChannels.Add($channelDiskTotal) > $null
    $channelOverallHealth = New-PRTGChannel -Name "$($objvSANSummary.Cluster) - Overall Health" -Value ($prtgStatus.($objvSANSummary.OverallHealth)) -ValueLookup "prtg.customlookups.vsan.status"
    $arrChannels.Add($channelOverallHealth) > $null

    foreach($objGroup in $colVSANHealthOverview){
        if($objGroup.TestGroup.StartsWith("Online health")){
            $strTestName = "Online health"
        } else {
            $strTestName = $objGroup.TestGroup
        }
        $channelHealthOverview = New-PRTGChannel -Name "$($objGroup.Cluster) - $strTestName" -Value ($prtgStatus.($($objGroup.Health))) -ValueLookup "prtg.customlookups.vsan.status"
        $arrChannels.Add($channelHealthOverview)  > $null
    }

    # Now get the messagses for any tests that failed
    $colFailedChecks = $colVSANHealthTest | ?{$_.Health -notin ("Green","Skipped")}
    foreach($objTest in $colFailedChecks){
        $strSensorMessage += "[VSAN Cluster:$($objTest.Cluster) - $($objTest.Test):$($objTest.Health)] "
    }

    # Write a channel for each disk in the vSAN Cluster
    foreach($objVSANDiskGroup in $colvSANDisks){
        # Report the status of the Capacity Tier Disks
        foreach($objCapacityDisk in $objVSANDiskGroup.ExtensionData.NonSsd){
            # Need to Sanitise the DG name to reduce the size of the channel name
            $strChannelName = "[$($objVSANDiskGroup.VMHost.Name)] VSAN Disk Status (UUID: $($objCapacityDisk.VSANDiskInfo.VSAnUuid))"
            $intDiskStatus = 0
            if($objCapacityDisk.OperationalState -eq "ok"){
                $intDiskStatus = 1
            } elseif($objCapacityDisk.OperationalState -eq "degraded") {
                $intDiskStatus = 3
            }
            $channelDiskHealth = New-PRTGChannel -Name $strChannelName -Value $intDiskStatus -ValueLookup "prtg.customlookups.vsan.status"
            $arrChannels.Add($channelDiskHealth)  > $null

            $prtgStatus.($objCapacityDisk.OperationalState)
        }
        # Report the status of the Flash Tier Disks
        foreach($objFlashCacheDisk in $objVSANDiskGroup.ExtensionData.Ssd){
            $strChannelName = "[$($objVSANDiskGroup.VMHost.Name)] VSAN Disk Status (UUID: $($objFlashCacheDisk.VSANDiskInfo.VSAnUuid))"
            $intDiskStatus = 0
            if($objFlashCacheDisk.OperationalState -eq "ok"){
                $intDiskStatus = 1
            } elseif($objFlashCacheDisk.OperationalState -eq "degraded") {
                $intDiskStatus = 3
            }
            $channelDiskHealth = New-PRTGChannel -Name $strChannelName -Value $intDiskStatus -ValueLookup "prtg.customlookups.vsan.status"
            $arrChannels.Add($channelDiskHealth)  > $null
        }
    }
    # Trim the trailing space
    $strSensorMessage = $strSensorMessage.TrimEnd(" ")
    Write-PRTGSensor -PRTGChannels $arrChannels -Message $strSensorMessage
    Disconnect-VIServer -Confirm:$false
}

# Call the Main Method
Main