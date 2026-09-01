<#
.TITLE
    ConvertTo-SafeDateTime

.SYNOPSIS
    Canonical culture-safe multi-format date parser.

.DESCRIPTION
    Parses dates from CSV exports, Windows Event logs, and Microsoft Graph API responses
    across cultures without throwing exceptions. Tries standard ISO-8601, round-trip, and regional formats.

.TAGS
    Dates,CultureSafe,Parsing

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

.PARAMETER Formats
    Array of custom format strings to attempt before falling back.

.PARAMETER Value
    The date string to parse.

.EXAMPLE
    ConvertTo-SafeDateTime -Value '2026-08-20T10:56:00.1234567Z'
.NOTES
    - Culture-safe date conversion; handles en-US vs non-US locales.

#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
function ConvertTo-SafeDateTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value,
        [string[]]$Formats = @(
            'yyyy-MM-ddTHH:mm:ss.fffffffZ',
            'yyyy-MM-ddTHH:mm:ss.ffffffZ',
            'yyyy-MM-ddTHH:mm:ss.fffZ',
            'yyyy-MM-ddTHH:mm:ssZ',
            'yyyy-MM-ddTHH:mm:sszzz',
            'yyyy-MM-ddTHH:mm:ssK',
            'yyyy-MM-ddTHH:mm:ss',
            'yyyy-MM-dd HH:mm:ss',
            'yyyy-MM-dd',
            'MM/dd/yyyy HH:mm:ss',
            'MM/dd/yyyy HH:mm',
            'MM/dd/yyyy',
            'M/d/yyyy',
            'o',
            's'
        )
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $null
        }

        $parsed = [datetime]::MinValue
        foreach ($format in $Formats) {
            if ([datetime]::TryParseExact($Value, $format, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$parsed)) {
                return $parsed
            }
        }

        # General invariant fallback
        $fallback = [datetime]::MinValue
        if ([datetime]::TryParse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal, [ref]$fallback)) {
            return $fallback
        }

        return $null
    }
}