function global:Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$FilePath = "C:\Users\nakan\Downloads\PowerShell_Study\PowerShell_Study\log.txt",
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Add-content $FilePath -value $Message
}
function global:Toast {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Template
    )

    $appId = $(Get-StartApps | Where-Object {$_.Name -eq "Windows PowerShell"}).AppId

    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
    
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($Template)

    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($xml)
}

function global:Action {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSEventArgs]$Event
    )
    $changedFileName = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    $timeStamp = $Event.TimeGenerated
    $Folder = $Event.MessageData
    $template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text hint-maxLines="1">File is $changeType.</text>
            <text>$changedFileName [$timeStamp]</text>
        </binding>
    </visual>
    <actions>
        <action activationType="protocol" content="open folder" arguments="file://$Folder"/>
    </actions>
</toast>
"@
    Toast -Template $template
}

function Register-TaskRunner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$EventName,
        [Parameter(Mandatory=$true)]
        [string]$Folder,
        [Parameter(Mandatory=$false)]
        [string]$Filter = "*.txt"
    )

    $VerbosePreference = "Continue"

    Log -Message "Folder: $Folder Filter: $Filter"

    $watcher = New-Object IO.FileSystemWatcher -Property @{ 
        Path = $Folder
        Filter = $Filter
        NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName
        IncludeSubdirectories = $false
        EnableRaisingEvents = $true
    }

    $null = Register-ObjectEvent -InputObject $watcher `
                         -EventName $EventName `
                         -Action {Action -Event $Event} `
                         -MessageData $Folder
}

Get-EventSubscriber | Unregister-Event
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Register-TaskRunner -EventName "Created" -Folder $here'\storage'
Register-TaskRunner -EventName "Changed" -Folder $here'\storage'
