# Icons — Canonical SVG Path Data for Enterprise Tools

Every icon in every tool is an SVG `<Path>` element. Never use Segoe Fluent Icons / symbol fonts — they don't exist on Windows Server by default and look wrong in dark mode.

---

## How Icons Work

In XAML:

```xml
<Path x:Name="ThemeIcon" Data="M12 7c-2.76 0-5 2.24-5 5..."
      Fill="#EAB308" Width="14" Height="14" Stretch="Uniform"/>
```

In PowerShell (to swap icons at runtime):

```powershell
$script:ThemeIcon.Data = [System.Windows.Media.Geometry]::Parse($MoonIconData)
$script:ThemeIcon.Fill = (New-Object System.Windows.Media.BrushConverter).ConvertFromString('#CBD5E1')
```

---

## Standard Icon Set

These icons cover 90% of admin tool needs. Copy the path data as-is into a `$svg` variable or directly into XAML.

### Theme & System

#### Sun (Light Theme Indicator)

```xml
M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41L5.99 4.58zm12.37 12.37c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0 .39-.39.39-1.03 0-1.41l-1.06-1.06zm1.06-10.96c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06zM7.05 18.36c-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06z
```

Fill: `#EAB308` (yellow)

#### Moon (Dark Theme Indicator)

```xml
M9 2c-1.05 0-2.05.16-3 .46 4.06 1.27 7 5.06 7 9.54 0 4.48-2.94 8.27-7 9.54.95.3 1.95.46 3 .46 5.52 0 10-4.48 10-10S14.52 2 9 2z
```

Fill: `#CBD5E1` (muted slate)

#### Settings (Gear)

```xml
M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z
```

Fill: `{DynamicResource TextSecondaryBrush}`

#### Info (About)

```xml
M11 7h2v2h-2zm0 4h2v6h-2zm1-9C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z
```

Fill: `{DynamicResource TextSecondaryBrush}`

#### Logs / List

```xml
M3 13h2v-2H3v2zm0 4h2v-2H3v2zm0-8h2V7H3v2zm4 4h14v-2H7v2zm0-4h14V7H7v2zM7 7v2h14V7H7z
```

Fill: `{DynamicResource TextSecondaryBrush}`

### Action Icons

#### Power Off

```xml
M13 3h-2v10h2V3zm4.83 2.17l-1.42 1.42C17.99 7.86 19 9.81 19 12c0 3.87-3.13 7-7 7s-7-3.13-7-7c0-2.19 1.01-4.14 2.58-5.42L6.17 5.17C4.23 6.82 3 9.26 3 12c0 4.97 4.03 9 9 9s9-4.03 9-9c0-2.74-1.23-5.18-3.17-6.83z
```

#### Refresh / Sync

```xml
M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z
```

#### Search

```xml
M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z
```

#### Add (Plus)

```xml
M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z
```

#### Delete (Trash)

```xml
M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z
```

#### Folder

```xml
M10 4H4c-1.11 0-2 .89-2 2v12c0 1.1.89 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.11-.9-2-2-2h-8l-2-2z
```

#### File

```xml
M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z
```

#### Save / Download

```xml
M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z
```

#### Play / Start

```xml
M8 5v14l11-7z
```

#### Stop

```xml
M6 6h12v12H6z
```

### Status Icons

#### Check (Success)

```xml
M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z
```

Fill: `{DynamicResource SuccessBrush}` (`#10B981`)

#### Warning Triangle

```xml
M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z
```

Fill: `{DynamicResource WarningBrush}` (`#F59E0B`)

#### Error (X Circle)

```xml
M12 2C6.47 2 2 6.47 2 12s4.47 10 10 10 10-4.47 10-10S17.53 2 12 2zm5 13.59L15.59 17 12 13.41 8.41 17 7 15.59 10.59 12 7 8.41 8.41 7 12 10.59 15.59 7 17 8.41 13.41 12 17 15.59z
```

Fill: `{DynamicResource DangerBrush}` (`#EF4444`)

### Network / Computer Icons

#### Computer

```xml
M20 18c1.1 0 1.99-.9 1.99-2L22 6c0-1.1-.9-2-2-2H4c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2H1c-.55 0-1 .45-1 1s.45 1 1 1h22c.55 0 1-.45 1-1s-.45-1-1-1h-3zM5 6h14c.55 0 1 .45 1 1v8c0 .55-.45 1-1 1H5c-.55 0-1-.45-1-1V7c0-.55.45-1 1-1z
```

#### Server

```xml
M20 13H4c-.55 0-1 .45-1 1v6c0 .55.45 1 1 1h16c.55 0 1-.45 1-1v-6c0-.55-.45-1-1-1zM7 19c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zM20 3H4c-.55 0-1 .45-1 1v6c0 .55.45 1 1 1h16c.55 0 1-.45 1-1V4c0-.55-.45-1-1-1zM7 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2z
```

### Identity / User Icons

#### User (Account)

```xml
M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z
```

Fill: `{DynamicResource TextSecondaryBrush}`

#### Users / Group

```xml
M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z
```

Fill: `{DynamicResource TextSecondaryBrush}`

---

## Icon Size Reference

| Context | Width / Height | Stretch |
|---------|----------------|---------|
| Toolbar buttons (header) | 14 x 14 | Uniform |
| Primary CTA buttons | 16 x 16 | Uniform |
| Sidebar nav buttons | 18 x 18 | Uniform |
| Status indicators | 8 x 8 | Uniform |
| App logo / icon | 40 x 40 | Uniform |

---

## Storing Icons in PowerShell

Store the icon SVG data as variables at the top of your `.ps1` file:

```powershell
# In WpfHelpers.ps1 — top of file
$SunIconData       = 'M12 7c-2.76 0-5 2.24-5 5s...'
$MoonIconData      = 'M9 2c-1.05 0-2.05.16-3 .46...'
$SettingsIconData  = 'M19.14 12.94c.04-.3.06-.61...'
$InfoIconData      = 'M11 7h2v2h-2zm0 4h2v6h-2zm1-9C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z...'
# ... etc
```

Swap icons at runtime:

```powershell
$script:ThemeIcon.Data = [System.Windows.Media.Geometry]::Parse($MoonIconData)
```

---

## Adding New Icons

Need an icon that isn't in this set?

1. Search for an SVG path at [heroicons.com](https://heroicons.com/) or [material-icons](https://fonts.google.com/icons) — both are MIT-licensed and use 24x24 viewboxes
2. Copy the `d="..."` attribute content (the path data)
3. Test in your tool — `<Path Data="..."/>`
4. Add the variable to this file for future reuse

**Never** copy a Font Awesome / Segoe Fluent Icon as a glyph character. They don't render on Windows Server without the font installed.
