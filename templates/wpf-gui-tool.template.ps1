<#
.TITLE
    [ToolName] - [Brief Purpose]

.SYNOPSIS
    [One-line summary of what the tool does.]

.DESCRIPTION
    [Full description: what it targets, thresholds and parameters, what gets
    skipped, and how results are reported.]

    Architecture highlights (Tier 1 single-file):
    - XAML inline as here-string; loaded through a dual-parser safe loader.
    - Theme initialized immediately after load (prevents single-color screen).
    - Every interactive button wrapped in Guard-Action / Release-Action.
    - All colors flow through DynamicResource Tailwind Slate tokens.
    - SVG path icons only - zero symbol-font dependencies.

.TAGS
    Operational,GUI

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution)

.AUTHOR
    AI Generated

.VERSION
    1.0.0

.CHANGELOG
    1.0.0 ([YYYY-MM-DD])
    - Initial release

.LASTUPDATE
    [YYYY-MM-DD]

.EXAMPLE
    .\[ToolName].ps1
    Opens the tool window and initializes the UI.

.EXAMPLE
    .\[ToolName].ps1 -TryMode
    Runs with sample data - no live queries or changes.

.NOTES
    - Execution context: standard user; elevation detected at runtime.
    - Exit codes: 0 = normal exit after the user closes the window.
    - Log: %LOCALAPPDATA%\[ToolName]\Logs\
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$TryMode
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# STA CHECK + AUTO RESTART
# ============================================================================

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $relaunchArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', $PSCommandPath)
    if ($TryMode) { $relaunchArgs += '-TryMode' }
    if ($PSVersionTable.PSEdition -eq 'Core') {
        pwsh.exe @relaunchArgs
    } else {
        powershell.exe @relaunchArgs
    }
    exit
}

# Tool identity (used by Add-LogLine and settings persistence) — replace placeholder per tool
if (-not $ToolName) { $ToolName = '[ToolName]' }

# ============================================================================
# ============================================================================
# LOGGING (canonical: dot-source scripts/Add-LogLine.ps1 - never re-type)
# Single source of truth: scripts/Add-LogLine.ps1 (duplicate guard, file log,
# console). After dot-sourcing we extend it with a LogViewer subscriber so that
# every log line is mirrored into the in-app RichTextBox (Pattern E - LogViewer).
# ============================================================================

$_scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$_canonicalLog = Join-Path (Split-Path -Parent $_scriptRoot) 'scripts/Add-LogLine.ps1'
if (-not (Test-Path -LiteralPath $_canonicalLog)) {
    throw "Canonical logging module not found at: $_canonicalLog"
}
. (Get-Item -LiteralPath $_canonicalLog).FullName

# ---- Template-specific extensions below this line ----

# Structured log buffer (PSWrap schema): {Counter, Timestamp, Level, Message, Color}, FIFO 1000.
$script:LogCounter   = 0
$script:MaxLogLines  = 1000
$script:LogEntries   = [System.Collections.ArrayList]::new()
$script:LogViewerBox = $null

# Bridge: every Add-LogLine call also notifies the LogViewer subscriber (Pattern E).
$script:OnLogEntry = {
    param([string]$Timestamp, [string]$Level, [string]$Message)
    $color = switch ($Level) {
        'SUCCESS' { '#10B981' } 'WARNING' { '#F59E0B' } 'ERROR' { '#EF4444' }
        'DEBUG'   { '#94A3B8' } default   { '#3B82F6' }
    }
    $script:LogCounter++
    $shortTime = if ($Timestamp.Length -ge 8) { $Timestamp.Substring(11, 8) } else { $Timestamp }
    $null = $script:LogEntries.Add([PSCustomObject]@{
        Counter   = $script:LogCounter
        Timestamp = $shortTime
        Level     = $Level
        Message   = $Message
        Color     = $color
    })
    while ($script:LogEntries.Count -gt $script:MaxLogLines) { $null = $script:LogEntries.RemoveAt(0) }
    if ($script:LogViewerBox) {
        try {
            Add-LogViewerLine -Box $script:LogViewerBox -Entry $script:LogEntries[-1]
        } catch { }
    }
}

# ============================================================================
# SETTINGS PERSISTENCE (Pattern Q — settings.json in %LOCALAPPDATA%)
# Canonical: Get-AppSettings / Set-AppSettings (references/patterns.md).
# Template aliases Load-UserSettings / Save-UserSettings kept for back-compat.
# Security: never include passwords or client secrets in $Settings.
# ============================================================================

function Get-AppSettings {
    [CmdletBinding()]
    param([string]$ToolNameOverride)
    $raw = if ($ToolNameOverride) { $ToolNameOverride } elseif ($ToolName -and $ToolName -ne '[ToolName]') { $ToolName } elseif ($script:ToolName -and $script:ToolName -ne '[ToolName]') { $script:ToolName } elseif ($PSCommandPath) { [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) } else { 'PowerShellApp' }
    if ($raw -like '*.template') { $raw = $raw.Substring(0, $raw.Length - 9) }
    if ([string]::IsNullOrWhiteSpace($raw) -or $raw -eq '[ToolName]') { $raw = 'PowerShellApp' }
    $effectiveName = $raw
    $path = Join-Path $env:LOCALAPPDATA "$effectiveName\settings.json"
    if (Test-Path -LiteralPath $path) {
        try { return (Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop) } catch { return [PSCustomObject]@{} }
    }
    return [PSCustomObject]@{}
}

function Set-AppSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][hashtable]$Settings,
        [string]$ToolNameOverride
    )
    $raw = if ($ToolNameOverride) { $ToolNameOverride } elseif ($ToolName -and $ToolName -ne '[ToolName]') { $ToolName } elseif ($script:ToolName -and $script:ToolName -ne '[ToolName]') { $script:ToolName } elseif ($PSCommandPath) { [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) } else { 'PowerShellApp' }
    if ($raw -like '*.template') { $raw = $raw.Substring(0, $raw.Length - 9) }
    if ([string]::IsNullOrWhiteSpace($raw) -or $raw -eq '[ToolName]') { $raw = 'PowerShellApp' }
    $effectiveName = $raw
    $dir = Join-Path $env:LOCALAPPDATA $effectiveName
    if (-not (Test-Path -LiteralPath $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force -ErrorAction SilentlyContinue }
    $path = Join-Path $dir 'settings.json'
    try { $Settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding UTF8 -Force -ErrorAction Stop } catch { Write-Warning "Save settings failed: $($_.Exception.Message)" }
}

function Load-UserSettings {
    [CmdletBinding()] param([string]$ToolNameOverride)
    if ($PSBoundParameters.ContainsKey('ToolNameOverride')) { return Get-AppSettings -ToolNameOverride $ToolNameOverride }
    return Get-AppSettings
}

function Save-UserSettings {
    [CmdletBinding()] param([Parameter(Mandatory = $true)][hashtable]$Settings, [string]$ToolNameOverride)
    if ($PSBoundParameters.ContainsKey('ToolNameOverride')) { Set-AppSettings -Settings $Settings -ToolNameOverride $ToolNameOverride } else { Set-AppSettings -Settings $Settings }
}
# ============================================================================
# WPF ASSEMBLIES + THEME TOKENS (Tailwind Slate - references/design-tokens.md)
# ============================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Cached SolidColorBrush factory for Tailwind Slate token values.
function New-Brush {
    param([Parameter(Mandatory = $true)][string]$Hex)
    $brush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($Hex))
    $brush.Freeze()
    return $brush
}

$script:LightTokens = @{
    BackgroundBrush    = '#F1F5F9'; SurfaceBrush     = '#FFFFFF'; SurfaceHoverBrush = '#F1F5F9'
    SidebarBrush       = '#E8EDF4'; AccentBrush      = '#3B82F6'; AccentHoverBrush  = '#1D4ED8'
    AccentTintBrush    = '#EFF6FF'; SuccessBrush     = '#10B981'; DangerBrush       = '#EF4444'
    WarningBrush       = '#F59E0B'; TextPrimaryBrush = '#0F172A'; TextSecondaryBrush = '#64748B'
    TextMutedBrush     = '#94A3B8'; TextBodyBrush    = '#334155'; BorderBrush       = '#E2E8F0'
    BorderHoverBrush   = '#93C5FD'; SeparatorBg      = '#E2E8F0'
    BtnPrimaryBg       = '#4F46E5'; BtnBlueBg        = '#3B82F6'; BtnGreenBg  = '#10B981'
    BtnRedBg           = '#EF4444'; BtnPurpleBg      = '#A855F7'; BtnGhostFg  = '#64748B'
    BtnGhostHoverBg    = '#F1F5F9'; LinkFg           = '#3B82F6'
    CodeBg             = '#EFF6FF'; CodeFg           = '#1D4ED8'
    CodeBlockBg        = '#1E293B'; CodeBlockFg      = '#E2E8F0'
    TableBg            = '#FFFFFF'; TableHeaderBg    = '#F1F5F9'
    TableAltBg         = '#F8FAFC'; TableBorder      = '#E2E8F0'
    BlockquoteBg       = '#F0F9FF'; BlockquoteFg     = '#1E40AF'
    BulletFg           = '#3B82F6'; IconBg           = '#DBEAFE'; IconFg  = '#1D4ED8'
    HeadingFg          = '#0F172A'; BodyFg           = '#334155'; H4Fg    = '#1D4ED8'
    UnderlineFg        = '#3B82F6'
    TabAccentBg        = '#3B82F6'; TabAccentText    = '#FFFFFF'
    TabInactiveBg      = '#F8FAFC'; TabInactiveBorder = '#E2E8F0'; TabInactiveText = '#64748B'
    TabHoverBg         = '#F1F5F9'
}
$script:DarkTokens = @{
    BackgroundBrush    = '#1E293B'; SurfaceBrush     = '#334155'; SurfaceHoverBrush = '#475569'
    SidebarBrush       = '#475569'; AccentBrush      = '#60A5FA'; AccentHoverBrush  = '#93C5FD'
    AccentTintBrush    = '#1E3A5F'; SuccessBrush     = '#10B981'; DangerBrush       = '#EF4444'
    WarningBrush       = '#F59E0B'; TextPrimaryBrush = '#FFFFFF'; TextSecondaryBrush = '#CBD5E1'
    TextMutedBrush     = '#94A3B8'; TextBodyBrush    = '#E2E8F0'; BorderBrush       = '#475569'
    BorderHoverBrush   = '#60A5FA'; SeparatorBg      = '#475569'
    BtnPrimaryBg       = '#5B7CF5'; BtnBlueBg        = '#4A78E8'; BtnGreenBg  = '#2EA76E'
    BtnRedBg           = '#D9534F'; BtnPurpleBg      = '#9560D8'; BtnGhostFg  = '#A0A1A6'
    BtnGhostHoverBg    = '#232536'; LinkFg           = '#60A5FA'
    CodeBg             = '#1E3A5F'; CodeFg           = '#93C5FD'
    CodeBlockBg        = '#0F172A'; CodeBlockFg      = '#E2E8F0'
    TableBg            = '#334155'; TableHeaderBg    = '#475569'
    TableAltBg         = '#3B4A5E'; TableBorder      = '#475569'
    BlockquoteBg       = '#1E3A5F'; BlockquoteFg     = '#93C5FD'
    BulletFg           = '#60A5FA'; IconBg           = '#1E3A5F'; IconFg  = '#60A5FA'
    HeadingFg          = '#F1F5F9'; BodyFg           = '#E2E8F0'; H4Fg    = '#93C5FD'
    UnderlineFg        = '#60A5FA'
    TabAccentBg        = '#60A5FA'; TabAccentText    = '#FFFFFF'
    TabInactiveBg      = '#1E293B'; TabInactiveBorder = '#475569'; TabInactiveText = '#94A3B8'
    TabHoverBg         = '#334155'
}

# Swaps DynamicResource token values between the light/dark palettes.
function Set-Theme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Window,
        [Parameter(Mandatory = $true)][bool]$IsDark
    )
    $tokens = if ($IsDark) { $script:DarkTokens } else { $script:LightTokens }
    foreach ($key in $tokens.Keys) {
        # Indexer replacement on a XamlReader-built dictionary corrupts deferred
        # DynamicResource references ("'#FF...' is not a valid value for property").
        # Remove + Add re-registers the resource cleanly - verified on 5.1 and pwsh.
        if ($Window.Resources.Contains($key)) { $null = $Window.Resources.Remove($key) }
        $Window.Resources.Add($key, (New-Brush -Hex $tokens[$key]))
    }
    $Window.Background = New-Brush -Hex $tokens['BackgroundBrush']
}

$SunIconData  = 'M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41L5.99 4.58zm12.37 12.37c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0 .39-.39.39-1.03 0-1.41l-1.06-1.06zm1.06-10.96c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06zM7.05 18.36c-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06z'
$MoonIconData = 'M9 2c-1.05 0-2.05.16-3 .46 4.06 1.27 7 5.06 7 9.54 0 4.48-2.94 8.27-7 9.54.95.3 1.95.46 3 .46 5.52 0 10-4.48 10-10S14.52 2 9 2z'

# ============================================================================
# XAML (all 19 canonical styles - references/xaml-styles.md)
# ============================================================================

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="[Tool Name]" Width="1100" Height="830" MinWidth="900" MinHeight="640"
        WindowStartupLocation="CenterScreen"
        WindowStyle="SingleBorderWindow" ResizeMode="CanResizeWithGrip"
        Background="{DynamicResource BackgroundBrush}"
        FontFamily="Segoe UI Variable Display, Segoe UI" FontSize="13"
        UseLayoutRounding="True" SnapsToDevicePixels="True" AllowDrop="True">
    <Window.Resources>
        <SolidColorBrush x:Key="BackgroundBrush" Color="#F1F5F9"/>
        <SolidColorBrush x:Key="SurfaceBrush" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="SurfaceHoverBrush" Color="#F1F5F9"/>
        <SolidColorBrush x:Key="SidebarBrush" Color="#E8EDF4"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#3B82F6"/>
        <SolidColorBrush x:Key="AccentHoverBrush" Color="#1D4ED8"/>
        <SolidColorBrush x:Key="AccentTintBrush" Color="#EFF6FF"/>
        <SolidColorBrush x:Key="SuccessBrush" Color="#10B981"/>
        <SolidColorBrush x:Key="DangerBrush" Color="#EF4444"/>
        <SolidColorBrush x:Key="WarningBrush" Color="#F59E0B"/>
        <SolidColorBrush x:Key="TextPrimaryBrush" Color="#0F172A"/>
        <SolidColorBrush x:Key="TextSecondaryBrush" Color="#64748B"/>
        <SolidColorBrush x:Key="TextMutedBrush" Color="#94A3B8"/>
        <SolidColorBrush x:Key="TextBodyBrush" Color="#334155"/>
        <SolidColorBrush x:Key="BorderBrush" Color="#E2E8F0"/>
        <SolidColorBrush x:Key="BorderHoverBrush" Color="#93C5FD"/>
        <SolidColorBrush x:Key="SeparatorBg" Color="#E2E8F0"/>

        <!-- 1/19 ProgressBar (implicit) -->
        <Style TargetType="{x:Type ProgressBar}">
            <Setter Property="Background" Value="{DynamicResource BorderBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource SuccessBrush}" />
            <Setter Property="BorderThickness" Value="0" />
            <Setter Property="Height" Value="8" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ProgressBar}">
                        <Grid>
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" />
                            <Border x:Name="PART_Indicator" Background="{TemplateBinding Foreground}" CornerRadius="6" HorizontalAlignment="Left" />
                            <Border x:Name="IndeterminateGlow" Background="{TemplateBinding Foreground}" CornerRadius="6" HorizontalAlignment="Left" Width="100" Visibility="Hidden">
                                <Border.RenderTransform><TranslateTransform x:Name="GlowTransform" X="-100" /></Border.RenderTransform>
                            </Border>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsIndeterminate" Value="True">
                                <Setter TargetName="PART_Indicator" Property="Visibility" Value="Hidden" />
                                <Setter TargetName="IndeterminateGlow" Property="Visibility" Value="Visible" />
                                <Trigger.EnterActions>
                                    <BeginStoryboard x:Name="IndeterminateStoryboard">
                                        <Storyboard RepeatBehavior="Forever">
                                            <DoubleAnimation Storyboard.TargetName="GlowTransform" Storyboard.TargetProperty="X" From="-100" To="400" Duration="0:0:1.5" />
                                        </Storyboard>
                                    </BeginStoryboard>
                                </Trigger.EnterActions>
                                <Trigger.ExitActions>
                                    <StopStoryboard BeginStoryboardName="IndeterminateStoryboard" />
                                </Trigger.ExitActions>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- 2/19 BtnBase (polished: hover lift DropShadow, Opacity 0.88/0.78/0.55) -->
        <Style x:Key="BtnBase" TargetType="{x:Type Button}">
            <Setter Property="BorderThickness" Value="0" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="Padding" Value="16,0" />
            <Setter Property="Height" Value="38" />
            <Setter Property="MinWidth" Value="100" />
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect BlurRadius="10" ShadowDepth="2" Color="#0F172A" Opacity="0.06" Direction="270"/>
                </Setter.Value>
            </Setter>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Button}">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="UIElement.Opacity" Value="0.88" />
                                <Setter TargetName="border" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect BlurRadius="14" ShadowDepth="3" Color="#0F172A" Opacity="0.09" Direction="270"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="UIElement.Opacity" Value="0.78" />
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Background" Value="{DynamicResource SurfaceHoverBrush}" />
                                <Setter TargetName="border" Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
                                <Setter TargetName="border" Property="BorderThickness" Value="1" />
                                <Setter Property="Foreground" Value="{DynamicResource TextMutedBrush}" />
                                <Setter TargetName="border" Property="UIElement.Opacity" Value="0.55" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- 3-8/19 Btn variants -->
        <Style x:Key="BtnPrimary" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="{DynamicResource BtnPrimaryBg}" /><Setter Property="Foreground" Value="White" />
        </Style>
        <Style x:Key="BtnBlue" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="{DynamicResource BtnBlueBg}" /><Setter Property="Foreground" Value="White" />
        </Style>
        <Style x:Key="BtnGreen" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="{DynamicResource BtnGreenBg}" /><Setter Property="Foreground" Value="White" />
        </Style>
        <Style x:Key="BtnRed" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="{DynamicResource BtnRedBg}" /><Setter Property="Foreground" Value="White" />
        </Style>
        <Style x:Key="BtnPurple" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="{DynamicResource BtnPurpleBg}" /><Setter Property="Foreground" Value="White" />
        </Style>
        <Style x:Key="BtnGhost" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="Transparent" /><Setter Property="Foreground" Value="{DynamicResource BtnGhostFg}" />
        </Style>

        <!-- 9/19 BtnOutline -->
        <Style x:Key="BtnOutline" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="Foreground" Value="{DynamicResource TextBodyBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
        </Style>

        <!-- 10/19 NavBtnBase (PSWrap-exact: hover SurfaceHover, pressed AccentTint) -->
        <Style x:Key="NavBtnBase" TargetType="{x:Type Button}">
            <Setter Property="Height" Value="46" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="HorizontalContentAlignment" Value="Left" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
            <Setter Property="Padding" Value="20,0" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="FontSize" Value="14" />
            <Setter Property="Margin" Value="0,0,0,8" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Button}">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="10" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}" Margin="{TemplateBinding Padding}" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="{DynamicResource SurfaceHoverBrush}" />
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="{DynamicResource AccentTintBrush}" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- 11/19 Card (static - no hover) -->
        <Style x:Key="Card" TargetType="{x:Type Border}">
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="CornerRadius" Value="14" />
            <Setter Property="Padding" Value="18" />
            <Setter Property="Margin" Value="0,0,0,12" />
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect BlurRadius="24" ShadowDepth="6" Color="#0F172A" Opacity="0.045" Direction="270" />
                </Setter.Value>
            </Setter>
        </Style>

        <!-- 12/19 StatCard (sanctioned border-highlight hover) -->
        <Style x:Key="StatCard" TargetType="{x:Type Border}">
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="CornerRadius" Value="14" />
            <Setter Property="Padding" Value="18,16" />
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="BorderBrush" Value="{DynamicResource BorderHoverBrush}" />
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- 13/19 InputBox (keyboard focus only - NO IsMouseOver) -->
        <Style x:Key="InputBox" TargetType="TextBox">
            <Setter Property="Height" Value="34" />
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource TextPrimaryBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="Padding" Value="10,0" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
            <Setter Property="CaretBrush" Value="{DynamicResource AccentBrush}" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="bdInput" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" SnapsToDevicePixels="True">
                            <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}" VerticalAlignment="Center" Focusable="False" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsKeyboardFocused" Value="True">
                                <Setter TargetName="bdInput" Property="BorderBrush" Value="{DynamicResource AccentBrush}" />
                                <Setter TargetName="bdInput" Property="BorderThickness" Value="1.5" />
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.55" /></Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- 14/19 InputBoxNoHover -->
        <Style x:Key="InputBoxNoHover" TargetType="TextBox" BasedOn="{StaticResource InputBox}" />

        <!-- 15/19 StyledCheckBox -->
        <Style x:Key="StyledCheckBox" TargetType="CheckBox">
            <Setter Property="Foreground" Value="{DynamicResource TextPrimaryBrush}" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
            <Setter Property="Cursor" Value="Hand" />
        </Style>

        <!-- 16/19 StyledComboBox -->
        <Style x:Key="StyledComboBox" TargetType="ComboBox">
            <Setter Property="Height" Value="34" />
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource TextPrimaryBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="Padding" Value="8,4" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
        </Style>

        <!-- 17/19 FieldLabel -->
        <Style x:Key="FieldLabel" TargetType="TextBlock">
            <Setter Property="Foreground" Value="{DynamicResource TextSecondaryBrush}" />
            <Setter Property="VerticalAlignment" Value="Center" />
            <Setter Property="FontSize" Value="14" />
            <Setter Property="FontWeight" Value="SemiBold" />
        </Style>

        <!-- 18/19 BottomActionBtn -->
        <Style x:Key="BottomActionBtn" TargetType="{x:Type Button}">
            <Setter Property="Height" Value="34" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="Padding" Value="8,0" />
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource TextBodyBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Button}">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="{DynamicResource AccentTintBrush}" />
                                <Setter TargetName="border" Property="BorderBrush" Value="{DynamicResource AccentBrush}" />
                                <Setter Property="Foreground" Value="{DynamicResource AccentHoverBrush}" />
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="{DynamicResource AccentBrush}" />
                                <Setter Property="Foreground" Value="White" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- 19/19 LiveMessageCenterBox -->
        <Style x:Key="LiveMessageCenterBox" TargetType="RichTextBox">
            <Setter Property="Height" Value="140" />
            <Setter Property="IsReadOnly" Value="True" />
            <Setter Property="Background" Value="#1E293B" />
            <Setter Property="Foreground" Value="#E2E8F0" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="FontFamily" Value="Consolas, Cascadia Code, monospace" />
            <Setter Property="FontSize" Value="12" />
            <Setter Property="Padding" Value="8" />
            <Setter Property="VerticalScrollBarVisibility" Value="Auto" />
        </Style>

        <!-- 20/20 SessionCard (canonical key 19/19 + widget; this is the 20th WPF widget, complements the 19 canonical style keys) -->
        <Style x:Key="SessionCard" TargetType="{x:Type Border}">
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="CornerRadius" Value="8" />
            <Setter Property="Padding" Value="10" />
            <Setter Property="Margin" Value="0,0,0,10" />
        </Style>

        <!-- Enterprise DataGrid theme (polished tables) -->
        <Style TargetType="{x:Type DataGrid}">
            <Setter Property="Background" Value="{DynamicResource TableBg}" />
            <Setter Property="BorderBrush" Value="{DynamicResource TableBorder}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="RowBackground" Value="{DynamicResource TableBg}" />
            <Setter Property="AlternatingRowBackground" Value="{DynamicResource TableAltBg}" />
            <Setter Property="AlternationCount" Value="2" />
            <Setter Property="HeadersVisibility" Value="Column" />
            <Setter Property="GridLinesVisibility" Value="Horizontal" />
            <Setter Property="HorizontalGridLinesBrush" Value="{DynamicResource TableBorder}" />
            <Setter Property="RowHeight" Value="34" />
            <Setter Property="FontSize" Value="12.5" />
            <Setter Property="AutoGenerateColumns" Value="False" />
            <Setter Property="IsReadOnly" Value="True" />
            <Setter Property="CanUserAddRows" Value="False" />
            <Setter Property="CanUserReorderColumns" Value="False" />
            <Setter Property="CanUserResizeRows" Value="False" />
            <Setter Property="SelectionMode" Value="Single" />
            <Setter Property="SelectionUnit" Value="FullRow" />
            <Setter Property="RowHeaderWidth" Value="0" />
        </Style>
        <Style TargetType="{x:Type DataGridColumnHeader}">
            <Setter Property="Background" Value="{DynamicResource TableHeaderBg}" />
            <Setter Property="Foreground" Value="{DynamicResource TextSecondaryBrush}" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="FontSize" Value="11" />
            <Setter Property="Padding" Value="12,9" />
            <Setter Property="BorderBrush" Value="{DynamicResource TableBorder}" />
            <Setter Property="BorderThickness" Value="0,0,1,1" />
            <Setter Property="HorizontalContentAlignment" Value="Left" />
            <Setter Property="VerticalContentAlignment" Value="Center" />
            <Setter Property="Height" Value="36" />
        </Style>
        <Style TargetType="{x:Type DataGridRow}">
            <Setter Property="Background" Value="{DynamicResource TableBg}" />
            <Setter Property="SnapsToDevicePixels" Value="True" />
            <Style.Triggers>
                <Trigger Property="AlternationIndex" Value="1"><Setter Property="Background" Value="{DynamicResource TableAltBg}" /></Trigger>
                <Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="{DynamicResource AccentTintBrush}" /></Trigger>
                <Trigger Property="IsSelected" Value="True"><Setter Property="Background" Value="{DynamicResource AccentTintBrush}" /><Setter Property="Foreground" Value="{DynamicResource TextPrimaryBrush}" /></Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="{x:Type DataGridCell}">
            <Setter Property="Padding" Value="12,0" />
            <Setter Property="BorderThickness" Value="0" />
            <Setter Property="Foreground" Value="{DynamicResource TextBodyBrush}" />
            <Setter Property="FontSize" Value="12.5" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type DataGridCell}">
                        <Border Padding="{TemplateBinding Padding}" Background="{TemplateBinding Background}" SnapsToDevicePixels="True">
                            <ContentPresenter VerticalAlignment="Center" />
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="220" MinWidth="180" MaxWidth="280" />
            <ColumnDefinition Width="*" />
        </Grid.ColumnDefinitions>

        <!-- COLUMN 0: FULL-HEIGHT NAVBAR (top edge -> bottom edge, left side) -->
        <Border Grid.Column="0" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="0,0,1,0" Background="{DynamicResource SidebarBrush}">
            <DockPanel LastChildFill="True">
                <StackPanel DockPanel.Dock="Top" Margin="16">
                    <StackPanel Orientation="Horizontal">
                        <Border Width="40" Height="40" CornerRadius="10">
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                    <GradientStop Color="#3B82F6" Offset="0" />
                                    <GradientStop Color="#8B5CF6" Offset="0.6" />
                                    <GradientStop Color="#EC4899" Offset="1" />
                                </LinearGradientBrush>
                            </Border.Background>
                            <Border.Effect>
                                <DropShadowEffect BlurRadius="8" ShadowDepth="2" Color="#3B82F6" Opacity="0.25" Direction="270" />
                            </Border.Effect>
                            <Path Stretch="Uniform" Width="20" Height="20" Fill="{DynamicResource SurfaceBrush}" Data="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-7 9h-2V7h-2v5H6v2h2v5h2v-5h2v-2zm4 4h-2v-5h2v5zm0-7h-2V7h2v2z" HorizontalAlignment="Center" VerticalAlignment="Center" />
                        </Border>
                        <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
                            <TextBlock Text="[ToolName]" FontSize="18" FontFamily="Segoe UI" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimaryBrush}" />
                            <TextBlock Text="[Tagline]" FontSize="12" Foreground="{DynamicResource TextSecondaryBrush}" FontWeight="SemiBold" />
                        </StackPanel>
                    </StackPanel>
                </StackPanel>

                <!-- Footer: About/Logs + version (docked to window bottom) -->
                <Border DockPanel.Dock="Bottom" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="0,1,0,0" Padding="12,10" Background="Transparent">
                    <StackPanel>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" /><ColumnDefinition Width="*" />
                            </Grid.ColumnDefinitions>
                            <Button Grid.Column="0" x:Name="AboutBtn" Style="{StaticResource BottomActionBtn}" ToolTip="View tool documentation and details" Margin="0,0,3,0">
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                    <Path Stretch="Uniform" Width="14" Height="14" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" Data="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z" Margin="0,0,8,0" VerticalAlignment="Center" />
                                    <TextBlock Text="About" VerticalAlignment="Center" />
                                </StackPanel>
                            </Button>
                            <Button Grid.Column="1" x:Name="LogsBtn" Style="{StaticResource BottomActionBtn}" ToolTip="View detailed activity logs" Margin="3,0,0,0">
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                    <Path Stretch="Uniform" Width="14" Height="14" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" Data="M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm16-4H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H8V4h12v12zM10 9h8v2h-8V9zm0 3h4v2h-4v-2zm0-6h8v2h-8V6z" Margin="0,0,8,0" VerticalAlignment="Center" />
                                    <TextBlock Text="Logs" VerticalAlignment="Center" />
                                </StackPanel>
                            </Button>
                        </Grid>
                        <Border BorderBrush="{DynamicResource TextMutedBrush}" BorderThickness="0,1,0,0" Margin="-12,8,-12,10" Opacity="0.4" />
                        <StackPanel>
                            <TextBlock FontSize="13" Foreground="{DynamicResource TextPrimaryBrush}" FontWeight="SemiBold" Margin="0,0,0,2">[ToolName]</TextBlock>
                            <TextBlock Text="Version 1.0" FontSize="11" Foreground="{DynamicResource TextMutedBrush}" FontWeight="SemiBold" />
                            <!-- TODO: update version text above; add author Hyperlink if desired -->
                        </StackPanel>
                    </StackPanel>
                </Border>

                <!-- Nav buttons fill the remaining height -->
                <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <StackPanel Margin="16,12,16,16">
                        <Button x:Name="NavBtnDashboard" Style="{StaticResource NavBtnBase}" ToolTip="Open the main dashboard page">
                            <StackPanel Orientation="Horizontal">
                                <Path Stretch="Uniform" Width="18" Height="18" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" Data="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-7 9h-2V7h-2v5H6v2h2v5h2v-5h2v-2zm4 4h-2v-5h2v5zm0-7h-2V7h2v2z" Margin="0,0,14,0" VerticalAlignment="Center" />
                                <TextBlock Text="Dashboard" VerticalAlignment="Center" />
                            </StackPanel>
                        </Button>
                        <!-- TODO: duplicate this button per page and pair it inside Set-ActivePage -->
                    </StackPanel>
                </ScrollViewer>
            </DockPanel>
        </Border>

        <!-- COLUMN 1: WORKSPACE (header / content / status bar) -->
        <Grid Grid.Column="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
            </Grid.RowDefinitions>

            <!-- ROW 0: HEADER (system controls top-right per Sidebar Law) -->
        <Border Grid.Row="0" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource SeparatorBg}" BorderThickness="0,0,0,1" Padding="16,10,16,10">
            <DockPanel LastChildFill="False">
                <TextBlock DockPanel.Dock="Left" Text="[Tool Name]" FontSize="17" FontWeight="Bold" Foreground="{DynamicResource TextPrimaryBrush}" VerticalAlignment="Center"/>
                <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
                    <Ellipse x:Name="ConnectionDot" Width="8" Height="8" Fill="{DynamicResource SuccessBrush}"/>
                    <TextBlock x:Name="ConnectionLabel" Text="Ready" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource TextSecondaryBrush}" Margin="6,0,16,0"/>
                    <Button x:Name="btnThemeToggle" Style="{StaticResource BtnGhost}" Width="38" MinWidth="0" Height="34" Padding="0" ToolTip="Switch to Dark theme">
                        <Path x:Name="ThemeIcon" Data="{x:Null}" Stretch="Uniform" Width="14" Height="14"/>
                    </Button>
                </StackPanel>
            </DockPanel>
        </Border>

        <!-- ROW 1: CONTENT -->
        <Grid Grid.Row="1" Margin="24,8,24,8">
            <!-- TODO: main content area - Cards, StatCards, forms, grids -->
            <Grid x:Name="PageDashboard">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" /><RowDefinition Height="*" />
                </Grid.RowDefinitions>
                <Border Grid.Row="0" Style="{StaticResource SessionCard}">
                    <StackPanel>
                        <TextBlock Text="SESSION" FontSize="11" FontWeight="Bold" Foreground="{DynamicResource TextSecondaryBrush}" Margin="0,0,0,6"/>
                        <TextBlock x:Name="SessionMachineTxt" Text="--" Foreground="{DynamicResource TextPrimaryBrush}" FontWeight="SemiBold"/>
                        <TextBlock x:Name="SessionUserTxt" Text="--" Foreground="{DynamicResource TextSecondaryBrush}" FontWeight="SemiBold"/>
                    </StackPanel>
                </Border>
                <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,12,0,0">
                    <TextBlock Text="Replace this card with your first feature." Style="{StaticResource FieldLabel}"/>
                </Border>
            </Grid>
        </Grid>

        <!-- ROW 2: STATUS BAR (canonical quartet + progress) -->
        <Border Grid.Row="2" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource SeparatorBg}" BorderThickness="0,1,0,0" Padding="16,6,20,6">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" /><ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /><ColumnDefinition Width="Auto" />
                </Grid.ColumnDefinitions>
                <Ellipse x:Name="StatusDot" Grid.Column="0" Width="8" Height="8" Fill="{DynamicResource SuccessBrush}" VerticalAlignment="Center"/>
                <TextBlock x:Name="StatusLabel" Grid.Column="1" Text="Ready" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource TextSecondaryBrush}" Margin="8,0,0,0" VerticalAlignment="Center"/>
                <TextBlock x:Name="StatusBarText" Grid.Column="2" Text="Starting..." FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource TextMutedBrush}" Margin="16,0,0,0" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                <ProgressBar x:Name="ProgressBar" Grid.Column="3" Width="140" VerticalAlignment="Center" Margin="0,0,16,0"/>
                <TextBlock x:Name="StatusTime" Grid.Column="4" Text="--:--:--" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource TextSecondaryBrush}" VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <!-- Toast stack (Pattern L - PSWrap-style animated notifications, never MessageBox) -->
        <StackPanel x:Name="ToastContainer" Grid.Row="1" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="0,0,8,16" Panel.ZIndex="99"/>
        </Grid>
    </Grid>
</Window>
'@

# ============================================================================
# SAFE XAML LOADER (dual parser)
# ============================================================================

# Parses XAML through both parsers and returns the live Window object.
function ConvertTo-XamlWindow {
    param([string]$Xaml)
    $clean = $Xaml -replace 'x:Class=".*?"', '' -replace 'mc:Ignorable=".*?"', ''
    $clean = $clean.Trim()
    # Parse FIRST (PSWrap-proven): XmlNodeReader+Load yields a dictionary whose
    # indexer updates corrupt deferred DynamicResource refs - Load is fallback only.
    try {
        return [System.Windows.Markup.XamlReader]::Parse($clean)
    }
    catch {
        try {
            $reader = New-Object System.Xml.XmlNodeReader([xml]$clean)
            return [System.Windows.Markup.XamlReader]::Load($reader)
        }
        catch {
            Add-LogLine "XAML parse failed: $($_.Exception.Message)" 'ERROR'
            throw
        }
    }
}

$script:Window = ConvertTo-XamlWindow -Xaml $xaml

# --- Initialize theme IMMEDIATELY (restores saved preference when present) ---
$script:isDarkMode = $false
$savedSettings = Load-UserSettings
if ($savedSettings -and $savedSettings.Theme -eq 'Dark') { $script:isDarkMode = $true }
Set-Theme -Window $script:Window -IsDark $script:isDarkMode
try {
    if ($script:Window.FindName('ThemeIcon')) {
        $icon = $script:Window.FindName('ThemeIcon')
        if ($script:isDarkMode) {
            $icon.Data = [System.Windows.Media.Geometry]::Parse($MoonIconData)
            $icon.Fill = (New-Object System.Windows.Media.BrushConverter).ConvertFromString('#CBD5E1')
        }
        else {
            $icon.Data = [System.Windows.Media.Geometry]::Parse($SunIconData)
            $icon.Fill = (New-Object System.Windows.Media.BrushConverter).ConvertFromString('#EAB308')
        }
    }
}
catch { Add-LogLine "Initial theme setup failed: $($_.Exception.Message)" 'WARNING' }

# ============================================================================
# CONTROL BINDINGS (every x:Name gets FindName + presence assertion)
# ============================================================================

foreach ($name in @('ConnectionDot','ConnectionLabel','btnThemeToggle','ThemeIcon',
                    'SessionMachineTxt','SessionUserTxt','StatusBarText',
                    'StatusDot','StatusLabel','StatusTime','ProgressBar',
                    'ToastContainer','NavBtnDashboard','AboutBtn','LogsBtn',
                    'PageDashboard')) {
    if (-not $script:Window.FindName($name)) {
        throw "Missing control in XAML: $name"
    }
}
$script:ConnectionDot   = $script:Window.FindName('ConnectionDot')
$script:ConnectionLabel = $script:Window.FindName('ConnectionLabel')
$script:btnThemeToggle  = $script:Window.FindName('btnThemeToggle')
$script:ThemeIcon       = $script:Window.FindName('ThemeIcon')
$script:StatusDot       = $script:Window.FindName('StatusDot')
$script:ToastContainer = $script:Window.FindName('ToastContainer')

# IDENTITY LOCK bridge: canonical Add-LogLine updates $script:lblStatusText;
# the XAML quartet name is StatusBarText - bind the hook to it here.
$script:lblStatusText = $script:Window.FindName('StatusBarText')
$script:NavBtnDashboard = $script:Window.FindName('NavBtnDashboard')
$script:AboutBtn        = $script:Window.FindName('AboutBtn')
$script:LogsBtn         = $script:Window.FindName('LogsBtn')
$script:PageDashboard   = $script:Window.FindName('PageDashboard')

Add-LogLine 'All XAML controls bound successfully' 'DEBUG'

# ============================================================================
# FEATURES: LOG VIEWER (Pattern E) + ABOUT DIALOG (Pattern M)
# Child dialogs parse WITHOUT StaticResource, then receive theme resources via
# Remove+Add copy - the only safe injection order (see pitfalls.md).
# ============================================================================

# Copies every brush/style resource from the main window into a child dialog.
function Copy-ThemeResources {
    [CmdletBinding()]
    param($Source, $Target)
    foreach ($key in @($Source.Resources.Keys)) {
        $res = $Source.Resources[$key]
        if ($Target.Resources.Contains($key)) { $null = $Target.Resources.Remove($key) }
        $null = $Target.Resources.Add($key, $res)
    }
}

# Appends one structured entry ({Timestamp,Level,Message,Color}) to the terminal view.
function Add-LogViewerLine {
    [CmdletBinding()]
    param($Box, [PSCustomObject]$Entry)
    if (-not $Box -or -not $Entry) { return }
    if (-not $Box.Tag) {
        $para = New-Object System.Windows.Documents.Paragraph
        $para.LineHeight = 18
        $Box.Document.Blocks.Add($para)
        $Box.Tag = $para
    }
    $head = New-Object System.Windows.Documents.Run("[{0}] [{1}] " -f $Entry.Timestamp, $Entry.Level)
    $head.Foreground = New-Brush -Hex $Entry.Color
    $head.FontWeight = [System.Windows.FontWeights]::SemiBold
    $body = New-Object System.Windows.Documents.Run($Entry.Message)
    $body.Foreground = New-Brush -Hex '#F8FAFC'
    $null = $Box.Tag.Inlines.Add($head)
    $null = $Box.Tag.Inlines.Add($body)
    $null = $Box.Tag.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
    $Box.ScrollToEnd()
}

# Builds the LogViewer child window (theme-copied, live feed wired).
function New-LogViewerWindow {
    [CmdletBinding()]
    param()
    $x = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Activity Log" Width="900" Height="600" MinWidth="600" MinHeight="400"
        WindowStartupLocation="CenterOwner" WindowStyle="SingleBorderWindow"
        ResizeMode="CanResizeWithGrip" Background="{DynamicResource BackgroundBrush}">
    <DockPanel>
        <Border DockPanel.Dock="Top" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource SeparatorBg}" BorderThickness="0,0,0,1" Padding="14,10">
            <DockPanel LastChildFill="False">
                <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" VerticalAlignment="Center">
                    <Path Stretch="Uniform" Width="16" Height="16" Fill="{DynamicResource AccentBrush}" Data="M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm16-4H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H8V4h12v12zM10 9h8v2h-8V9zm0 3h4v2h-4v-2zm0-6h8v2h-8V6z"/>
                    <TextBlock Text="Activity Log" FontSize="15" FontWeight="Bold" Foreground="{DynamicResource TextPrimaryBrush}" Margin="8,0,0,0" VerticalAlignment="Center"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
                    <Button x:Name="lvCopyBtn" Background="{DynamicResource BtnBlueBg}" Foreground="White" BorderThickness="0" Cursor="Hand" Padding="14,6" Margin="0,0,8,0" FontSize="12" FontWeight="SemiBold">
                        <StackPanel Orientation="Horizontal"><Path Stretch="Uniform" Width="12" Height="12" Fill="White" Data="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/><TextBlock Text="Copy" Margin="6,0,0,0"/></StackPanel>
                    </Button>
                    <Button x:Name="lvClearBtn" Background="{DynamicResource DangerBrush}" Foreground="White" BorderThickness="0" Cursor="Hand" Padding="14,6" Margin="0,0,8,0" FontSize="12" FontWeight="SemiBold">
                        <StackPanel Orientation="Horizontal"><Path Stretch="Uniform" Width="12" Height="12" Fill="White" Data="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/><TextBlock Text="Clear" Margin="6,0,0,0"/></StackPanel>
                    </Button>
                    <Button x:Name="lvCloseBtn" Background="{DynamicResource SurfaceHoverBrush}" Foreground="{DynamicResource TextPrimaryBrush}" BorderThickness="0" Cursor="Hand" Padding="14,6" FontSize="12" FontWeight="SemiBold" Content="Close"/>
                </StackPanel>
            </DockPanel>
        </Border>
        <Border DockPanel.Dock="Bottom" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource SeparatorBg}" BorderThickness="0,1,0,0" Padding="14,6">
            <TextBlock x:Name="lvCountText" Text="0 entries" FontSize="11" FontWeight="SemiBold" Foreground="{DynamicResource TextMutedBrush}"/>
        </Border>
        <RichTextBox x:Name="lvBox" Margin="12,12,12,12" Background="{DynamicResource CodeBlockBg}" Foreground="{DynamicResource CodeBlockFg}"
                     FontFamily="Cascadia Code, Consolas, Courier New" FontSize="12" IsReadOnly="True" VerticalScrollBarVisibility="Auto"
                     BorderThickness="0" Padding="10">
            <FlowDocument PagePadding="0"/>
        </RichTextBox>
    </DockPanel>
</Window>
'@
    $win = ConvertTo-XamlWindow -Xaml $x
    Copy-ThemeResources -Source $script:Window -Target $win

    $box = $win.FindName('lvBox')
    $count = $win.FindName('lvCountText')
    # Handlers run LATER under WPF dispatch - they CANNOT see this function's
    # locals ($win/$box). Publish script-scoped refs for them to bind against.
    $script:LogViewerWindow = $win
    $script:LogViewerBox = $box
    $script:lvCountText = $count

    foreach ($entry in $script:LogEntries) { Add-LogViewerLine -Box $box -Entry $entry }
    $count.Text = "{0} entries" -f $script:LogEntries.Count

    $win.FindName('lvCopyBtn').Add_Click({
        try {
            $sb = New-Object System.Text.StringBuilder
            foreach ($entry in $script:LogEntries) {
                $null = $sb.Append('[').Append($entry.Counter).Append('] [').Append($entry.Timestamp).Append('] [').Append($entry.Level).Append('] ').AppendLine($entry.Message)
            }
            $text = $sb.ToString()
            try { [System.Windows.Clipboard]::SetText($text) } catch { $null = ($text | Set-Clipboard) }
            Show-ToastMessage 'Log copied to clipboard.' 'Success'
        } catch { Show-ToastMessage "Copy failed: $($_.Exception.Message)" 'Error' }
    }) | Out-Null
    $win.FindName('lvClearBtn').Add_Click({
        try {
            $script:LogViewerBox.Document.Blocks.Clear(); $script:LogViewerBox.Tag = $null
            $script:LogEntries.Clear(); $script:lvCountText.Text = '0 entries'
            Show-ToastMessage 'Log viewer cleared.' 'Info'
        } catch { Show-ToastMessage "Clear failed: $($_.Exception.Message)" 'Error' }
    }) | Out-Null
    $win.FindName('lvCloseBtn').Add_Click({ $script:LogViewerWindow.Close() }) | Out-Null

    return $win
}

# Opens the live Activity Log window (Pattern E).
function Show-LogViewer {
    [CmdletBinding()]
    param()
    $win = New-LogViewerWindow
    if (-not $win) {
        Add-LogLine 'Activity Log window failed to build' 'ERROR'
        return
    }
    $win.Owner = $script:Window
    $win.Add_Closed({
        $script:LogViewerBox = $null
        $script:LogViewerWindow = $null
        $script:lvCountText = $null
    })
    $null = $win.ShowDialog()
}

# Builds the About dialog (gradient hero + feature cards, Pattern M style).
function New-AboutWindow {
    [CmdletBinding()]param()
    $x=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="About - [ToolName]" Width="560" Height="520" MinWidth="520" MinHeight="480" WindowStartupLocation="CenterOwner" WindowStyle="SingleBorderWindow" ResizeMode="NoResize" Background="{DynamicResource BackgroundBrush}">
    <Grid><Grid.RowDefinitions><RowDefinition Height="140" /><RowDefinition Height="*" /><RowDefinition Height="Auto" /></Grid.RowDefinitions>
        <Border Grid.Row="0"><Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#3B82F6" Offset="0" /><GradientStop Color="#8B5CF6" Offset="0.55" /><GradientStop Color="#EC4899" Offset="1" /></LinearGradientBrush></Border.Background>
            <Grid Margin="20,14">
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <Border Width="56" Height="56" CornerRadius="14" Background="#22FFFFFF" VerticalAlignment="Center"><Path Stretch="Uniform" Width="28" Height="28" Fill="White" Data="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h10v2zm3-4H7v-2h10v2zm-3-4H7V7h10v2z" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
                <StackPanel Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
                    <TextBlock Text="[ToolName]" FontSize="20" FontWeight="ExtraBold" Foreground="White"/>
                    <TextBlock Text="[Tagline]" FontSize="12" Foreground="#E6FFFFFF" Margin="0,2,0,0"/>
                    <StackPanel Orientation="Horizontal" Margin="0,8,0,0">
                        <Border Background="#33FFFFFF" CornerRadius="6" Padding="7,3" Margin="0,0,6,0"><TextBlock Text="v[Version]" FontSize="11" FontWeight="SemiBold" Foreground="White"/></Border>
                        <Border Background="#33FFFFFF" CornerRadius="6" Padding="7,3"><TextBlock Text="MIT License" FontSize="11" FontWeight="SemiBold" Foreground="White"/></Border>
                    </StackPanel>
                </StackPanel>
            </Grid>
        </Border>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Margin="20,14,20,10">
                <TextBlock Text="[ToolName] is a [brief description] that provides a user-friendly interface for [task]." FontSize="13" TextWrapping="Wrap" Foreground="{DynamicResource TextBodyBrush}" Margin="0,0,0,14"/>

                <Border Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="12" Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Highlights" FontSize="11" FontWeight="Bold" Foreground="{DynamicResource TextSecondaryBrush}" Margin="0,0,0,8"/>
                        <StackPanel Orientation="Horizontal" Margin="0,0,0,6"><Ellipse Width="6" Height="6" Fill="{DynamicResource AccentBrush}" VerticalAlignment="Center" Margin="0,0,8,0"/><TextBlock Text="[Feature 1] - [Detail]" FontSize="12" Foreground="{DynamicResource TextBodyBrush}" TextWrapping="Wrap"/></StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="0,0,0,6"><Ellipse Width="6" Height="6" Fill="{DynamicResource AccentBrush}" VerticalAlignment="Center" Margin="0,0,8,0"/><TextBlock Text="Tailwind Slate - 19 canonical styles, dark/light toggle" FontSize="12" Foreground="{DynamicResource TextBodyBrush}" TextWrapping="Wrap"/></StackPanel>
                        <StackPanel Orientation="Horizontal"><Ellipse Width="6" Height="6" Fill="{DynamicResource AccentBrush}" VerticalAlignment="Center" Margin="0,0,8,0"/><TextBlock Text="Enterprise patterns - Guard-Action, Add-LogLine, toasts, settings persistence" FontSize="12" Foreground="{DynamicResource TextBodyBrush}" TextWrapping="Wrap"/></StackPanel>
                    </StackPanel>
                </Border>

                <Border Background="{DynamicResource TableAltBg}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="10" Padding="12" Margin="0,0,0,10">
                    <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <TextBlock Text="Requirements" FontSize="11" FontWeight="Bold" Foreground="{DynamicResource TextSecondaryBrush}" Margin="0,0,0,4"/>
                            <TextBlock Text="Windows 10/11  |  PS 5.1+  |  Standard user" FontSize="12" Foreground="{DynamicResource TextBodyBrush}" TextWrapping="Wrap"/>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Margin="12,0,0,0">
                            <TextBlock Text="Author" FontSize="11" FontWeight="Bold" Foreground="{DynamicResource TextSecondaryBrush}" Margin="0,0,0,4"/>
                            <StackPanel Orientation="Horizontal"><Path Stretch="Uniform" Width="12" Height="12" Fill="{DynamicResource AccentBrush}" Data="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" VerticalAlignment="Center"/><TextBlock Text="[Author] - (c) 2026" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimaryBrush}" Margin="6,0,0,0" VerticalAlignment="Center"/></StackPanel>
                        </StackPanel>
                    </Grid>
                </Border>

                <Border Background="#FFF7ED" BorderBrush="#FDBA74" BorderThickness="1" CornerRadius="10" Padding="12">
                    <TextBlock Text="Provided as-is with no warranty. Test in staging before production. Authors assume no liability for damage or data loss." FontSize="11" Foreground="#7C2D12" TextWrapping="Wrap"/>
                </Border>
            </StackPanel>
        </ScrollViewer>
        <Border Grid.Row="2" Background="{DynamicResource SurfaceBrush}" BorderBrush="{DynamicResource SeparatorBg}" BorderThickness="0,1,0,0" Padding="14,10"><Button x:Name="aboutOkBtn" HorizontalAlignment="Right" Background="{DynamicResource BtnPrimaryBg}" Foreground="White" BorderThickness="0" Cursor="Hand" Padding="22,7" FontSize="13" FontWeight="SemiBold" Content="OK"/></Border>
    </Grid>
</Window>
"@
    $win=ConvertTo-XamlWindow -Xaml $x; Copy-ThemeResources -Source $script:Window -Target $win; $script:AboutWindow=$win; $win.FindName('aboutOkBtn').Add_Click({$script:AboutWindow.Close()}) | Out-Null; return $win
}

function Show-AboutDialog {
    [CmdletBinding()]
    param()
    $win = New-AboutWindow
    if (-not $win) {
        Add-LogLine 'About window failed to build' 'ERROR'
        return
    }
    $win.Owner = $script:Window
    $null = $win.ShowDialog()
}

# ============================================================================
# STATE + GUARDS (canonical: scripts/Guard-Action.ps1)
# ============================================================================

$script:isBusy = $false

# Busy guard - returns $false when an operation is already running (Pattern H).
function Guard-Action {
    [CmdletBinding()]
    param([string]$ActionName)
    if ($script:isBusy) {
        Add-LogLine -Message "Operation in progress - please wait: $ActionName" -Level 'WARNING'
        return $false
    }
    $script:isBusy = $true
    return $true
}

function Release-Action { $script:isBusy = $false } # Clears the busy flag (finally-block partner of Guard-Action).

# Runs a scriptblock on the UI dispatcher thread; cross-thread safe, logs failures.
function Invoke-SafeUIAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [string]$ActionName = 'Unknown'
    )
    try {
        if ($script:Window -and $script:Window.Dispatcher.CheckAccess()) { & $Action }
        else { $null = $script:Window.Dispatcher.Invoke([Action]{ & $Action }) }
    }
    catch { Add-LogLine "$ActionName failed: $($_.Exception.Message)" 'ERROR' }
}

# Converts bytes to a human-readable size string ('1.46 KB').
function Format-FileSize {
    [CmdletBinding()]
    param([long]$Bytes)
    if ($Bytes -lt 1KB) { return '{0} B' -f $Bytes }
    if ($Bytes -lt 1MB) { return '{0:N2} KB' -f ($Bytes / 1KB) }
    return '{0:N2} MB' -f ($Bytes / 1MB)
}

# ============================================================================
# UI HELPERS (Patterns I + L + K)
# ============================================================================

# Central busy/idle switch: disables controls, toggles progress bar.
function Set-UIState {
    [CmdletBinding()]
    param([bool]$IsProcessing)
    # TODO: add your action buttons to the disable list below
    if ($script:ProgressBar) {
        $script:ProgressBar.IsIndeterminate = $IsProcessing
        if (-not $IsProcessing) { $script:ProgressBar.Value = 0 }
    }
}

# PSWrap-exact toast: slide-in colored card with SVG icon, 3s auto-dismiss fade-out.
function Show-ToastMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Success', 'Error', 'Warning', 'Info')][string]$Type = 'Info'
    )
    if (-not $script:ToastContainer) { return }

    $bg = switch ($Type) {
        'Success' { '#10B981' } 'Error' { '#EF4444' }
        'Warning' { '#F59E0B' } default { '#3B82F6' }
    }
    $icon = switch ($Type) {
        'Success' { 'M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z' }
        'Error'   { 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z' }
        'Warning' { 'M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z' }
        default   { 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z' }
    }

    Invoke-SafeUIAction -ActionName "Toast ($Type)" -Action {
        $border = New-Object System.Windows.Controls.Border
        $border.Background = New-Brush -Hex $bg
        $border.CornerRadius = [System.Windows.CornerRadius]::new(8)
        $border.Padding = [System.Windows.Thickness]::new(14, 10, 14, 10)
        $border.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
        $border.Opacity = 0
        $border.HorizontalAlignment = 'Right'

        $stack = New-Object System.Windows.Controls.StackPanel
        $stack.Orientation = 'Horizontal'
        $path = New-Object System.Windows.Shapes.Path
        $path.Data = [System.Windows.Media.Geometry]::Parse($icon)
        $path.Fill = [System.Windows.Media.Brushes]::White
        $path.Width = 16; $path.Height = 16
        $path.Stretch = 'Uniform'
        $path.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
        $path.VerticalAlignment = 'Center'
        $text = New-Object System.Windows.Controls.TextBlock
        $text.Text = $Message
        $text.Foreground = [System.Windows.Media.Brushes]::White
        $text.FontSize = 12
        $text.FontWeight = [System.Windows.FontWeights]::SemiBold
        $text.VerticalAlignment = 'Center'
        $null = $stack.Children.Add($path)
        $null = $stack.Children.Add($text)
        $border.Child = $stack
        $null = $script:ToastContainer.Children.Add($border)

        # Fade in (200ms).
        $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fadeIn.From = 0; $fadeIn.To = 1
        $fadeIn.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(200))
        $border.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeIn)

        # Auto-dismiss after 3s: fade out (300ms), then remove via one-shot timer.
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(3)
        $timer.Tag = $border
        $timer.Add_Tick({
            # $this = firing timer (handlers cannot see locals); border rides in .Tag.
            $t = $this
            $t.Stop()
            $b = $t.Tag
            if (-not $b) { return }
            $fadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation
            $fadeOut.From = 1; $fadeOut.To = 0
            $fadeOut.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(300))
            $b.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeOut)
            $remover = New-Object System.Windows.Threading.DispatcherTimer
            $remover.Interval = [TimeSpan]::FromMilliseconds(350)
            $remover.Tag = $b
            $remover.Add_Tick({
                $r = $this
                $r.Stop()
                if ($r.Tag) { $null = $script:ToastContainer.Children.Remove($r.Tag) }
            })
            $remover.Start()
        })
        $timer.Start()
    }
}

# Applies PSWrap nav states: active tab gets AccentTint bg + AccentHover fg + Bold;
# every other nav button goes Transparent + TextSecondary + SemiBold; pages toggle.
function Set-ActivePage {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][ValidateSet('Dashboard')][string]$TabName)

    $activeBg   = $script:Window.TryFindResource('AccentTintBrush')
    $activeFg   = $script:Window.TryFindResource('AccentHoverBrush')
    $inactiveFg = $script:Window.TryFindResource('TextSecondaryBrush')
    $inactiveBg = [System.Windows.Media.Brushes]::Transparent

    if ($script:NavBtnDashboard) {
        if ($TabName -eq 'Dashboard') {
            $script:NavBtnDashboard.Background = $activeBg
            $script:NavBtnDashboard.Foreground = $activeFg
            $script:NavBtnDashboard.FontWeight = [System.Windows.FontWeights]::Bold
        }
        else {
            $script:NavBtnDashboard.Background = $inactiveBg
            $script:NavBtnDashboard.Foreground = $inactiveFg
            $script:NavBtnDashboard.FontWeight = [System.Windows.FontWeights]::SemiBold
        }
    }
    # TODO: duplicate this block per additional nav button / page pair.
    if ($script:PageDashboard) {
        $script:PageDashboard.Visibility = if ($TabName -eq 'Dashboard') { 'Visible' } else { 'Collapsed' }
    }
}

# ============================================================================
# EVENT HANDLERS (every interactive button: Guard-Action / try / finally Release)
# ============================================================================

$script:btnThemeToggle.Add_Click({
    if (-not (Guard-Action 'Theme Toggle')) { return }
    try {
        $script:isDarkMode = -not $script:isDarkMode
        Set-Theme -Window $script:Window -IsDark $script:isDarkMode
        $brushConverter = New-Object System.Windows.Media.BrushConverter
        if ($script:isDarkMode) {
            $script:ThemeIcon.Data = [System.Windows.Media.Geometry]::Parse($MoonIconData)
            $script:ThemeIcon.Fill = $brushConverter.ConvertFromString('#CBD5E1')
            $script:btnThemeToggle.ToolTip = 'Switch to Light theme'
        }
        else {
            $script:ThemeIcon.Data = [System.Windows.Media.Geometry]::Parse($SunIconData)
            $script:ThemeIcon.Fill = $brushConverter.ConvertFromString('#EAB308')
            $script:btnThemeToggle.ToolTip = 'Switch to Dark theme'
        }
        Add-LogLine "Theme switched to $(if ($script:isDarkMode) { 'Dark' } else { 'Light' })" 'INFO'
    }
    catch {
        Add-LogLine "Theme toggle failed: $($_.Exception.Message)" 'ERROR'
    }
    finally {
        Release-Action
    }
}) | Out-Null

# TODO: wire additional buttons here using the identical guard pattern.
# Long operations MUST use Start-Job + DispatcherTimer (Pattern B) or an async
# runspace (Pattern C) - NEVER block the dispatcher thread.

$script:NavBtnDashboard.Add_Click({
    if (-not (Guard-Action 'Navigation')) { return }
    try { Set-ActivePage -TabName 'Dashboard' } finally { Release-Action }
}) | Out-Null

$script:AboutBtn.Add_Click({
    if (-not (Guard-Action 'About')) { return }
    try { Show-AboutDialog } finally { Release-Action }
}) | Out-Null

$script:LogsBtn.Add_Click({
    if (-not (Guard-Action 'Logs')) { return }
    try {
        Add-LogLine 'Activity Log opened' 'DEBUG'
        Show-LogViewer
    }
    finally { Release-Action }
}) | Out-Null

# Initialize PSWrap nav state: Dashboard active, everything else transparent.
Set-ActivePage -TabName 'Dashboard'

# ============================================================================
# WINDOW LIFECYCLE (clock timer + exactly ONE closing handler)
# ============================================================================

$script:clockTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:clockTimer.Interval = [TimeSpan]::FromSeconds(1)
$script:clockTimer.Add_Tick({
    if ($script:StatusTime) {
        $script:StatusTime.Dispatcher.Invoke([Action]{
            $script:StatusTime.Text = (Get-Date -Format 'HH:mm:ss')
        })
    }
}) | Out-Null
$script:clockTimer.Start()

$script:Window.Add_Loaded({
    $machine = $env:COMPUTERNAME
    $user    = $env:USERNAME
    if ($script:Window.FindName('SessionMachineTxt')) { $script:Window.FindName('SessionMachineTxt').Text = $machine }
    if ($script:Window.FindName('SessionUserTxt'))    { $script:Window.FindName('SessionUserTxt').Text    = $user }
    Add-LogLine "[ToolName] started$(if ($TryMode) { ' in TryMode' })" 'INFO'
}) | Out-Null

$script:Window.Add_Closing({
    Add-LogLine 'Closing - cleaning up background resources' 'INFO'
    if ($script:clockTimer) { $script:clockTimer.IsEnabled = $false }
    Save-UserSettings -Settings @{ Theme = $(if ($script:isDarkMode) { 'Dark' } else { 'Light' }) }
    # TODO: stop/remove background jobs and runspaces here (Pattern B/C cleanup).
})

[void]$script:Window.ShowDialog()

