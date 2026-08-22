<#
.TITLE
    Connect-GraphAuth

.SYNOPSIS
    Canonical Microsoft Graph authentication helper matrix.

.DESCRIPTION
    The single source of truth for every Graph authentication mode in Intune and enterprise scripts.
    Supports Managed Identity, Interactive login, Device Code Flow (for RDP/bastion hosts),
    Client Credentials (App Registration), Certificate auth, and config persistence in LocalAppData.

.PARAMETER TenantId
    Directory (Tenant) ID for unattended app registration authentication.

.PARAMETER ClientSecret
    Client secret for app registration authentication.

.PARAMETER CertificateThumbprint
    Certificate thumbprint in Cert:\CurrentUser\My or Cert:\LocalMachine\My for certificate authentication.

.PARAMETER Mode
    Authentication mode ('Auto', 'ManagedIdentity', 'Interactive', 'DeviceCode', 'ClientCredentials', 'Certificate'). Default is 'Auto'.

.PARAMETER Scopes
    Array of required Graph permission scopes for interactive/device code authentication.

.PARAMETER ClientId
    Application (Client) ID for unattended app registration authentication.

.TAGS
    Graph,Authentication

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution)

.AUTHOR
    AI Generated

.VERSION
    1.2.0

.CHANGELOG
    1.2.0 (2026-08-20)
    - Canonical rich header upgrade to Enterprise Standards field order
    1.0.0 - Initial release

.LASTUPDATE
    2026-08-22

.EXAMPLE
    Connect-GraphAuth -Mode DeviceCode -Scopes @('DeviceManagementManagedDevices.ReadWrite.All')
#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
function Connect-GraphAuth {
    [CmdletBinding()]
    param(
        [ValidateSet('Auto', 'ManagedIdentity', 'Interactive', 'DeviceCode', 'ClientCredentials', 'Certificate')]
        [string]$Mode = 'Auto',
        [string[]]$Scopes = @('User.Read'),
        [string]$ClientId = $env:AZURE_CLIENT_ID,
        [string]$TenantId = $env:AZURE_TENANT_ID,
        [string]$ClientSecret = $env:AZURE_CLIENT_SECRET,
        [string]$CertificateThumbprint
    )

    # Validate module availability
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Required module 'Microsoft.Graph.Authentication' is not installed. Install via: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    # Context detection
    $isRunningInAzureAutomation = ($null -ne $env:AUTOMATION_ASSET_ACCOUNTID) -or ($null -ne $PSPrivateMetadata.JobId.Guid)

    if ($Mode -eq 'Auto') {
        $Mode = if ($isRunningInAzureAutomation) { 'ManagedIdentity' } else { 'Interactive' }
    }

    try {
        switch ($Mode) {
            'ManagedIdentity' {
                Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop
                Write-Verbose 'Connected to Microsoft Graph using Managed Identity.'
            }
            'Interactive' {
                Connect-MgGraph -Scopes $Scopes -NoWelcome -ErrorAction Stop
                Write-Verbose 'Connected to Microsoft Graph using interactive login.'
            }
            'DeviceCode' {
                # Device Code Flow: prompts with code for browser verification on another device (ideal for RDP/Bastion)
                Connect-MgGraph -Scopes $Scopes -UseDeviceAuthentication -NoWelcome -ErrorAction Stop
                Write-Verbose 'Connected to Microsoft Graph using Device Code authentication.'
            }
            'ClientCredentials' {
                if (-not ($ClientId -and $TenantId -and $ClientSecret)) {
                    throw "Client Credentials mode requires ClientId, TenantId, and ClientSecret parameters or environment variables."
                }
                $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
                Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -ClientSecret $secureSecret -NoWelcome -ErrorAction Stop
                Write-Verbose 'Connected to Microsoft Graph using Client Credentials.'
            }
            'Certificate' {
                if (-not ($ClientId -and $TenantId -and $CertificateThumbprint)) {
                    throw "Certificate mode requires ClientId, TenantId, and CertificateThumbprint parameters."
                }
                Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint -NoWelcome -ErrorAction Stop
                Write-Verbose 'Connected to Microsoft Graph using Certificate authentication.'
            }
        }
        return $true
    }
    catch {
        throw "Failed to connect to Microsoft Graph ($Mode): $($_.Exception.Message)"
    }
}

function Save-GraphAuthConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [string]$TenantId,
        [string]$ClientId,
        [string]$CertificateThumbprint,
        [string]$AuthMode = 'Interactive'
    )

    $configDir = Join-Path $env:LOCALAPPDATA $AppName
    if (-not (Test-Path -Path $configDir)) {
        $null = New-Item -ItemType Directory -Path $configDir -Force -ErrorAction SilentlyContinue
    }

    # Security Rule: Never persist ClientSecret in plaintext settings.json
    $config = [PSCustomObject]@{
        TenantId              = $TenantId
        ClientId              = $ClientId
        CertificateThumbprint = $CertificateThumbprint
        AuthMode              = $AuthMode
        LastSaved             = (Get-Date -Format 'o')
    }

    $configFile = Join-Path $configDir 'settings.json'
    $config | ConvertTo-Json -Depth 3 | Set-Content -Path $configFile -Encoding UTF8 -Force
    Write-Verbose "Configuration saved safely to $configFile"
}

function Get-GraphAuthConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName
    )

    $configFile = Join-Path $env:LOCALAPPDATA "$AppName\settings.json"
    if (Test-Path -Path $configFile) {
        try {
            return Get-Content -Path $configFile -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Failed to parse $configFile"
        }
    }
    return $null
}

function Disconnect-GraphAuth {
    [CmdletBinding()]
    param()
    try {
        if (Get-MgContext -ErrorAction SilentlyContinue) {
            $null = Disconnect-MgGraph -ErrorAction SilentlyContinue
            Write-Verbose 'Disconnected from Microsoft Graph.'
        }
    }
    catch {
        # Silent cleanup
    }
}