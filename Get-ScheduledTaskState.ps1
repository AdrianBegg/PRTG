##########################################################################################
# Name: Get-ScheduledTaskState.ps1
# Author: Adrian Begg (adrian.begg@ehloworld.com.au)
#
# Date: 19/04/2017
# Purpose: The purpose of the script is to monitor the Task Scheduler on a remotely
# remote machine. Returns a channel for each task. Requires the custom lookup installed 
# oid.passler.custom.windows.scheduledTaskStatus.ovl
##########################################################################################
# Use from PRTG, 
#
# Required flags
# -computer "ComputerName"
#
#Optional flags
# -TaskPath "\"
#
#Examples

# Get all the tasks for the Root level only for machine LABADDS1
#.\Get-ScheduledTaskState -Computer "LABADDS1" -TaskPath "\" 

# Get all the tasks for machine LABADDS1
# .\Get-ScheduledTaskState -Computer "LABADDS1"

# Get all the tasks for the folder "Centricity" for machine LABADDS1
#.\Get-ScheduledTaskState -Computer "LABADDS1" -TaskPath "\Centricity\" 

Param(
	[Parameter(Mandatory=$True)] [string] $Computer,
	[Parameter(Mandatory=$false)] [string] $TaskPath
	)

#Functions
Function PRTGError($errormsg){ # Return Friendly Error Message to PRTG
        Write-host "<?xml version=`"1.0`" encoding=`"Windows-1252`" ?>"
        write-host "<prtg>"
        Write-Host "<error>1</error>"
        Write-Host "<text>$errormsg</text>"
        write-host "</prtg>"
        Exit
}

# A parameter to deterermine if a filter should be applied
[bool]$TaskPathFilter = $false;

# Parameter Checking
If ([string]$TaskPath.Length -ne 0){ $TaskPathFilter = $true }

# Attempt to establish a PowerShell Session with the Remote Machine
try{
	$session = New-PSSession -computerName $Computer
} catch {
	PRTGError "Failed to connect to machine via Remote Powershell $($Computer)"
}

# Next we need to create a ScriptBlock object which will be executed remotely (need to use a static method for the second
[ScriptBlock] $srBlkGetTasks = { Get-ScheduledTask }
if($TaskPathFilter){
	[string] $strScriptBlockWithFilter = "Get-ScheduledTask | ?{$`_.TaskPath -eq '$($TaskPath)'}"
	[ScriptBlock] $srBlkGetTasks = [ScriptBlock]::Create($strScriptBlockWithFilter)
}

# Next get the scheduled tasks
try{
	$scheduledTasks = Invoke-Command -Session $session -ScriptBlock $srBlkGetTasks
} catch {
	PRTGError "Failed to execute the Command to Get Scheduled tasks on the machine $($Computer)"
}
if($scheduledTasks -eq $null){
	PRTGError "No scheduled tasks were returned; please check the TaskPath provided and try again"
}

# Initialise Output XML for PRTG
[string] $strPRTGChannelOutput = @"
<?xml version=`"1.0`" encoding=`"Windows-1252`" ?>
<prtg>
"@

foreach($task in $scheduledTasks){
	# Now add the output as a channel
	[int]$taskState = 3
	# Ready
	if($task.State -eq 3){
		$taskState = 0
	}
	# Running 
	if($task.State -eq 4){
		$taskState = 1
	} 
	# Disabled
	if($task.State -eq 1){
		$taskState = 2
	}
	$strPRTGChannelOutput += @"
<result><channel>$($task.TaskName)</channel>
	<unit>Custom</unit>
	<showChart>1</showChart>
	<showTable>1</showTable>
	<value>$taskState</value>
	<ValueLookup>oid.paessler.custom.windows.scheduledTaskStatus</ValueLookup>
</result>
"@
}

# Finally if no exceptions have been thrown then return the result; write the trailer and output the result
$strPRTGChannelOutput += @"
</prtg>
"@
Write-Host $strPRTGChannelOutput

# Close the connection	
Disconnect-PSSession $session > $nul