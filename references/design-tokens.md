# Design Tokens — Tailwind Slate (Enterprise Standard)

Every color, spacing value, font, and shadow in every tool comes from a token. Hardcoding a hex value anywhere except in this file (or its dark-mode override) breaks the design language.

---

## Table of Contents

1. [How tokens work](#how-tokens-work)
2. [Light Mode Brush Definitions](#light-mode-brush-def)
3. [Dark Mode Overrides](#dark-mode-overrides)
4. [Spacing Rules](#spacing-rules)
5. [Typography Scale](#typography-scale)
6. [Icon Sizes](#icon-sizes)

---

## How tokens work

Tokens are `SolidColorBrush` resources defined in `Window.Resources` of `MainWindow.xaml`. UI elements reference them via `{DynamicResource TokenName}`:

```xml
<Border Background="{DynamicResource SurfaceBrush}"
        BorderBrush="{DynamicResource BorderBrush}"
        CornerRadius="12">
```

When the user clicks the theme toggle button, `Set-Theme` (defined in `WpfHelpers.ps1`) replaces the brush instances in `Window.Resources` with dark-mode values. Every element using `{DynamicResource}` updates automatically because the resource key still resolves — only the brush instance changed.

**Why `DynamicResource` not `StaticResource`:** `StaticResource` resolves once at parse time. `DynamicResource` resolves at lookup time. Theme toggle works because the lookup happens at render time.

---

## Light Mode Brush Definitions

Copy this block verbatim into every `MainWindow.xaml` inside `<Window.Resources>`:

```xml
<!-- Core surface -->
<SolidColorBrush x:Key="BackgroundBrush" Color="#F1F5F9"/>
<SolidColorBrush x:Key="SurfaceBrush" Color="#FFFFFF"/>
<SolidColorBrush x:Key="SurfaceHoverBrush" Color="#F1F5F9"/>
<SolidColorBrush x:Key="SidebarBrush" Color="#E8EDF4"/>

<!-- Accent / status -->
<SolidColorBrush x:Key="AccentBrush" Color="#3B82F6"/>
<SolidColorBrush x:Key="AccentHoverBrush" Color="#1D4ED8"/>
<SolidColorBrush x:Key="AccentTintBrush" Color="#EFF6FF"/>
<SolidColorBrush x:Key="SuccessBrush" Color="#10B981"/>
<SolidColorBrush x:Key="DangerBrush" Color="#EF4444"/>
<SolidColorBrush x:Key="WarningBrush" Color="#F59E0B"/>

<!-- Text -->
<SolidColorBrush x:Key="TextPrimaryBrush" Color="#0F172A"/>
<SolidColorBrush x:Key="TextSecondaryBrush" Color="#64748B"/>
<SolidColorBrush x:Key="TextMutedBrush" Color="#94A3B8"/>
<SolidColorBrush x:Key="TextBodyBrush" Color="#334155"/>

<!-- Borders -->
<SolidColorBrush x:Key="BorderBrush" Color="#E2E8F0"/>
<SolidColorBrush x:Key="BorderHoverBrush" Color="#93C5FD"/>
<SolidColorBrush x:Key="SeparatorBg" Color="#E2E8F0"/>

<!-- Buttons -->
<SolidColorBrush x:Key="BtnPrimaryBg" Color="#4F46E5"/>
<SolidColorBrush x:Key="BtnBlueBg" Color="#3B82F6"/>
<SolidColorBrush x:Key="BtnGreenBg" Color="#10B981"/>
<SolidColorBrush x:Key="BtnRedBg" Color="#EF4444"/>
<SolidColorBrush x:Key="BtnPurpleBg" Color="#A855F7"/>
<SolidColorBrush x:Key="BtnGhostFg" Color="#64748B"/>
<SolidColorBrush x:Key="BtnGhostHoverBg" Color="#F1F5F9"/>

<!-- Code / Table / Tab -->
<SolidColorBrush x:Key="CodeBg" Color="#EFF6FF"/>
<SolidColorBrush x:Key="CodeFg" Color="#1D4ED8"/>
<SolidColorBrush x:Key="CodeBlockBg" Color="#1E293B"/>
<SolidColorBrush x:Key="CodeBlockFg" Color="#E2E8F0"/>
<SolidColorBrush x:Key="TableBg" Color="#FFFFFF"/>
<SolidColorBrush x:Key="TableHeaderBg" Color="#F1F5F9"/>
<SolidColorBrush x:Key="TableAltBg" Color="#F8FAFC"/>
<SolidColorBrush x:Key="TableBorder" Color="#E2E8F0"/>
<SolidColorBrush x:Key="TabAccentBg" Color="#3B82F6"/>
<SolidColorBrush x:Key="TabAccentText" Color="#FFFFFF"/>
<SolidColorBrush x:Key="TabInactiveBg" Color="#F8FAFC"/>
<SolidColorBrush x:Key="TabInactiveBorder" Color="#E2E8F0"/>
<SolidColorBrush x:Key="TabInactiveText" Color="#64748B"/>
<SolidColorBrush x:Key="TabHoverBg" Color="#F1F5F9"/>

<!-- Markdown rendering (used in AboutInfo) -->
<SolidColorBrush x:Key="LinkFg" Color="#3B82F6"/>
<SolidColorBrush x:Key="BlockquoteBg" Color="#F0F9FF"/>
<SolidColorBrush x:Key="BlockquoteFg" Color="#1E40AF"/>
<SolidColorBrush x:Key="BulletFg" Color="#3B82F6"/>
<SolidColorBrush x:Key="IconBg" Color="#DBEAFE"/>
<SolidColorBrush x:Key="IconFg" Color="#1D4ED8"/>
<SolidColorBrush x:Key="H4Fg" Color="#1D4ED8"/>
<SolidColorBrush x:Key="HeadingFg" Color="#0F172A"/>
<SolidColorBrush x:Key="BodyFg" Color="#334155"/>
<SolidColorBrush x:Key="UnderlineFg" Color="#3B82F6"/>
```

---

## Dark Mode Overrides

This block lives in `Set-Theme -Window $script:Window -IsDark $true` (Pattern A - Theme Toggle). Every key from the light-mode seed block is overridden:

```powershell
# Remove + Add (NOT indexer assignment) — indexer assignment on a XamlReader-built
# Resources dictionary corrupts deferred DynamicResource references. See references/pitfalls.md
# "Pitfall: Indexer Assignment on XamlReader-Built ResourceDictionary" for the empirical failure mode.
foreach ($key in $tokens.Keys) {
    if ($Window.Resources.Contains($key)) { $null = $Window.Resources.Remove($key) }
    $null = $Window.Resources.Add($key, (New-Brush -Hex $tokens[$key]))
}
$Window.Background = New-Brush -Hex $tokens['BackgroundBrush']
```

Then `Set-Theme` is called with the dark-mode token hashtable:

```powershell
$darkTokens = @{
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
    LinkFg             = '#60A5FA'
    BlockquoteBg       = '#1E3A5F'; BlockquoteFg     = '#93C5FD'
    BulletFg           = '#60A5FA'; IconBg           = '#1E3A5F'; IconFg  = '#60A5FA'
    H4Fg               = '#93C5FD'; HeadingFg        = '#F1F5F9'; BodyFg  = '#E2E8F0'
    UnderlineFg        = '#60A5FA'
    TabAccentBg        = '#60A5FA'; TabAccentText    = '#FFFFFF'
    TabInactiveBg      = '#1E293B'; TabInactiveBorder = '#475569'; TabInactiveText = '#94A3B8'
    TabHoverBg         = '#334155'
}
Set-Theme -Window $Window -IsDark $true   # uses $darkTokens internally
```

`Set-Theme -IsDark $false` restores every value to its light-mode seed. Always pair the two functions so toggling is symmetric. The canonical implementation lives in `templates/wpf-gui-tool.template.ps1` (function `Set-Theme` using `Remove + Add`) — copy that pattern, do not retype from the snippet above.
## Spacing Rules

These are **non-negotiable values** — every tool uses them:

| Element | Value |
|---------|-------|
| Window `WindowStyle` | `SingleBorderWindow` |
| Window `ResizeMode` | `CanResizeWithGrip` |
| Content area margin | `Margin="24,8,24,8"` |
| Card padding | `Padding="18"` or `Padding="18,16"` (StatCard) |
| Card margin | `Margin="0,0,0,12"` |
| Grid row gap | `Margin="0,0,0,6"` |
| Button `CornerRadius` | `8` |
| Card `CornerRadius` | `14` |
| Nav item `CornerRadius` | `10` |
| Button height (standard) | `38` |
| Button height (compact) | `34` |
| Button `MinWidth` | `100` |
| StatusBar padding | `Padding="16,6,20,6"` |
| Drop shadow (cards) | `BlurRadius="24" ShadowDepth="6" Color="#0F172A" Opacity="0.045"` |
| Drop shadow (stat cards) | `BlurRadius="12" ShadowDepth="3" Color="#0F172A" Opacity="0.04"` |

**Never use borderless windows** (`WindowStyle="None"`). The user must be able to resize, minimize, and snap the window to screen edges.

---

## Typography Scale

Use `Segoe UI Variable Display, Segoe UI` as `FontFamily` so the Segoe UI Variable font is used where available and falls back gracefully on older systems.

| Role | Size | Weight | Use |
|------|------|--------|-----|
| Display Large | 28 | ExtraBold | Hero titles (rare) |
| Display Medium | 24 | ExtraBold | Page H1 |
| Heading | 17 | Bold | Card titles |
| Subheading | 14 | Bold | Nav labels, trend lines |
| Body | 13 | SemiBold | Default body text and DataGrid rows |
| Small | 12 | SemiBold | KPI subtitles, footer text |
| Caption | 11 | SemiBold | Sidebar labels |
| KPI Value | 20-32 | ExtraBold | Stat card numbers |

---

## Icon Sizes

Match icon size to context:

| Context | Size |
|---------|------|
| Toolbar buttons (header) | `Width="14" Height="14"` |
| Primary CTA buttons | `Width="16" Height="16"` |
| Sidebar nav buttons | `Width="18" Height="18"` |
| StatusBar indicator dots | `Width="8" Height="8"` |

All icons are `<Path>` elements with SVG `Data="..."`. Never use Segoe Fluent Icons / symbol fonts — they don't exist on Windows Server by default.

See `references/icons.md` for the standard icon set (sun, moon, settings, power, info, etc.) with verified SVG path data.
## Extended Token Families (PSWrap parity - 2026-08-23)

Sourced from PSWrap `src/WpfHelpers.ps1`. Seeded in `wpf-gui-tool.template.ps1` LightTokens/DarkTokens; consumed by data-heavy tool styles (code blocks, tables, tabs, markdown About rendering).

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| BtnGhostHoverBg | #F1F5F9 | #232536 | Ghost button hover fill |
| LinkFg | #3B82F6 | #60A5FA | Hyperlinks, markdown links |
| CodeBg / CodeFg | #EFF6FF / #1D4ED8 | #1E3A5F / #93C5FD | Inline code chips |
| CodeBlockBg / CodeBlockFg | #1E293B / #E2E8F0 | #0F172A / #E2E8F0 | Terminal/code blocks |
| TableBg | #FFFFFF | #334155 | DataGrid background |
| TableHeaderBg | #F1F5F9 | #475569 | Grid header row |
| TableAltBg | #F8FAFC | #3B4A5E | Alternating rows |
| TableBorder | #E2E8F0 | #475569 | Grid lines |
| BlockquoteBg / BlockquoteFg | #F0F9FF / #1E40AF | #1E3A5F / #93C5FD | Markdown quotes |
| BulletFg | #3B82F6 | #60A5FA | List bullets |
| IconBg / IconFg | #DBEAFE / #1D4ED8 | #1E3A5F / #60A5FA | Icon circles/tiles |
| HeadingFg / BodyFg / H4Fg | #0F172A / #334155 / #1D4ED8 | #F1F5F9 / #E2E8F0 / #93C5FD | Markdown headings/body |
| UnderlineFg | #3B82F6 | #60A5FA | Markdown link underline |
| TabAccentBg / TabAccentText | #3B82F6 / #FFFFFF | #60A5FA / #FFFFFF | Active tab |
| TabInactiveBg / TabInactiveBorder / TabInactiveText | #F8FAFC / #E2E8F0 / #64748B | #1E293B / #475569 / #94A3B8 | Inactive tab |
| TabHoverBg | #F1F5F9 | #334155 | Tab hover |

Also adopted from PSWrap: `Invoke-SafeUIAction` (dispatcher-safe scriptblock runner) and `Format-FileSize` now ship in wpf-gui-tool.template.ps1.
