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
<SolidColorBrush x:Key="BlockBgColor" Color="#F0F9FF"/>
<SolidColorBrush x:Key="BlockFgColor" Color="#1E40AF"/>
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

This block lives in `Set-Theme -Window $script:Window -IsDark $true` in `WpfHelpers.ps1`. Every key from the light-mode seed block is overridden:

```powershell
$resources = $Window.Resources
$resources['BackgroundBrush']    = New-Brush '#1E293B'
$resources['SurfaceBrush']       = New-Brush '#334155'
$resources['SurfaceHoverBrush']  = New-Brush '#475569'
$resources['SidebarBrush']       = New-Brush '#475569'
$resources['BorderBrush']        = New-Brush '#475569'
$resources['BorderHoverBrush']   = New-Brush '#60A5FA'
$resources['TextPrimaryBrush']   = New-Brush '#FFFFFF'
$resources['TextSecondaryBrush'] = New-Brush '#CBD5E1'
$resources['TextMutedBrush']     = New-Brush '#94A3B8'
$resources['TextBodyBrush']      = New-Brush '#E2E8F0'
$resources['AccentBrush']        = New-Brush '#60A5FA'
$resources['AccentHoverBrush']   = New-Brush '#93C5FD'
$resources['AccentTintBrush']    = New-Brush '#1E3A5F'
$resources['SuccessBrush']       = New-Brush '#10B981'
$resources['DangerBrush']        = New-Brush '#EF4444'
$resources['BtnPrimaryBg']       = New-Brush '#5B7CF5'
$resources['BtnBlueBg']          = New-Brush '#4A78E8'
$resources['BtnGreenBg']         = New-Brush '#2EA76E'
$resources['BtnRedBg']           = New-Brush '#D9534F'
$resources['BtnPurpleBg']        = New-Brush '#9560D8'
$resources['BtnGhostFg']         = New-Brush '#A0A1A6'
$resources['BtnGhostHoverBg']    = New-Brush '#232536'
$resources['CodeBg']             = New-Brush '#1E3A5F'
$resources['CodeFg']             = New-Brush '#93C5FD'
$resources['CodeBlockBg']        = New-Brush '#0F172A'
$resources['CodeBlockFg']        = New-Brush '#E2E8F0'
$resources['TableBg']            = New-Brush '#334155'
$resources['TableHeaderBg']      = New-Brush '#475569'
$resources['TableAltBg']         = New-Brush '#3B4A5E'
$resources['TableBorder']        = New-Brush '#475569'
$resources['LinkFg']             = New-Brush '#60A5FA'
$resources['BlockBgColor']       = New-Brush '#1E3A5F'
$resources['BlockFgColor']       = New-Brush '#93C5FD'
$resources['BulletFg']           = New-Brush '#60A5FA'
$resources['IconBg']             = New-Brush '#1E3A5F'
$resources['IconFg']             = New-Brush '#60A5FA'
$resources['H4Fg']               = New-Brush '#93C5FD'
$resources['HeadingFg']          = New-Brush '#F1F5F9'
$resources['BodyFg']             = New-Brush '#E2E8F0'
$resources['SeparatorBg']        = New-Brush '#475569'
$resources['UnderlineFg']        = New-Brush '#60A5FA'
$resources['TabAccentBg']        = New-Brush '#60A5FA'
$resources['TabAccentText']      = New-Brush '#FFFFFF'
$resources['TabInactiveBg']      = New-Brush '#1E293B'
$resources['TabInactiveBorder']  = New-Brush '#475569'
$resources['TabInactiveText']    = New-Brush '#94A3B8'
$resources['TabHoverBg']         = New-Brush '#334155'
$Window.Background = New-Brush '#1E293B'
```

`Set-Theme -IsDark $false` restores every value to its light-mode seed. Always pair the two functions so toggling is symmetric.

---

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