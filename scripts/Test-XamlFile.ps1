<#
.TITLE
    Test-XamlFile

.SYNOPSIS
    Canonical dual-parser WPF XAML validation helper.

.DESCRIPTION
    Validates WPF XAML files or here-strings using both XamlReader.Parse() (for syntax/XML/ampersand errors)
    and XmlNodeReader + XamlReader.Load() (for StaticResource key binding errors).

.TAGS
    Validation,XAML,WPF

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

.PARAMETER PassThru
    If specified, returns detailed validation result hashtable instead of boolean.

.PARAMETER Content
    Raw XAML string to test (for in-memory Tier 1 here-strings).

.PARAMETER Path
    Path to the XAML file to test.

.EXAMPLE
    Test-XamlFile -Content $xaml

.EXAMPLE
    Test-XamlFile -Path 'MainWindow.xaml'
.NOTES
    - XAML validator — tests both XamlReader.Parse and XmlNodeReader+Load per pitfalls.md.

#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
function Test-XamlFile {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Path', Position = 0)]
        [string]$Path,
        [Parameter(Mandatory = $true, ParameterSetName = 'Content')]
        [string]$Content,
        [switch]$PassThru
    )

    # Ensure WPF Assemblies are loaded
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction SilentlyContinue

    $rawXaml = if ($PSCmdlet.ParameterSetName -eq 'Path') {
        if (-not (Test-Path -Path $Path)) {
            throw "XAML file not found: $Path"
        }
        Get-Content -Path $Path -Raw -Encoding UTF8
    } else {
        $Content
    }

    $result = @{
        SyntaxParseOk    = $false
        ResourceLoadOk   = $false
        IsValid          = $false
        ErrorMessage     = $null
    }

    # Method 1: Catches syntax errors (Ampersand Law, malformed markup)
    try {
        $null = [System.Windows.Markup.XamlReader]::Parse($rawXaml)
        $result.SyntaxParseOk = $true
    }
    catch {
        $result.ErrorMessage = "XamlReader.Parse failed: $($_.Exception.Message)"
        if ($PassThru) { return [PSCustomObject]$result }
        Write-Error $result.ErrorMessage
        return $false
    }

    # Method 2: Catches runtime resource binding issues (StaticResource Law)
    $xmlReader = $null
    try {
        $xml = [xml]$rawXaml
        $xmlReader = New-Object System.Xml.XmlNodeReader($xml)
        $null = [System.Windows.Markup.XamlReader]::Load($xmlReader)
        $result.ResourceLoadOk = $true
        $result.IsValid = $true
    }
    catch {
        $result.ErrorMessage = "XamlReader.Load failed: $($_.Exception.Message)"
        if ($PassThru) { return [PSCustomObject]$result }
        Write-Error $result.ErrorMessage
        return $false
    }
    finally {
        if ($xmlReader) {
            $xmlReader.Close()
        }
    }

    if ($PassThru) {
        return [PSCustomObject]$result
    }
    return $true
}