Param(
  [switch]$recurse
)

Function writeEventLog {
    param([string]$source, [string]$errorMessage, [System.Diagnostics.EventLogEntryType] $eventLogEntryType)
    
    $windowsEventLog = new-object System.Diagnostics.EventLog('Application')
	$windowsEventLog.MachineName = "."
	$windowsEventLog.Source = $source
	$windowsEventLog.WriteEntry("An error occured : " + $errorMessage, $eventLogEntryType)

}

try
{
    $currentDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition

    if (Test-Path "$currentDirectory\DeleteLog_config.ps1")
    {
        # Get Informations about log folders from configuration file
        $logFoldersInfo = Get-Content $currentDirectory\DeleteLog_config.ps1
        
        # Exclude first line
        $i=1
        while ($i -lt $logFoldersInfo.Length)
        {
            try
            {
                $daysToKeep = $logFoldersInfo[$i].split('|')[0]
                [string[]]$included_extensions = $logFoldersInfo[$i].split('|')[1].split(',')
                [string[]]$excluded_extensions = $logFoldersInfo[$i].split('|')[2].split(',')
                $logFolder = $logFoldersInfo[$i].split('|')[3]
                
                $included_extensionPattern = ""
                $excluded_extensionPattern = ""

                # Included extension
                if ($included_extensions -ne $null)
                { 
                    foreach($extension in $included_extensions)
                    {
                        $included_extensionPattern += "^.$extension`$|"
                    }
                    # delete last pipe
                    $included_extensionPattern = $included_extensionPattern.remove($included_extensionPattern.Length - 1)
                }

                # Excluded extension
                if ($excluded_extensions -ne $null)
                { 
                    foreach($extension in $excluded_extensions)
                    {
                        $excluded_extensionPattern += "*.$extension|"
                    }
                    # delete last pipe
                    $excluded_extensionPattern = $excluded_extensionPattern.remove($excluded_extensionPattern.Length - 1)
                }
            
                if (Test-Path $logFolder)
                {
                    # Recursive - Folder
                    if ($recurse)
                    {
                        Get-ChildItem $logFolder -Exclude $excluded_extensionPattern -Recurse  | ? {$_.mode -like "-a---*" -and ($_.LastWriteTime -lt (Get-Date).adddays(-$daysToKeep)) -and $_.Extension -match $included_extensionPattern } | Remove-Item -Force
                    }
                    # Not recursive
                    Get-ChildItem $logFolder -Exclude $excluded_extensionPattern | ? {$_.mode -like "-a---*" -and ($_.LastWriteTime -lt (Get-Date).adddays(-$daysToKeep)) -and $_.Extension -match $included_extensionPattern} | Remove-Item -Force
                }
            }
            catch [System.exception]
            {
                writeEventLog "DeleteLog" $_.Exception.Message ([System.Diagnostics.EventLogEntryType]::Error)
            }
            $i++
        }
        
    }
}
catch [System.exception]
{
    writeEventLog "DeleteLog" $_.Exception.Message ([System.Diagnostics.EventLogEntryType]::Error)
}