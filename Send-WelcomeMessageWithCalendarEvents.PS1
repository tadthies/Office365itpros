# Send-WelcomeMessageWithCalendarEvents.PS1
# a script to send a welcome message to new user accounts, complete with an attachment to welcome the new account
# and updating the calendar of the Corporate events mailbox so that the new people get invited to suitable events.
# Github link: https://github.com/12Knocksinna/Office365itpros/blob/master/Send-WelcomeMessageWithCalendarEvents.PS1

# V1.0 13-May-2026
# Requires the Microsoft Graph PowerShell SDK running in app-only mode with the following permissions:
# Mail.Send, Organization.Read.All, Calendars.Read, User.Read.All
# This script is intended to be run as an Azure Automation runbook or in app-only mode in an interactive PowerShell session. 

Function Update-MessageRecipients {
    [cmdletbinding()]
    Param(
        [array]$ListOfAddresses )
    ForEach ($SMTPAddress in $ListOfAddresses) {
        @{
            emailAddress = @{address = $SMTPAddress}
        }    
    }    
}

Function Update-MessageAttachments {
    [cmdletbinding()]
    Param(
        [array]$ListOfAttachments 
    )

    [array]$MsgAttachments = $null
    ForEach ($File in $ListOfAttachments) {
        $ConvertedContent = [Convert]::ToBase64String([IO.File]::ReadAllBytes($File))
        $FileExtension = [System.IO.Path]::GetExtension($File) 
        Switch ($FileExtension) {
            ".pdf" {
                $ContentType = "application/pdf"
            }
            ".docx" {
                $ContentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            }
            ".xlsx" {
                $ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            }   
            ".pptx" {
                $ContentType = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            }   
            ".jpg" {
                $ContentType = "image/jpeg"
            }   
            ".png" {
                $ContentType = "image/png"
            }   
            default {
                $ContentType = "application/octet-stream"
            }
        }
        $AttachmentDetails = @{
            "@odata.type" = "#microsoft.graph.fileAttachment"
            Name = $File
            ContentType =  $ContentType
            ContentBytes = $ConvertedContent
        }
        $MsgAttachments += $AttachmentDetails
    }
    Return $MsgAttachments  
}

# Start of processing

$Thumbprint = '0CF6CE3F3548FD73E7AC8CF20226ED447E125C71'
$TenantId = 'a662313f-14fc-43a2-9a7a-d2e27f4f3478'
$AppId = 'dfe6637d-8d2a-4d8f-90eb-c2cbb7479b55'

# Connect in app-only mode
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint $Thumbprint

# Runbook - connect using a managed identity. Make sure that the automation account has the 
# necessary permissions and that the required modules like Microsoft.Graph.Authentication, Microsoft.Graph.Calendar,  
# Microsoft.Graph.Users, and Microsoft.Graph.Users.Actions are added to the runbook environment
Connect-MgGraph -Identity

# We're going to look for user accounts created in the last week, but you can change this as needed
$WeekAgo = (Get-Date).AddDays(-7).toString("yyyy-MM-ddTHH:mm:ssZ")    
# and the user accounts must be licensed for Exchange Online -
$ExoServicePlan1 = "9aaf7827-d63c-4b61-89c3-182f06f82e5c"
$ExoServicePlan2 = "efb87545-963c-4e0d-99df-69c6916d9eb0"

# Find the set of user accounts licensed for Exchange Online created in the last seven days
[array]$Users = Get-MgUser -Filter "(createddateTime ge $WeekAgo and userType eq 'Member') `
    and (assignedPlans/any(c:c/servicePlanId eq $ExoServicePlan1 and capabilityStatus eq 'Enabled') `
     or assignedPlans/any(c:c/servicePlanId eq $ExoServicePlan2 and capabilityStatus eq 'Enabled'))" `
    -ConsistencyLevel eventual -CountVariable Test -All -PageSize 500 -Sort ('displayname') `
    -Property Id, displayName, userprincipalName, assignedPlans, CreatedDateTime, mail

If (!$Users) { 
    Write-Host "No new users found. Exiting!" 
    break 
} Else {
    Write-Host "Found" $Test "new users created in the last week. Processing..." 
}

# Message sender can be any user in the tenant.
$MsgFrom = 'Azure.Management.Account@office365itpros.com'
# Get Tenant name
$TenantName = (Get-MgOrganization).displayName
$MsgSubject = "A warm welcome to $($TenantName)"

# Define some variables used to construct the HTML content in the message body
#HTML header with styles
$HtmlHead="<html><style>BODY{font-family: Arial; font-size: 10pt;}
	H1{font-size: 22px;}
	H2{font-size: 18px; padding-top: 10px;}
	H3{font-size: 16px; padding-top: 8px;}
    </style>"

# Define attachments  we're only using one here, which we fetch from a web site
# if you want to add more files, add the file names to the $AttachmentsList array.
# Obviously, change the file to something that makes sense for your organization.
$WebAttachmentFile = "https://office365itpros.com/wp-content/uploads/2022/02/WelcomeToOffice365ITPros.docx"
# fetch the content of the web file and store it in the downloads folder
$Attachment = ((New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path) +"\WelcomeNewEmployeeToOffice365itpros.docx"
Invoke-WebRequest -Uri $WebAttachmentFile -OutFile $Attachment
[array]$Attachments = $Attachment

#Content for the message - obviously, this is very customizable and should reflect what you want to say to new users
$HtmlBody = "<body>
     <h1>Welcome to $($TenantName)</h1>
     <p><strong>Generated:</strong> $(Get-Date -Format 'dd-MMM-yyyy')</p>  
     <h2><u>We're Pleased to Have You Here</u></h2>
     <p><b>Welcome to your new Microsoft 365 account</b></p>
     <p>You can open your account to access your email and documents by clicking <a href=http://www.portal.office.com>here</a> </p>
     <p>Have a great time and be sure to call the help desk if you need assistance. And be sure to read all the great articles about Microsoft 365 published by our <a href=https://office365itpros.com>Microsoft 365 experts</a>.</p>"

# Determine if any calendar events for corporate events should be added to the message. We look for events in the next six weeks.
# If any events are found, create an .ics file and add it to the attachments list
$CalendarUser = Get-MgUser -UserId "Corporate.Events.Meetings@office365itpros.com"
Try {
    $NoCorporateEvents = $False
    $Calendar = Get-MgUserDefaultCalendar -UserId $CalendarUser.Id -ErrorAction Stop
} Catch {
    Write-Host "Can't find calendar for corporate events" $CalendarUser " - skipping addition of calendar events to message attachments"
    $NoCorporateEvents = $True
}
$StartDateTime = (Get-Date).ToString("yyyy-MM-dd")
$EndDateTime = (Get-Date).AddDays(42).ToString("yyyy-MM-dd")

Try {
    [array]$Events = Get-MgUserCalendarView -UserId $CalendarUser.Id -CalendarId $Calendar.Id -all `
        -EndDateTime $EndDateTime -StartDateTime $StartDateTime -ErrorAction Stop    
} Catch {
    Write-Host "Error fetching events from corporate events calendar - skipping addition of calendar events to message attachments"
    $NoCorporateEvents = $True
}

# If we have some events, go and process them
If ($Events -and $NoCorporateEvents -eq $False) {
    Write-Host "Found" $Events.Count "upcoming events in the corporate calendar. Adding users as meeting participants."
    # Define array of new attendees to add as participants to the corporate events. 
    # In this example, we're just adding the new users as optional attendees, but you could change this as needed.   
    [array]$NewAttendees = @()
    # Loop through the users we want to add to the event
    ForEach ($User in $Users) {
        # Create hash table containing attendee details
        $NewAttendee = @{
            EmailAddress = @{
                Address = $User.Mail
                Name    = $User.displayName
            }
            Type = "optional"   # or "required"
        }
        # Add the hash table to the array of new attendees
        $NewAttendees += $NewAttendee
    }
    ForEach ($Meeting in $Events) {
        # Get current attendees for the meeting
        [array]$CurrentAttendees = $Meeting.Attendees
        # Combine the arrays of new and existing attendees to create an updated list of attendees for the meeting
        [array]$UpdatedAttendees = $CurrentAttendees + $NewAttendees
        # Update the meeting to add the users as participants
        Try {
            $Status = Update-MgUserEvent -UserId $CalendarUser.Id -EventId $Meeting.Id -Attendees $UpdatedAttendees -ErrorAction Stop
        } Catch {
            Write-Host "Error updating meeting" $Meeting.Subject ":" $_.Exception.Message
        }   
    }   
}
# Create the attachments for the message
[array]$MsgAttachments = Update-MessageAttachments -ListOfAttachments $Attachments

# Loop through each user to generate and send the welcome message, customizing the content for each user.
ForEach ($user in $users) {
    $ToRecipientList   = @( $User.Mail )
    [array]$MsgToRecipients = Update-MessageRecipients -ListOfAddresses $ToRecipientList
    Write-Host "Sending welcome email to" $User.DisplayName
    # Customize the message 
    $htmlHeaderUser = "<h2>A Huge Welcome to Our New User " + $User.DisplayName + "</h2>"    
    $HtmlMsg = "</body></html>" + $HtmlHead + $htmlHeaderUser + $HtmlBody + "<p>"
    
    # Construct the message body
    $MsgBody = @{
        Content = "$($HtmlMsg)"
        ContentType = 'html'   
    }

    $Message =  @{subject           = $MsgSubject}
    $Message += @{toRecipients      = $MsgToRecipients}  
    $Message += @{ccRecipients      = $MsgCcRecipients}  
    $Message += @{attachments       = $MsgAttachments}
    $Message += @{body              = $MsgBody}
    $Params   = @{'message'         = $Message}
    $Params  += @{'saveToSentItems' = $True}
    $Params  += @{'isDeliveryReceiptRequested' = $True}

    Try {
        Send-MgUserMail -UserId $MsgFrom -BodyParameter $Params -ErrorAction Stop
    } Catch {
        Write-Host "Error sending message to" $User.DisplayName ":" $_.Exception.Message
    }
  
}

Write-Host "Processing complete. Sent welcome messages to" $Users.Count "new users created in the last week."

# An example script used to illustrate a concept. More information about the topic can be found in the Office 365 for IT Pros eBook https://gum.co/O365IT/
# and/or a relevant article on https://office365itpros.com or https://www.practical365.com. See our post about the Office 365 for IT Pros repository 
# https://office365itpros.com/office-365-github-repository/ for information about the scripts we write.

# Do not use our scripts in production until you are satisfied that the code meets the needs of your organization. Never run any code downloaded from 
# the Internet without first validating the code in a non-production environment. 