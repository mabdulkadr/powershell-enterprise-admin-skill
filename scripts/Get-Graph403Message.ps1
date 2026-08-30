<#
.TITLE
    Get-Graph403Message

.SYNOPSIS
    Canonical Microsoft Graph HTTP 403 error message mapper.

.DESCRIPTION
    Converts bare HTTP 403 Forbidden errors into actionable administrative guidance,
    specifying required roles and permissions per service (Entra ID, Intune, Autopilot, Defender, Exchange, Teams).

.PARAMETER Details
    Optional detailed exception message or sub-code for extra context.

.PARAMETER Service
    Target service name ('EntraID', 'Intune', 'Autopilot', 'Defender', 'Exchange', 'Teams', 'SharePoint').

.TAGS
    Graph,ErrorHandling,RBAC

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution)

.AUTHOR
    AI Generated

.VERSION
    1.1.0

.CHANGELOG
    1.1.0 (2026-08-20)
    - Canonical rich header upgrade to Enterprise Standards field order
    1.0.0 - Initial release

.LASTUPDATE
    2026-08-20

.EXAMPLE
    Get-Graph403Message -Service 'Intune'
#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
function Get-Graph403Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('EntraID', 'Intune', 'Autopilot', 'Defender', 'Exchange', 'Teams', 'SharePoint')]
        [string]$Service,
        [string]$Details
    )

    $map = @{
        EntraID    = "Missing Entra ID administrative role or scope. Assign 'Cloud Device Administrator' or 'User Administrator' with appropriate scopes and re-authenticate."
        Intune     = "Missing Intune administrative role. Assign 'Intune Administrator' with 'DeviceManagementManagedDevices.ReadWrite.All' or relevant permission and re-authenticate."
        Autopilot  = "Missing Autopilot access. Assign 'Intune Administrator' with 'DeviceManagementServiceConfig.ReadWrite.All' and re-authenticate."
        Defender   = "Missing Defender / Security role. Assign 'Security Administrator' or 'Security Operator' with 'SecurityEvents.Read.All' and re-authenticate."
        Exchange   = "Missing Exchange role or Mail scope. Assign 'Exchange Administrator' with 'Mail.Send' or 'Mail.ReadWrite' and re-authenticate."
        Teams      = "Missing Teams administrative role. Assign 'Teams Administrator' with 'Team.ReadBasic.All' and re-authenticate."
        SharePoint = "Missing SharePoint role. Assign 'SharePoint Administrator' with 'Sites.ReadWrite.All' and re-authenticate."
    }

    $baseMsg = $map[$Service]
    if ($Details) {
        return "Graph API 403 Forbidden ($Service): $baseMsg [Context: $Details]"
    }
    return "Graph API 403 Forbidden ($Service): $baseMsg"
}