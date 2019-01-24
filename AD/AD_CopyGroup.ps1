#Usage : .\AD_CopyGroup.ps1 -groupNameSrc "Source Group" -groupNameDest "Destination Group" -logfile "C:\temp\log.txt"
#Exit Code :
#0 = Success 
#1 = Error with the import module function 
#2 = The group does not exist


Param (
  [parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[String]$groupNameSrc,

  [parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[String]$groupNameDest,

  [parameter(Mandatory = $false)]
	[ValidateNotNullOrEmpty()]
	[String]$logfile
  #is log file is not specified, event will comme to host
    
)

Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$False)]
    [string]
    $logfile
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Level $Message"
    If($logfile) {
        Add-Content $logfile -Value $Line
    }
    Else {
        if ($Level -eq "FATAL" -or $Level -eq "ERROR"  ) {Write-Host $Line -ForegroundColor Red} 
        elseif ($Level -eq "WARN" ) {Write-Host $Line -ForegroundColor Yellow} 
        elseif ($Level -eq "DEBUG" ) {Write-Host $Line -ForegroundColor Green} 
        else {Write-Output $Line }
        
    }
}

Function CleanLogFile {
  param(
    [STRING]$logfile
    )
try {
    if (get-item $logfile -ErrorAction SilentlyContinue){ Remove-item $logfile -force } 
    Write-Log -Level "INFO" -Message "Old Log file removed, a new one as been created on $($logfile)" -logfile $logfile
    }
    catch {
    Write-Log -Level "INFO" -Message "Old Log file didn't exist a new one will was created" -logfile $logfile
    }
}

Function importPowershellAD {
try {
    Import-module ActiveDirectory -ErrorAction Stop
    }
catch {
    Write-Log -Level "FATAL" -Message "AD module not imported. Error Message : $($_.Exception.Message)" -logfile $logfile
    exit 1
    }
Write-Log -Level "INFO" -Message "AD Module imported" -logfile $logfile}

Function CheckADGroup{
  param(
    [STRING]$groupName
    )
try {
    $groupExist = Get-ADGroup -identity $groupName -ErrorAction Stop
    }
catch {
    Write-Log -Level "FATAL" -Message "AD Group $($groupName) not found. Error Message : $($_.Exception.Message)" -logfile $logfile
    exit 2
    }
Write-Log -Level "INFO" -Message "AD Group $($groupName) exist" -logfile $logfile
}


function addUsers{ 
  param(
    [STRING]$groupNameSrc,
    [STRING]$groupNameDest
    )
    $count=0
    $countError=0
    $Target = Get-ADGroupMember -Identity $groupNameSrc -Recursive  
    foreach ($Person in $Target) {  
        try
        {
        Add-ADGroupMember -Identity $groupNameDest -Members $Person.distinguishedname -Credential $AdminCredentials
        Write-Log -Level "INFO" -Message "User : $($Person.distinguishedname) Was added in the group $($groupNameDest)" -logfile $logfile
        $count=$count+1
        }
        catch
        {

         Write-Log -Level "WARN" -Message "The user $($Person.distinguishedname) was not added in the group $($groupNameDest)" -logfile $logfile
         Write-Log -Level "ERROR" -Message "UNEXEPECTED Error Message : $($_.Exception.Message)" -logfile $logfile
         $countError=$countError+1       
        }
    }  
    Write-Log -Level "INFO" -Message " $($count) Users added in the group $($groupNameDest)" -logfile $logfile
    Write-Log -Level "ERROR" -Message " $($countError) Errors" -logfile $logfile
       
}
 

####################################################################################################
##########################################Main #####################################################

#Clean up the log file
CleanLogFile ($logfile)
Write-Log -Level "INFO" -Message "Script begining, written by dana23746" -logfile $logfile

#Prerequisite 
$AdminCredentials = Get-Credential ""
###Import AD Module 
importPowershellAD
###Check if AD Group Exist 
CheckADGroup -groupName $groupNameSrc 
CheckADGroup -groupName $groupNameDest 

#add the users from the Source Group to the destination group
addUsers -groupNameSrc $groupNameSrc -groupNameDest $groupNameDest

exit 0
