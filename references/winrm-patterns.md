# WinRM and PSRemoting Patterns

Patterns for running commands remotely across Windows machines using WinRM (PowerShell remoting). This is the foundation for almost all multi-device enterprise admin scripts.

---

## Table of Contents

1. [Why WinRM matters for enterprise admin](#why-winrm-matters-for-enterprise-admin)
2. [Prerequisites](#prerequisites)
3. [Single-machine remoting](#single-machine-remoting)
4. [Multi-machine parallel execution](#multi-machine-parallel-execution)
5. [Credential handling](#credential-handling)
6. [Common errors and fixes](#common-errors-and-fixes)
7. [Connectivity testing](#connectivity-testing)
8. [Integration with WPF tools](#integration-with-wpf-tools)

---

## Why WinRM matters for enterprise admin

Most enterprise admin work targets **more than one machine**. A user reports a problem and you need to check the same setting on five machines. A service needs to be restarted on every endpoint in a department. You need inventory from every laptop in the fleet.

You cannot log on to each machine interactively. PSRemoting lets you run PowerShell on remote machines from one session. It uses the WS-Management protocol (WinRM), which is on by default on Windows Server 2012 R2+ and available (but not always enabled) on Windows 10/11 clients.

**Key benefit:** Commands, errors, and return values behave exactly like local PowerShell. No learning curve beyond the credential and connection mechanics.

**Key gotcha:** WinRM must be enabled on the remote machine. The firewall must allow inbound 5985 (HTTP) or 5986 (HTTPS). For client machines joined to Entra ID, additional configuration may be needed.

---

## Prerequisites

### Enable PSRemoting on a Remote Machine

Run as Administrator on the target machine (or via GPO):

```powershell
Enable-PSRemoting -Force
```

This:
- Starts the WinRM service (sets it to auto-start)
- Creates a listener on HTTP (5985) and HTTPS (5986)
- Configures the Windows Firewall to allow inbound WinRM traffic
- Enables local loopback connection

### Enable via Group Policy

For fleet-wide deployment, use GPO:

```
Computer Configuration
  → Policies
    → Administrative Templates
      → Windows Components
        → Windows Remote Management (WinRM)
          → WinRM Service
            → "Allow automatic configuration of listeners" = Enabled
              → IPv4 filter: * (or your subnet)
              → IPv6 filter: * (or your subnet)
```

### Check if a Machine is Reachable

```powershell
# Quick connectivity check
Test-WSMan -ComputerName "SERVER01"

# Detailed check
Invoke-Command -ComputerName "SERVER01" -ScriptBlock { $env:COMPUTERNAME }
```

### Trust the Host (for self-signed certs / first connection)

```powershell
# Add to TrustedHosts list (workgroup machines)
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*.contoso.local" -Force

# Or per-machine
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "WORKGROUP-MACHINE01" -Force
```

---

## Single-machine remoting

### Invoke a Command

```powershell
$result = Invoke-Command -ComputerName "SERVER01" -ScriptBlock {
    Get-Service -Name "WinRM"
} -ErrorAction Stop

$result | Format-Table Name, Status, StartType
```

### Enter an Interactive Session

```powershell
Enter-PSSession -ComputerName "SERVER01"

# Now you are running commands on SERVER01
Get-Process | Select-Object -First 5
# Type `Exit-PSSession` to return
```

### Run a Local Script on a Remote Machine

```powershell
Invoke-Command -ComputerName "SERVER01" -FilePath "C:\Scripts\Check-Service.ps1"
```

---

## Multi-machine parallel execution

This is where WinRM really shines. There are two patterns: **fan-out with `Invoke-Command -ThrottleLimit`** (built-in parallelism) or **explicit runspace pool** (maximum control).

### Pattern 1: Fan-Out (Built-in, Recommended)

```powershell
$computers = Get-Content "C:\Lists\Computers.txt"

$results = Invoke-Command -ComputerName $computers -ScriptBlock {
    param($ServiceName)
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    [pscustomobject]@{
        ComputerName = $env:COMPUTERNAME
        Service      = $ServiceName
        Status       = if ($svc) { $svc.Status.ToString() } else { 'Not Installed' }
    }
} -ArgumentList "WinRM" -ThrottleLimit 10

$results | Format-Table -AutoSize
```

`Invoke-Command` handles parallel connections internally. `-ThrottleLimit` controls how many machines to contact simultaneously. 10 is a reasonable default for most environments; raise it for read-only operations, lower it for write-heavy workloads.

### Pattern 2: Runspace Pool (Maximum Control)

Use this when:
- You need each remote call to stream progress back
- You want to control connection lifetime individually
- You need to handle failures per-machine with custom logic
- The WPF tool needs real-time updates (see "Integration with WPF tools" below)

```powershell
$computers = Get-Content "C:\Lists\Computers.txt"

# Create a runspace pool with 1..8 concurrent runspaces
$pool = [runspacefactory]::CreateRunspacePool(1, 8)
$pool.ApartmentState = 'MTA'
$pool.Open()

$jobs = foreach ($computer in $computers) {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool

    [void]$ps.AddScript({
        param($Computer)
        try {
            $result = Invoke-Command -ComputerName $Computer -ScriptBlock {
                Get-Service -Name "WinRM"
            } -ErrorAction Stop

            [pscustomobject]@{
                ComputerName = $Computer
                Status       = 'Success'
                Service      = $result.Status.ToString()
                Error        = $null
            }
        }
        catch {
            [pscustomobject]@{
                ComputerName = $Computer
                Status       = 'Failed'
                Service      = $null
                Error        = $_.Exception.Message
            }
        }
    }).AddArgument($computer)

    [pscustomobject]@{
        PS    = $ps
        Async = $ps.BeginInvoke()
    }
}

# Collect results
$results = foreach ($job in $jobs) {
    $job.PS.EndInvoke($job.Async)
    $job.PS.Dispose()
}
$pool.Close()

$results | Format-Table -AutoSize
```

**Why use a runspace pool over `-ThrottleLimit`?** The pool gives you:
- Per-machine result objects with status (Success / Failed)
- The exception message per failure (not just `Invoke-Command`'s generic error)
- The ability to cancel individual jobs

**Why MTA?** `Invoke-Command` runs in MTA (multi-threaded apartment). If your runspace uses STA, you'll get COMException errors. This is one of the most common PSRemoting bugs.

---

## Credential handling

### Prompt the User

```powershell
$cred = Get-Credential -Message "Enter admin credentials for remote machines"
# User enters DOMAIN\username and password
```

### Use a Stored Credential (Use Sparingly)

```powershell
# Export credential to encrypted file (run once, manually)
Get-Credential | Export-Clixml -Path "C:\Secure\admin.cred"
# File is encrypted with current user + machine credentials

# Use in script
$cred = Import-Clixml -Path "C:\Secure\admin.cred"
Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock { ... }
```

**Why `Export-Clixml`?** The encrypted file can only be decrypted by the same user on the same machine. This is a Microsoft-supported pattern for unattended scripts but should never be used for cross-user or cross-machine credential sharing.

### Use a RunAs Account from a Secret Vault

```powershell
Install-Module Microsoft.PowerShell.SecretManagement -Force
Install-Module Microsoft.PowerShell.SecretStore -Force

# Register a vault once
Register-SecretVault -Name "AdminCreds" -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# Store a credential once
$cred = Get-Credential
Set-Secret -Name "IT-Admin" -Secret $cred -Vault "AdminCreds"

# Use in script
$cred = Get-Secret -Name "IT-Admin" -Vault "AdminCreds" -AsCredential
Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock { ... }
```

This is the **preferred** approach for enterprise admin scripts that need unattended execution.

---

## Common errors and fixes

### "WinRM cannot complete the operation"

**Cause:** WinRM is not running, firewall is blocking, or the target is unreachable.

**Fix:**

```powershell
# Verify network reachability
Test-Connection -ComputerName $computer -Count 2 -Quiet

# Verify WinRM port
Test-NetConnection -ComputerName $computer -Port 5985

# If the machine is reachable but WinRM is blocked:
# Run on the target machine as Administrator: Enable-PSRemoting -Force
```

### "Access is denied"

**Cause:** The credential does not have admin rights on the target, or UAC is blocking the token.

**Fix:**

```powershell
# Use a credential that is a local admin on the target
$cred = Get-Credential
Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock { ... }

# For UAC-restricted environments, configure LocalAccountTokenFilterPolicy
# (one-time, on the target machine, as Administrator):
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "LocalAccountTokenFilterPolicy" -Value 1 -PropertyType DWord -Force
```

### "The WS-Management service cannot process the request because the request body is too large"

**Cause:** The remote script returned more than the default WinRM payload allows.

**Fix:** Raise `MaxEnvelopeSizekb` on **both** sides of the connection. The setting is under `WSMan:\localhost\Service\` on the target that **accepts** the connection, and `WSMan:\localhost\Client\` on the machine that **initiates** it:

```powershell
# On the target machine (the one that receives the connection — Service namespace)
Set-Item WSMan:\localhost\Service\MaxEnvelopeSizekb -Value 8192
Restart-Service WinRM

# On the initiating (admin) machine — Client namespace, because this machine connects OUT to targets
Set-Item WSMan:\localhost\Client\MaxEnvelopeSizekb -Value 8192

# Per-call alternative that needs no config change (works on all PS versions):
Invoke-Command -ComputerName 'SRV01' -ScriptBlock $sb -SessionOption (New-PSSessionOption -MaximumReceivedObjectSizeMB 16)
```

There is no `MaxEnvelopeSizekb` under bare `WSMan:\localhost\` — it only exists under the `Service\` and `Client\` sub-namespaces. The per-call `New-PSSessionOption -MaximumReceivedObjectSizeMB` shown above increases the *local client* receive buffer without a registry change, but it cannot raise the remote Service limit — that requires the `WSMan:\localhost\Service\` setting plus `Restart-Service WinRM` on the target.

### "The connection to the remote computer was closed"

**Cause:** The remote machine rebooted, WinRM crashed, or the network connection was interrupted.

**Fix:** Add retry logic. Don't use `Invoke-Command -ErrorAction Stop` for transient operations:

```powershell
function Invoke-CommandWithRetry {
    param(
        [string]$ComputerName,
        [scriptblock]$ScriptBlock,
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 5
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ErrorAction Stop
        }
        catch {
            if ($attempt -eq $MaxAttempts) { throw }
            Write-Verbose "Attempt $attempt failed for $ComputerName. Retrying in $DelaySeconds seconds..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}
```

### "Kerberos authentication error / NTLM fallback"

**Cause:** The target is in a different domain or workgroup without proper trust.

**Fix:**

```powershell
# Allow NTLM (less secure, use only when needed)
Set-Item WSMan:\localhost\Client\AllowNegotiate -Value $false
Set-Item WSMan:\localhost\Client\AllowNTLM -Value $true

# Or use the explicit credential format: COMPUTER\username
$cred = Get-Credential -UserName "WORKGROUP-MACHINE01\Administrator"
```

---

## Connectivity testing

Build this into every multi-device tool. It tells the operator **before** they start a long operation which machines are unreachable.

```powershell
function Test-RemoteConnectivity {
    param([string[]]$ComputerNames)

    $results = foreach ($computer in $ComputerNames) {
        $ping = Test-Connection -ComputerName $computer -Count 2 -Quiet -ErrorAction SilentlyContinue
        $wsman = $false
        try {
            Test-WSMan -ComputerName $computer -ErrorAction Stop | Out-Null
            $wsman = $true
        }
        catch { }

        [pscustomobject]@{
            ComputerName = $computer
            Ping         = $ping
            WinRM        = $wsman
            Status       = if ($ping -and $wsman) { 'Ready' }
                          elseif ($ping) { 'WinRM Blocked' }
                          else { 'Unreachable' }
        }
    }

    return $results
}
```

---

## Integration with WPF tools

Combine this with the WPF patterns from `xaml-styles.md`. Use a runspace pool + DispatcherTimer so the GUI stays responsive while remote commands execute.

```powershell
$script:isBusy = $false
$Script:Results = @()

function Start-RemoteScan {
    param([string[]]$Computers)

    if (-not (Guard-Action "Remote Scan")) { return }
    $script:isBusy = $true
    $Script:Results = @()

    $pool = [runspacefactory]::CreateRunspacePool(1, 8)
    $pool.ApartmentState = 'MTA'
    $pool.Open()

    $jobs = foreach ($computer in $Computers) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $pool
        [void]$ps.AddScript({
            param($Computer)
            try {
                $svc = Invoke-Command -ComputerName $Computer -ScriptBlock {
                    Get-Service -Name "WinRM"
                } -ErrorAction Stop
                [pscustomobject]@{
                    Computer = $Computer; Status = 'Success'; Detail = $svc.Status.ToString()
                }
            }
            catch {
                [pscustomobject]@{
                    Computer = $Computer; Status = 'Failed'; Detail = $_.Exception.Message
                }
            }
        }).AddArgument($computer)

        @{ PS = $ps; Async = $ps.BeginInvoke() }
    }

    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds(300)
    $totalJobs = $jobs.Count
    $completed = 0
    $timer.Add_Tick({
        $timer.Stop()
        foreach ($job in $jobs.GetEnumerator()) {
            if ($job.Value.Async.IsCompleted) {
                $completed++
                $result = $job.Value.PS.EndInvoke($job.Value.Async)
                $job.Value.PS.Dispose()
                $Script:Results += $result
                $dgResults.ItemsSource = $Script:Results  # WPF DataGrid
                Add-LogLine "$($result.Computer): $($result.Status)" "INFO"
            }
            else {
                $timer.Start()  # Re-arm for incomplete jobs
            }
        }

        if ($completed -eq $totalJobs) {
            $pool.Close()
            $script:isBusy = $false
        }
    })
    $timer.Start()
}
```

Read `xaml-styles.md` for the full Message Center, DataGrid styling, and busy-state guard patterns.

---

## Logging pattern for remote operations

Log every per-machine result so you can troubleshoot after the fact:

```powershell
$logFile = "C:\ProgramData\RemoteScan\Logs\RemoteScan_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-RemoteLog {
    param(
        [string]$Computer,
        [string]$Action,
        [string]$Result,
        [string]$Error
    )

    $entry = [pscustomobject]@{
        Timestamp  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Computer   = $Computer
        Action     = $Action
        Result     = $Result
        Error      = $Error
    }
    $entry | Export-Csv -Path $logFile -Append -NoTypeInformation -Encoding UTF8
}
```

Always include the **computer name** in every log line for remote operations. Without it, the log is unusable for troubleshooting.
