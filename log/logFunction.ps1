# Usage : Write-Log -Level "INFO" -Message "AD Module imported" -logfile $logfile
# 1-Create a variable for the log file, if not specified, logs will apear on the console : 
# $logfile="C:\logFile.txt"
# 2- Copy and paste this function to your script 
# 3- Use it like this :  
# Write-Log -Level "INFO" -Message "Info message" -logfile $logfile
# Write-Log -Level "WARN" -Message "Warning Message" -logfile $logfile
# etc .. Level can be : "INFO","WARN","ERROR","FATAL","DEBUG"


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
