function Reset-UserForward { 
<#
.SYNOPSIS
This command will be run when a user is terminated.
.DESCRIPTION
The Reset-UserForward commandlet will add the person to the Orgs-O365-Exchange-Online group, enable the mailbox, hide the email address from the address list,
connect to exchange online, set retention policy to 90 days, set the forwarding address, match the exchange GUID, show the forwarding address, schedule a Job
to remove the mailbox 30 days henceforth.
.PARAMETER TUDName
Get the Display Name for the Termed User and paste/type here.
.PARAMETER TUUPN
Get the User logon name (UPN) from Active Directory and paste/type here.
.PARAMETER RUDName
Get the Display Name for the User receiving forwarded email from Active Directory and paste/type here.
.PARAMETER RUUPN
Get the User Logon name (UPN) for the user recieving forwarded email from Active Directory and paste/type here.
.PARAMETER TaskNumber
Get the TaskNumber from the SOM ticket and paste/type here.
.PARAMETER Requester
Enter the first name of the person makeing the request. Use the first name only
.PARAMETER RequesterUPN
Enter the User logon name (UPN) of the person making the request. 
.EXAMPLE
Reset-UserForward
Will prompt for 
.EXAMPLE
Reset-UserForward -TUDName Mary Jones -TUUPN mjones -RUDName Billy Smith -RUUPN bsmith -TaskNumber TASK1234567 -Requester Jane -RequesterUPN jdoe
Enter the TUDName TUUPN RUDName RUUPN TaskNumber Requester RequesterUPN parameters
.INPUTS
Types of objects input
.OUTPUTS
Types of objects returned
.NOTES
My notes.
.LINK
http://
.COMPONENT
.ROLE
.FUNCTIONALITY
#>
    [alias('ruf')]
    [cmdletbinding()]
    Param(
        [parameter(Mandatory=$True,HelpMessage="Enter termed user's Display Name without quotes, like: Mary Jones")]
        [string]$TUDName = (Read-Host "Enter Display Name without quotes, like: Mary Jones"),

        [parameter(Mandatory=$True,HelpMessage="Enter the termed user's UPN without quotes, like: mjones")]
        [string]$TUUPN = (Read-Host "Enter User Logon Name without quotes, like: mjones"),

        [parameter(Mandatory=$True,HelpMessage="Enter the receiving user's Display Name without quotes, like: Mary Jones")]
        [string]$RUDName = (Read-Host "Enter Recieving users Display Name without quotes, like: Mary Jones"),

        [parameter(Mandatory=$True,HelpMessage="Enter the receiving user's UPN without quotes, like mjones")]
        [string]$RUUPN = (Read-Host "Enter the receiving User Logon Name without quotes, like mjones"),
        
        [parameter(Mandatory=$True,HelpMessage="Enter the Task Number without quotes, like TASK1234567")]
        [string]$TaskNumber = (Read-Host "Enter the Task Number without quotes, like TASK1234567"),

        [parameter(Mandatory=$True,HelpMessage="Enter the name of the user requesting the action without quotes, like Mary Jones")]
        [string]$Requester = (Read-Host "Enter the Task Number without quotes, like Mary Jones"),

        [parameter(Mandatory=$True,HelpMessage="Enter the UPN of the user requesting the action, like MJones")]
        [string]$RequesterUPN = (Read-Host "Enter the Task Number without quotes, like MJones")
        
        )       
   
    #Connect to ExchangeOnPrem
    Powershell.exe -executionpolicy remotesigned -File "C:\Users\jyourname\OneDrive\Documents\Joe\ConnectToExchangeOnPrem.ps1"  

    #Connect to Exchange online
    $CertThumbPrnt = import-clixml "c:\KeyPath\CertificateThumbPrint.xml"
    $EXOAppID = import-clixml "c:\KeyPath\EXOAppID.xml"
    Connect-ExchangeOnline -CertificateThumbPrint "$CertThumbPrnt" -AppID "$EXOAppID" -Organization "yourcorp.onmicrosoft.com"

    #Connect Connect-IPPSSession
    $jayournameCred = Import-Clixml "C:\keypath\jayournamecred.xml"
    Connect-IPPSSession -Credential $jayournamecred

    #Hide name from the address list.
    Set-ADUser -Identity "$TUUPN" -Add @{msExchHideFromAddressLists="TRUE"}
            
    #set the retention policy
    Set-Mailbox -Identity "$TUUPN@yourcorp.com" -RetentionPolicy "90 Day Delete"

    #set the mailbox GUID
    $ExGuid = (Get-Mailbox -Identity "$TUUPN@yourcorp.com").ExchangeGUID
    $ExGuid
    #do {
        #Set-RemoteMailbox -Identity "$TUUPN@yourcorp.com" -ExchangeGuid $ExGuid -DomainController dc1.wxyz.yourcorp.com
    $RExGuid = (Get-RemoteMailbox -Identity "$TUUPN@yourcorp.com").ExchangeGUID
    $RExGuid
        #} until ($RExGuid -eq $ExGuid)

    #set the archivce GUID
    $ArchGuid = (Get-Mailbox -Identity "$TUUPN@yourcorp.com").ArchiveGuid
    $ArchGuid
    #do {
        #Set-RemoteMailbox -Identity "$TUUPN@yourcorp.com" -ArchiveGuid $ArchGuid -DomainController dc1.wxyz.yourcorp.com
    $RArchGuid = (Get-RemoteMailbox -Identity "$TUUPN@yourcorp.com").ArchiveGuid
    $RArchGuid
        #} until ($RArchGuid -eq $ArchGuid)

    #set the forwarding address.
    Set-Mailbox -Identity "$TUUPN@yourcorp.com" -ForwardingAddress "$RUUPN@yourcorp.com" -DeliverToMailboxAndForward $true

    #Remove All Holds on Mailbox.
    Set-Mailbox -Identity $TUUPN@yourcorp.com -RemoveDelayReleaseHoldApplied
    Set-Mailbox -Identity $TUUPN@yourcorp.com -RemoveDelayHoldApplied

    #Set the Teams Compliance Exception Policy
    Set-RetentionCompliancePolicy -Identity "Teams Chat - 30 day retention" -AddTeamsChatLocationException $TUUPN
       
    #display the results, show the SMTP address and forwarding address.
    Get-ADUser $TUUPN -Properties proxyAddresses | Select-Object -ExpandProperty proxyaddresses
    Get-ADUser -Identity $TUUPN -Properties msExchHideFromAddressLists
    Get-Mailbox -Identity "$TUUPN@yourcorp.com" | Select-Object -Property ForwardingAddress,ForwardingSmtpAddress | Out-String -Stream | sort
    Get-Mailbox -Identity  $TUUPN | fl *Hold*
    Get-RemoteMailbox -Identity "$TUUPN@yourcorp.com" -DomainController azwesdc01.wxyz.yourcorp.com | select Name,ExchangeGuid
       
    #create PS1 with the Value only of the user. used ::Create to insert the variable 
 
    #Shows the value only of the users.This appears to display the variable correctly in the script block.  
    $VUserLN = get-variable TUUPN -ValueOnly 

    #create the script block to run for the scheduled task.  Add the snappin exchange to enalble the exhchange cmdlets.

    $ScriptBlock = [ScriptBlock]::Create("Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
Disable-RemoteMailbox -Identity $VUserLN@yourcorp.com -archive -confirm:`$false
Disable-mailbox -Identity $VUserLN@yourcorp.com -archive -confirm:`$false ")

    $ScriptBlock  | Out-File -FilePath C:\Temp\DisableArchive_$VUserLN.ps1

    $ScriptBlock2 = [ScriptBlock]::Create("Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
Disable-RemoteMailbox -Identity $VUserLN@yourcorp.com -confirm:`$false")

    $ScriptBlock2  | Out-File -FilePath C:\Temp\DisabledMailbox_$VUserLN.ps1

    $ScriptBlock3 = [ScriptBlock]::Create("Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
Remove-ADGroupMember -Identity O365-Exchange-Online -Members $VUserLN -confirm:`$false")

    $ScriptBlock3  | Out-File -FilePath C:\Temp\RemoveLicense_$VUserLN.ps1

    #Get Creds to setup Scheduled Job
    $cred = Import-CliXml -Path 'C:\keypath\cred.xml'
        
    #Get the current date/time
    $CurrentTime = Get-Date

    #Scheduled powershell job to disable archive.
    $TriggerTime_DisableArchive = $CurrentTime.AddMinutes(43287)
    $jo = New-ScheduledJobOption -RunElevated
    $jt = New-JobTrigger -Once -At $TriggerTime_DisableArchive
    $jd = Register-ScheduledJob -Name "$TUUPN - Disable Archive" -ScheduledJobOption $jo -Trigger $jt -ScriptBlock $scriptblock -Credential $cred

    #Scheduled powershell job to disable mailbox.
    $TriggerTime_DisableMailbox = $CurrentTime.AddMinutes(43767)
    $jo = New-ScheduledJobOption -RunElevated
    $jt = New-JobTrigger -Once -At $TriggerTime_DisableMailbox
    $jd = Register-ScheduledJob -Name "$TUUPN - Disable Mailbox" -ScheduledJobOption $jo -Trigger $jt -ScriptBlock $scriptblock2 -Credential $cred    

    #Scheduled powershell job to remove license.
    $TriggerTime_RemoveLicense = $CurrentTime.AddMinutes(44247)
    $jo = New-ScheduledJobOption -RunElevated
    $jt = New-JobTrigger -Once -At $TriggerTime_RemoveLicense
    $jd = Register-ScheduledJob -Name "$TUUPN - Remove License" -ScheduledJobOption $jo -Trigger $jt -ScriptBlock $scriptblock3 -Credential $cred
    
    #Send Mail Message to the mail team that the job has been scheduled.
    $SMTPServer = "smtp.office365.com"
    $SMTPPort = "587"
    $credential = Import-CliXml -Path 'C:\keypath\yournamecred.xml'
    $From = "Automated <yourname@yourcorp.com>"
    $Subject = "Scheduled jobs registered for $TUUPN - $TaskNumber"
    $Body = 
"A scheduled registered job to disable the archive was created for: $TriggerTime_DisableArchive
A scheduled registered job to disable the mailbox was created for: $TriggerTime_DisableMailbox
A scheduled registered job to remove the O365 license was created for: $TriggerTime_RemoveLicense
Job Purposes: Disable Archive, Disable Mailbox, Remove License
Requested by: $Requester
For Termed User: $TUUPN
Tasknumber: $TaskNumber"
    

    Send-MailMessage -From $From -To "distributionlist@yourcorp.com" -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential $Credential

    #Send Mail Message to receiving user and requester.
    $RFSubject = "$TaskNumber - Term ($TUDName) Email Forward"
    $PRUDName = $RUDName.IndexOf(" ")
    $RPRUDFirstName = $RUDName.Substring(0, $PRUDName)
    $BodyReceiver =

"Hi $Requester/$RPRUDFirstName,

Email for $TUDName is being forwarded to $RUDName.


    
Your Name
Your Title 
Your Organization
(123) 456-7890
yourname@yourcorp.com"

    
    Send-MailMessage -From $From -To "$RequesterUPN@yourcorp.com", "$RUUPN@yourcorp.com" -Cc "distributionlist@yourcorp.com" -Subject $RFSubject -Body $BodyReceiver -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential $credential
           
    } # end function Reset-UserForward




