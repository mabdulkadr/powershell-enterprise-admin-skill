<#
.TITLE
    Send-EmailNotification

.SYNOPSIS
    Canonical HTML email helper for Intune notification runbooks via Graph Mail API.

.DESCRIPTION
    The single source of truth for sending HTML mail via Microsoft Graph from
    Azure Automation runbooks. Uses the Graph sendMail endpoint with
    saveToSentItems = $false (Managed Identity has no mailbox). Always pair
    with Microsoft Graph authentication (Connect-MgGraph -Identity in runbooks).

.PARAMETER To
    Recipient email address (single recipient; loop outside for multi).

.PARAMETER Subject
    Mail subject line.

.PARAMETER HtmlBody
    HTML content for the message body.

.PARAMETER FromUserId
    User UPN to send "from" via /users/{id}/sendMail. REQUIRED in Azure Automation
    runbooks - $env:USERNAME resolves to the worker account (e.g., OASTokenSrv01)
    and Invoke-MgGraphRequest will fail with ResourceNotFound. Use a real mailbox UPN
    such as 'ops-notifications@contoso.com'. Optional on interactive sessions when
    $env:USERNAME is the operator's UPN.

.TAGS
    Graph,Email,Notification

.PLATFORM
    Windows

.PERMISSIONS
    Graph: Mail.Send (application permission for runbooks)

.AUTHOR
    AI Generated

.VERSION
    1.0.0

.CHANGELOG
    1.0.0 (2026-08-24) - Initial release (extracted from templates/intune-notification.template.ps1)

.LASTUPDATE
    2026-08-24

.EXAMPLE
    Send-EmailNotification -To 'ops@contoso.com' -Subject 'Daily Report' -HtmlBody $html

.NOTES
    - saveToSentItems is ALWAYS $false: the Managed Identity has no mailbox.
    - For multi-recipient mail, build toRecipients in caller and use Graph directly.
    - FromUserId is Mandatory - in Azure Automation runbooks the default $env:USERNAME
      is the worker account, not a valid Entra UPN. Pass an explicit mailbox UPN such as
      'ops-notifications@contoso.com' from the caller.
    - Canonical source: copy this file or dot-source it from templates.
#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

function Send-EmailNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$To,
        [Parameter(Mandatory = $true)][string]$Subject,
        [Parameter(Mandatory = $true)][string]$HtmlBody,
        [Parameter(Mandatory = $true)][string]$FromUserId
    )

    $messageBody = @{
        message = @{
            subject      = $Subject
            body         = @{ contentType = 'HTML'; content = $HtmlBody }
            toRecipients = @( @{ emailAddress = @{ address = $To } } )
        }
        saveToSentItems = $false   # Managed Identity has no mailbox
    } | ConvertTo-Json -Depth 6

    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/users/$FromUserId/sendMail" `
        -Method POST -Body $messageBody -ContentType 'application/json' -ErrorAction Stop
}
