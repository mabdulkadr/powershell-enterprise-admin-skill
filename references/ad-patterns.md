# Active Directory Management Patterns

Patterns for Active Directory administration scripts. **All examples are CLI context — use `Write-Log` (canonical: `scripts/Write-Log.ps1`), not the GUI `Add-LogLine`.**

---

## Table of Contents

1. [Module Requirements](#module-requirements)
2. [Computer Management](#computer-management)
3. [User Management](#user-management)
4. [Group Management](#group-management)
5. [Reporting](#reporting)
6. [Health Monitoring](#health-monitoring)
7. [Bulk Operations](#bulk-operations)
8. [Safety Patterns](#safety-patterns)

---

## Module Requirements

```powershell
# Check for ActiveDirectory module
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "RSAT Active Directory module not installed" "ERROR"
    Write-Log "Install with: Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0" "INFO"
    exit 1
}
Import-Module ActiveDirectory -ErrorAction Stop
```

---

## Computer Management

### Disable Stale Computer Accounts

```powershell
function Get-StaleComputers {
    param(
        [int]$InactiveDays = 90,
        [string]$SearchBase
    )

    $cutoffDate = (Get-Date).AddDays(-$InactiveDays)

    $params = @{
        Filter = { LastLogonTimeStamp -lt $cutoffDate }
        Properties = @('LastLogonTimeStamp', 'OperatingSystem', 'Enabled', 'DistinguishedName')
    }

    if ($SearchBase) { $params.SearchBase = $SearchBase }

    Get-ADComputer @params | Select-Object @{
        Name = 'ComputerName'; Expression = { $_.Name }
    }, @{
        Name = 'LastLogon'; Expression = {
            [DateTime]::FromFileTime($_.LastLogonTimeStamp)
        }
    }, @{
        Name = 'DaysInactive'; Expression = {
            ((Get-Date) - [DateTime]::FromFileTime($_.LastLogonTimeStamp)).Days
        }
    }, OperatingSystem, Enabled, DistinguishedName
}
```

### Move Computers Between OUs

```powershell
function Move-ComputerToOU {
    param(
        [string]$ComputerName,
        [string]$TargetOU
    )

    try {
        $computer = Get-ADComputer -Identity $ComputerName -ErrorAction Stop
        Move-ADObject -Identity $computer.DistinguishedName -TargetPath $TargetOU -ErrorAction Stop
        Write-Log "Moved $ComputerName to $TargetOU" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to move $ComputerName`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}
```

### Bulk Disable/Enable

```powershell
function Set-ComputersEnabled {
    param(
        [string[]]$ComputerNames,
        [bool]$Enabled
    )

    $results = foreach ($name in $ComputerNames) {
        try {
            Set-ADComputer -Identity $name -Enabled $Enabled -ErrorAction Stop
            [pscustomobject]@{
                ComputerName = $name
                Status       = if ($Enabled) { 'Enabled' } else { 'Disabled' }
                Error        = $null
            }
        }
        catch {
            [pscustomobject]@{
                ComputerName = $name
                Status       = 'Failed'
                Error        = $_.Exception.Message
            }
        }
    }

    return $results
}
```

---

## User Management

### Get Inactive Users

```powershell
function Get-InactiveUsers {
    param(
        [int]$InactiveDays = 30,
        [string]$SearchBase
    )

    $cutoffDate = (Get-Date).AddDays(-$InactiveDays)

    $params = @{
        Filter = { LastLogonDate -lt $cutoffDate -and Enabled -eq $true }
        Properties = @('LastLogonDate', 'Department', 'Title', 'EmailAddress')
    }

    if ($SearchBase) { $params.SearchBase = $SearchBase }

    Get-ADUser @params | Select-Object @{
        Name = 'UserName'; Expression = { $_.SamAccountName }
    }, @{
        Name = 'DisplayName'; Expression = { $_.Name }
    }, Department, Title, EmailAddress, LastLogonDate, @{
        Name = 'DaysInactive'; Expression = {
            if ($_.LastLogonDate) {
                ((Get-Date) - $_.LastLogonDate).Days
            } else { 'Never' }
        }
    }
}
```

### Bulk Password Reset

```powershell
function Reset-UserPasswords {
    param(
        [string[]]$UserNames,
        [string]$NewPassword
    )

    $securePassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force

    foreach ($user in $UserNames) {
        try {
            Set-ADAccountPassword -Identity $user -NewPassword $securePassword -Reset -ErrorAction Stop
            Set-ADUser -Identity $user -ChangePasswordAtLogon $true -ErrorAction Stop
            Write-Log "Password reset for $user" "SUCCESS"
        }
        catch {
            Write-Log "Failed to reset password for $user`: $($_.Exception.Message)" "ERROR"
        }
    }
}
```

---

## Group Management

### Add Users from CSV to Group

```powershell
function Add-UsersToGroupFromCSV {
    param(
        [string]$CSVPath,
        [string]$GroupName,
        [string]$UserColumnName = 'Username'
    )

    $csv = Import-Csv -Path $CSVPath
    $results = foreach ($row in $csv) {
        $username = $row.$UserColumnName
        try {
            Add-ADGroupMember -Identity $GroupName -Members $username -ErrorAction Stop
            [pscustomobject]@{
                Username = $username
                Group    = $GroupName
                Status   = 'Added'
                Error    = $null
            }
        }
        catch {
            [pscustomobject]@{
                Username = $username
                Group    = $GroupName
                Status   = 'Failed'
                Error    = $_.Exception.Message
            }
        }
    }

    return $results
}
```

### Group Membership Report

```powershell
function Get-GroupMembershipReport {
    param([string]$GroupName)

    $members = Get-ADGroupMember -Identity $GroupName -Recursive
    $report = foreach ($member in $members) {
        $obj = Get-ADObject -Identity $member.DistinguishedName -Properties *
        [pscustomobject]@{
            Name       = $member.Name
            ObjectClass = $member.ObjectClass
            Enabled    = if ($obj.objectClass -eq 'user') { $obj.Enabled } else { 'N/A' }
            DN         = $member.DistinguishedName
        }
    }

    return $report
}
```

---

## Reporting

### AD Health Report

```powershell
function Get-ADHealthReport {
    $report = [ordered]@{}

    # DC connectivity
    $dcs = Get-ADDomainController -Filter *
    $report.DCStatus = foreach ($dc in $dcs) {
        $ping = Test-Connection -ComputerName $dc.HostName -Count 2 -Quiet -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Name     = $dc.Name
            IP       = $dc.IPv4Address
            Status   = if ($ping) { 'Online' } else { 'Offline' }
            Site     = $dc.Site
        }
    }

    # FSMO roles
    $forest = Get-ADForest
    $domain = Get-ADDomain
    $report.Roles = [ordered]@{
        'Schema Master'         = $forest.SchemaMaster
        'Domain Naming Master'  = $forest.DomainNamingMaster
        'PDC Emulator'          = $domain.PDCEmulator
        'RID Master'            = $domain.RIDMaster
        'Infrastructure Master' = $domain.InfrastructureMaster
    }

    # Password last set - Get-ADUser -Filter accepts an LDAP filter string,
    # not a PowerShell expression with a [DateTime] comparison. Use a wildcard
    # filter to fetch enabled users, then post-filter on LastLogonDate in PowerShell.
    # This is faster and works around the LDAP-date conversion gotcha.
    $cutoff30 = (Get-Date).AddDays(-30)
    $report.UsersNeverLoggedOn = (Get-ADUser -Filter { Enabled -eq $true } -Properties LastLogonDate |
        Where-Object { $_.LastLogonDate -lt $cutoff30 }).Count
    $report.ComputersStale90Days = (Get-StaleComputers -InactiveDays 90).Count

    return $report
}
```

### Export to HTML

```powershell
function Export-ADReportToHTML {
    param(
        [object]$Report,
        [string]$OutputPath
    )

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>AD Health Report</title>
    <style>
        body { font-family: Segoe UI; margin: 20px; background: #f6f8fb; }
        h1 { color: #1f2d3a; }
        table { border-collapse: collapse; width: 100%; margin: 16px 0; background: white; }
        th { background: #e6ebf4; padding: 10px; text-align: left; font-weight: 600; }
        td { padding: 8px 10px; border-bottom: 1px solid #e6ebf4; }
        .online { color: #0a8a0a; font-weight: 600; }
        .offline { color: #d13438; font-weight: 600; }
    </style>
</head>
<body>
    <h1>Active Directory Health Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
"@

    # DC Status table
    $html += "<h2>Domain Controller Status</h2>"
    $html += "<table><tr><th>Name</th><th>IP</th><th>Status</th><th>Site</th></tr>"
    foreach ($dc in $Report.DCStatus) {
        $statusClass = if ($dc.Status -eq 'Online') { 'online' } else { 'offline' }
        $html += "<tr><td>$($dc.Name)</td><td>$($dc.IP)</td><td class='$statusClass'>$($dc.Status)</td><td>$($dc.Site)</td></tr>"
    }
    $html += "</table>"

    # FSMO Roles
    $html += "<h2>FSMO Roles</h2>"
    $html += "<table><tr><th>Role</th><th>Holder</th></tr>"
    foreach ($role in $Report.Roles.GetEnumerator()) {
        $html += "<tr><td>$($role.Key)</td><td>$($role.Value)</td></tr>"
    }
    $html += "</table>"

    $html += "</body></html>"
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Log "Report exported to $OutputPath" "SUCCESS"
}
```

---

## Health Monitoring

### Test AD Connectivity

```powershell
function Test-ADConnectivity {
    param([string[]]$DomainControllers)

    $results = foreach ($dc in $DomainControllers) {
        $ping = Test-Connection -ComputerName $dc -Count 2 -Quiet -ErrorAction SilentlyContinue
        $ldapTest = $false
        try {
            $rootDSE = [ADSI]"LDAP://$dc/rootDSE"
            $null = $rootDSE.defaultNamingContext
            $ldapTest = $true
        } catch { }

        [pscustomobject]@{
            DC      = $dc
            Ping    = $ping
            LDAP    = $ldapTest
            Status  = if ($ping -and $ldapTest) { 'Healthy' } else { 'Degraded' }
        }
    }

    return $results
}
```

### Replication Monitor

```powershell
function Get-ADReplicationStatus {
    $partners = Get-ADReplicationPartnerMetadata -ErrorAction SilentlyContinue
    $results = foreach ($partner in $partners) {
        [pscustomobject]@{
            Partner       = $partner.Partner
            LastReplication = $partner.LastReplicationTime
            ConsecutiveFailures = $partner.ConsecutiveReplicationFailures
            Status        = if ($partner.ConsecutiveReplicationFailures -eq 0) { 'Healthy' } else { 'Issue' }
        }
    }
    return $results
}
```

---

## Bulk Operations

### CSV Import Pattern

```powershell
function Import-ADObjectsFromCSV {
    param(
        [string]$CSVPath,
        [string]$ObjectType = 'Computer'  # Computer, User, Group
    )

    $csv = Import-Csv -Path $CSVPath
    $columns = $csv[0].PSObject.Properties.Name

    # Auto-detect name column
    $nameColumn = $columns | Where-Object {
        $_ -in @('ComputerName','Computer','Device','Name','Hostname','SamAccountName','UserName')
    } | Select-Object -First 1

    if (-not $nameColumn) {
        Write-Log "Cannot detect name column. Available: $($columns -join ', ')" "ERROR"
        return @()
    }

    $results = foreach ($row in $csv) {
        $name = $row.$nameColumn
        try {
            switch ($ObjectType) {
                'Computer' { Get-ADComputer -Identity $name -ErrorAction Stop }
                'User'     { Get-ADUser -Identity $name -ErrorAction Stop }
                'Group'    { Get-ADGroup -Identity $name -ErrorAction Stop }
            }
            [pscustomobject]@{ Name = $name; Status = 'Found'; Error = $null }
        }
        catch {
            [pscustomobject]@{ Name = $name; Status = 'NotFound'; Error = $_.Exception.Message }
        }
    }

    return $results
}
```

### Protected DN Pattern

**Why this matters:** Active Directory has a few DNs whose modification can take down the entire domain — most notably the `Domain Controllers` OU. Moving a DC object out of that OU breaks replication and effectively bricks the forest. The standard default OUs (`CN=Users`, `CN=Computers`) are also common targets for accidental moves that orphan accounts. Add a guard to any bulk operation that touches OUs:

```powershell
# Prevent accidental modification of critical OUs/accounts.
# Extend this list with any production-specific DNs that must never move.
$protectedDNs = @(
    'CN=Users,DC=contoso,DC=com'
    'CN=Computers,DC=contoso,DC=com'
    'CN=Domain Controllers,DC=contoso,DC=com'
    # 'OU=Service-Accounts,DC=contoso,DC=com'   # example: protect service accounts
)

function Test-IsProtected {
    param([string]$DistinguishedName)
    return $protectedDNs -contains $DistinguishedName
}

# Usage in a bulk operation
foreach ($computer in $computers) {
    if (Test-IsProtected -DistinguishedName $computer.DistinguishedName) {
        Write-Log "SKIPPED $computer.Name — protected DN" "WARNING"
        continue
    }
    Move-ADObject ...
}
```

This pattern is also useful when filtering CSV imports — never trust a CSV column to determine whether an object is safe to modify.

---

## Safety Patterns

### Confirm Before Destructive Operations

```powershell
function Remove-ADObjectsSafely {
    param(
        [string[]]$ObjectNames,
        [string]$ObjectType = 'Computer',
        [switch]$Force
    )

    if (-not $Force) {
        Write-Host "About to remove $($ObjectNames.Count) $ObjectType objects:" -ForegroundColor Yellow
        $ObjectNames | ForEach-Object { Write-Host "  - $_" }
        $confirm = Read-Host "Type 'YES' to confirm"
        if ($confirm -ne 'YES') {
            Write-Log "Operation cancelled by user" "WARNING"
            return
        }
    }

    foreach ($name in $ObjectNames) {
        try {
            Remove-ADObject -Identity $name -Recursive -Confirm:$false -ErrorAction Stop
            Write-Log "Removed $name" "SUCCESS"
        }
        catch {
            Write-Log "Failed to remove $name`: $($_.Exception.Message)" "ERROR"
        }
    }
}
```

### Audit Trail

Operational logging uses `Write-Log` (canonical: `scripts/Write-Log.ps1`). For compliance, keep a **structured CSV audit record** of every AD change — this is a data export, not a log, and it replaces no logging function:

```powershell
# Log all AD changes for audit
function Write-ADAuditLog {
    param(
        [string]$Action,
        [string]$Target,
        [string]$Details
    )

    # Canonical log path: C:\ProgramData\<ToolName>\Logs\ (see SKILL.md "Canonical Conventions")
    $logDir = "C:\ProgramData\ADUserManager\Logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    $entry = [pscustomobject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Action    = $Action
        Target    = $Target
        Details   = $Details
        User      = $env:USERNAME
        Computer  = $env:COMPUTERNAME
    }

    $entry | Export-Csv -Path (Join-Path $logDir "AD_Audit_$(Get-Date -Format 'yyyyMMdd').csv") `
        -NoTypeInformation -Append
}
```
