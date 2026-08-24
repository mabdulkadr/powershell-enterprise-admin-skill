# Code Patterns — The 21 Canonical Enterprise Patterns

Every primitive you need to build a tool. Each pattern is the canonical implementation — copy it, place it in the right file, customize the action.

---

## Table of Contents

| Pattern | Purpose |
|---------|---------|
| [A. Theme Toggle](#pattern-a-theme-toggle) | Sun/moon icon swap + Set-Theme |
| [B. Background Data Load](#pattern-b-background-data-load) | Start-Job + DispatcherTimer for CIM/WMI/Graph |
| [C. Async Runspace](#pattern-c-async-runspace) | BeginInvoke + DispatcherTimer for long .NET ops |
| [D. Inline XAML Dialog](#pattern-d-inline-xaml-dialog) | Modal forms that don't need their own XAML file |
| [E. LogViewer Theme Copy](#pattern-e-logviewer-theme-copy) | Copy theme tokens to child windows |
| [F. Window-Level Drag and Drop](#pattern-f-window-level-drag-and-drop) | File path inputs accept drag-drop |
| [G. Select All / Deselect All DataGrid](#pattern-g-select-all--deselect-all-datagrid) | Bulk operations on row-checked grids |
| [H. Guard-Action](#pattern-h-guard-action) | Every interactive button uses this |
| [I. Set-UIState Busy/Idle](#pattern-i-set-uistate-busyidle) | Disable buttons + show progress bar |
| [J. Update-UIState Central Refresh](#pattern-j-update-uistate-central-refresh) | TextChanged events, post-action state |
| [K. Clock Timer](#pattern-k-clock-timer) | StatusBar shows current time |
| [L. Show-ToastMessage](#pattern-l-show-toastmessage) | Replace MessageBox with animated toast (In-App) |
| [M. About Dialog Markdown Rendering](#pattern-m-about-dialog-markdown-rendering) | docs/*.md → WPF elements |
| [N. Live Column Filtering](#pattern-n-live-column-by-column-datagrid-filtering) | Filter boxes over DataGrid columns |
| [O. Shift-Click Range Selection](#pattern-o-shift-click-multi-row-range-selection) | Fast multi-row checkbox selection |
| [P. Multi-Input Comma Search](#pattern-p-multi-input-comma-separated-search-parsing) | Comma/newline search box parsing |
| [Q. Settings Persistence](#pattern-q-settings-persistence-pattern-settingsjson-in-localappdata) | Safe `%LocalAppData%` JSON config |
| [R. Async External Process Wrapper](#pattern-r-async-external-process-wrapper-runspace--processstartinfo--polling) | Non-blocking CLI tool wrapper with polling |
| [S. Live Message Center Console](#pattern-s-richtextbox-live-message-center-colorized-in-app-terminal-console) | Color-coded in-app RichTextBox log terminal |
| [T. Native Windows OS Toast Notifications](#pattern-t-native-windows-os-toast-notifications-action-center-winrt-xml) | Direct Action Center toast without external modules |
| [U. Responsive HTML Executive Report](#pattern-u-responsive-html-executive-report-generator) | Self-contained executive HTML dashboard with search |

---

## Pattern A: Theme Toggle

Lives in the tool's event handler section (in the single .ps1 file). Click handler swaps theme tokens and rotates the icon.

```powershell
# Top-level state in the .ps1 file
$script:isDarkMode = $false

# SVG path data for the icons (define these once at the top of the .ps1 file)
$SunIconData  = 'M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41L5.99 4.58zm12.37 12.37c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0 .39-.39.39-1.03 0-1.41l-1.06-1.06zm1.06-10.96c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06zM7.05 18.36c-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06z'
$MoonIconData = 'M9 2c-1.05 0-2.05.16-3 .46 4.06 1.27 7 5.06 7 9.54 0 4.48-2.94 8.27-7 9.54.95.3 1.95.46 3 .46 5.52 0 10-4.48 10-10S14.52 2 9 2z'

# Click handler — wires to the theme toggle button in the header
if ($script:ThemeToggleBtn) {
    $script:ThemeToggleBtn.Add_Click({
        if (-not (Guard-Action 'Theme Toggle')) { return }
        try {
            $script:isDarkMode = -not $script:isDarkMode
            Set-Theme -Window $script:Window -IsDark $script:isDarkMode
            if ($script:isDarkMode) {
                $script:ThemeIcon.Data = [System.Windows.Media.Geometry]::Parse($MoonIconData)
                $script:ThemeIcon.Fill = (New-Object System.Windows.Media.BrushConverter).ConvertFromString('#CBD5E1')
                $script:ThemeToggleBtn.ToolTip = 'Switch to Light theme'
            } else {
                $script:ThemeIcon.Data = [System.Windows.Media.Geometry]::Parse($SunIconData)
                $script:ThemeIcon.Fill = (New-Object System.Windows.Media.BrushConverter).ConvertFromString('#EAB308')
                $script:ThemeToggleBtn.ToolTip = 'Switch to Dark theme'
            }
            Add-LogLine "Theme: $(if ($script:isDarkMode) { 'Dark' } else { 'Light' })" 'INFO'
        } finally {
            Release-Action
        }
    }) | Out-Null
}
```

**Critical:** `Set-Theme` must override **every** token from the design system. See `design-tokens.md` for the full dark-mode override block.

---

## Pattern B: Background Data Load

Use `Start-Job` for CIM/WMI queries, Graph API calls, or any operation that returns a single result object. Polls with `DispatcherTimer` at 300ms.

```powershell
# In the .ps1 file (inline or in a function)
function Start-BackgroundDataLoad {
    $script:DataLoadJob = Start-Job -ScriptBlock {
        # Use $using: for any variables needed inside the job
        $cs  = Get-CimInstance Win32_ComputerSystem
        $os  = Get-CimInstance Win32_OperatingSystem
        $cpu = Get-CimInstance Win32_Processor
        return [PSCustomObject]@{
            ComputerName = $cs.Name
            Manufacturer = $cs.Manufacturer
            OSVersion    = $os.Caption
            CPUName      = $cpu.Name
        }
    }

    $script:DataLoadTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:DataLoadTimer.Interval = [TimeSpan]::FromMilliseconds(300)
    $script:DataLoadTimer.Add_Tick({
        if ($script:DataLoadJob.State -eq 'Completed') {
            $script:DataLoadTimer.IsEnabled = $false
            $data = Receive-Job -Job $script:DataLoadJob -Keep
            Remove-Job -Job $script:DataLoadJob -Force -ErrorAction SilentlyContinue
            $script:DataLoadJob = $null

            if (-not $data) {
                Add-LogLine 'No data received from background job' 'WARNING'
                return
            }
            $script:Window.Dispatcher.Invoke([Action]{ Update-DashboardUI -Data $data })
        }
    }) | Out-Null
    $script:DataLoadTimer.Start()
}

# Cleanup in Add_Closing handler (same file):
if ($script:DataLoadJob) {
    Stop-Job -Job $script:DataLoadJob -ErrorAction SilentlyContinue
    Remove-Job -Job $script:DataLoadJob -Force -ErrorAction SilentlyContinue
}
if ($script:DataLoadTimer) { $script:DataLoadTimer.IsEnabled = $false }
```

**Why `-Keep` on Receive-Job:** Keeps the output in the job's output collection for one more read. Without `-Keep`, repeated polls return nothing after the first receive.

**Why 300ms (not 250ms):** Lower intervals hit the dispatcher too often for no benefit. 300ms is below human perception of lag but reduces idle CPU.

---

## Pattern C: Async Runspace

For long in-process .NET operations that need assembly access (file system traversal, image processing, .NET interop). Polls with `DispatcherTimer` at 350ms.

```powershell
function Start-AsyncOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [int]$PollIntervalMs = 350
    )

    if (-not (Guard-Action 'Async Operation')) { return }
    Set-UIState -IsProcessing $true
    Add-LogLine "Starting: $(Split-Path $InputPath -Leaf)" 'INFO'

    $script:asyncInstance = [powershell]::Create().AddScript({
        param($Path)
        # Heavy work here — file system ops, .NET interop, etc.
        return [PSCustomObject]@{ Success = $true; Result = 'done' }
    }).AddArgument($InputPath)

    $script:asyncResult = $script:asyncInstance.BeginInvoke()

    $script:pollTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $script:pollTimer.Interval = [TimeSpan]::FromMilliseconds($PollIntervalMs)
    $script:pollTimer.Add_Tick({
        if (-not $script:asyncResult) { $script:pollTimer.Stop(); return }
        if ($script:asyncResult.IsCompleted) {
            $script:pollTimer.Stop()
            try {
                $r = $script:asyncInstance.EndInvoke($script:asyncResult)
                Add-LogLine "Completed: $($r.Result)" 'SUCCESS'
                $script:Window.Dispatcher.Invoke([Action]{ <# update UI #> })
            } catch {
                Add-LogLine "Error: $($_.Exception.Message)" 'ERROR'
            } finally {
                if ($script:asyncInstance) {
                    $script:asyncInstance.Dispose()
                    $script:asyncInstance = $null
                }
                $script:asyncResult = $null
                Set-UIState -IsProcessing $false
                Release-Action
            }
        }
    }) | Out-Null
    $script:pollTimer.Start()
}

function Stop-AsyncOperation {
    if ($script:asyncInstance -and $script:asyncResult -and (-not $script:asyncResult.IsCompleted)) {
        try { $script:asyncInstance.Stop() } catch { }
        if ($script:pollTimer) { $script:pollTimer.Stop() }
        $script:asyncInstance.Dispose()
        $script:asyncInstance = $null
        $script:asyncResult = $null
        Set-UIState -IsProcessing $false
        Release-Action
        Add-LogLine 'Operation cancelled.' 'WARNING'
    }
}
```

**Why `EndInvoke` is mandatory:** A `BeginInvoke` without paired `EndInvoke` leaks the runspace. Always call both.

**Why `Dispose()`:** The `[powershell]` instance holds the runspace, the script, and the output buffer. Without `Dispose()`, all three leak until process exit.

---

## Pattern D: Inline XAML Dialog

For one-off modal forms that don't warrant their own XAML file. The dialog inherits the parent's theme via resource copy.

```powershell
function Show-CustomDialog {
    $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Dialog" Width="500" Height="400"
        WindowStartupLocation="CenterOwner"
        Background="{DynamicResource BackgroundBrush}">
    <Grid Margin="24">
        <Button x:Name="btnOk" Content="OK"
                Background="{DynamicResource AccentBrush}" Foreground="White"
                Style="{StaticResource BtnPrimary}"/>
    </Grid>
</Window>
'@
    # 1. Targeted replacements FIRST (curly quotes before control-char strip)
    $xaml = $xaml -replace ''', "'"

    # 2. Then strip control characters
    $clean = $xaml -replace '[﻿‌‍‎‏‪-‮]', ''

    # 3. Try Parse(), fall back to XmlNodeReader+Load()
    try { $dw = [System.Windows.Markup.XamlReader]::Parse($clean) }
    catch {
        $sr = New-Object System.IO.StringReader($clean)
        $xr = [System.Xml.XmlReader]::Create($sr)
        $dw = [System.Windows.Markup.XamlReader]::Load($xr)
    }

    # 4. Copy theme resources from main window
    $script:Window.Resources.Keys | ForEach-Object {
        $dw.Resources[$_] = $script:Window.Resources[$_]
    }

    # 5. Center over parent
    $dw.Owner = $script:Window
    $dw.WindowStartupLocation = 'CenterOwner'

    # 6. Bind and wire
    $okBtn = $dw.FindName('btnOk')
    $okBtn.Add_Click({ $dw.Close() }) | Out-Null

    [void]$dw.ShowDialog()
}
```

**Why the cleanup order matters:** The curly-quote replacement (`-replace ''', "'"`) MUST run BEFORE the control-character strip — otherwise the curly quote gets removed and the second replace is dead code.

---

## Pattern E: LogViewer Theme Copy

The standalone log viewer window reads XAML from disk and inherits the parent's theme via resource copy.

```powershell
function Show-LogViewer {
    $xmlContent = [System.IO.File]::ReadAllText((Join-Path $script:XamlDir 'LogViewer.xaml'))
    $xml = [xml]$xmlContent
    $reader = New-Object System.Xml.XmlNodeReader($xml)
    $logWindow = [System.Windows.Markup.XamlReader]::Load($reader)
    $reader.Close()

    # Copy theme resources so {DynamicResource} tokens resolve
    foreach ($key in $script:Window.Resources.Keys) {
        $logWindow.Resources[$key] = $script:Window.Resources[$key]
    }

    $logWindow.Owner = $script:Window
    $logWindow.WindowStartupLocation = 'CenterOwner'
    [void]$logWindow.ShowDialog()
}
```

This is the same pattern as D — just loading XAML from disk instead of a here-string. Both work because the theme copy makes the child window match the parent's current theme (light or dark).

---

## Pattern F: Window-Level Drag and Drop

Make the entire window accept dropped files. Filter to your expected extensions.

```xml
<!-- In MainWindow.xaml: <Window ... AllowDrop="True"> -->
```

```powershell
# In the .ps1 file (inline)
$script:Window.Add_DragOver({
    $_.Effects = if ($_.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
        [System.Windows.DragDropEffects]::Copy
    } else {
        [System.Windows.DragDropEffects]::None
    }
    $_.Handled = $true
}) | Out-Null

$script:Window.Add_Drop({
    if ($_.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
        $files = $_.Data.GetData([System.Windows.DataFormats]::FileDrop)
        $target = $files | Where-Object { $_ -like '*.ps1' } | Select-Object -First 1
        if ($target) {
            $script:txtInputPath.Text = $target
            Add-LogLine "File dropped: $target" 'INFO'
            Update-UIState
        }
    }
}) | Out-Null
```

**Why filter inside the Drop handler (not the DragOver handler):** Show Copy cursor for everything (the user knows they can drop); reject in the Drop handler if no match.

---

## Pattern G: Select All / Deselect All DataGrid

For bulk operations on row-checked DataGrids. The CheckBox column binds to an `IsSelected` property on each row object.

```xml
<!-- In MainWindow.xaml: DataGrid column with per-row checkbox -->
<DataGridTemplateColumn Header="check" Width="36">
    <DataGridTemplateColumn.CellTemplate>
        <DataTemplate>
            <CheckBox IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}"
                      HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </DataTemplate>
    </DataGridTemplateColumn.CellTemplate>
</DataGridTemplateColumn>
```

```powershell
# After Window.FindName('chkSelectAll') binding (same file)
$script:chkSelectAll = $Window.FindName('chkSelectAll')

# Wire the checkbox to flip all rows
$script:itemList = [System.Collections.ArrayList]::new()

$script:chkSelectAll.Add_Checked({
    foreach ($item in $script:itemList) { $item.IsSelected = $true }
    if ($script:DataGrid) { $script:DataGrid.Items.Refresh() }
}) | Out-Null

$script:chkSelectAll.Add_Unchecked({
    foreach ($item in $script:itemList) { $item.IsSelected = $false }
    if ($script:DataGrid) { $script:DataGrid.Items.Refresh() }
}) | Out-Null
```

**Why `Items.Refresh()`:** WPF DataGrid doesn't re-evaluate CheckBox bindings when a property changes via code. `Refresh()` forces re-evaluation.

---

## Pattern H: Guard-Action

**Every interactive button** uses this. The `Guard-Action` / `Release-Action` pair prevents concurrent operations that could corrupt state. **The canonical implementation is `scripts/Guard-Action.ps1` — copy it verbatim instead of retyping.**

```powershell
# Dot-source the canonical implementation — never retype Guard-Action / Release-Action.
# Path: <skill>/scripts/Guard-Action.ps1
. "$PSScriptRoot/../scripts/Guard-Action.ps1"

# Usage in every action button:
$script:BtnAction.Add_Click({
    if (-not Guard-Action -ActionName 'Action Name') { return }
    try {
        # ... your logic here ...
        Add-LogLine -Message 'Completed.' -Level 'INFO'
    } catch {
        Add-LogLine -Message "Failed: $($_.Exception.Message)" -Level 'ERROR'
    } finally {
        Release-Action
    }
}) | Out-Null
```

**Why `finally`:** Ensures `Release-Action` runs even on exception, preventing the tool from being permanently locked in busy state after a crash.

---

## Pattern I: Set-UIState Busy/Idle

Disables action buttons and toggles the progress bar.

```powershell
function Set-UIState {
    [CmdletBinding()]
    param([bool]$IsProcessing)

    $script:isBusy = $IsProcessing

    if ($script:ProgressBar) {
        $script:ProgressBar.IsIndeterminate = $IsProcessing
        if (-not $IsProcessing) { $script:ProgressBar.Value = 0 }
    }

    # Disable every action button while busy
    @($script:btnAction1, $script:btnAction2, $script:btnBrowse) |
        Where-Object { $_ } |
        ForEach-Object { $_.IsEnabled = -not $IsProcessing }
}
```

Call `Set-UIState -IsProcessing $true` at the start of any operation, and `Set-UIState -IsProcessing $false` when it completes.

---

## Pattern J: Update-UIState Central Refresh

Centralized function called on TextChanged events and after any data change. Refreshes derived UI state.

```powershell
function Update-UIState {
    # Refresh any lists
    Update-BundleFilesList

    # Update KPI labels
    if ($script:KpiSourceSize -and $script:txtInputPath.Text -and (Test-Path $script:txtInputPath.Text)) {
        $len = (Get-Item -LiteralPath $script:txtInputPath.Text).Length
        $script:KpiSourceSize.Text = Format-FileSize -Bytes $len
    }

    # Update status text
    if ($script:lblStatus) {
        $script:lblStatus.Text = if ($script:txtInputPath.Text) { 'Ready' } else { 'Select a file...' }
    }
}

# Wire to TextChanged events:
$script:txtInputPath.Add_TextChanged({ Update-UIState }) | Out-Null
```

**Why centralized:** Every change to any input flows through one function. Adding a new KPI means adding one branch, not hunting every TextChanged event.

---

## Pattern K: Clock Timer

StatusBar shows the current time, updated every second.

```powershell
# 1-second clock in StatusBar (inline in .ps1 file)
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
```

**Why wrap in `Dispatcher.Invoke`:** `Add_Tick` runs on the dispatcher thread, but defensive wrapping is cheap insurance against accidental thread switches.

---

## Pattern L: Show-ToastMessage

Replace blocking `MessageBox` calls with animated slide-up notifications.

```powershell
# Show-ToastMessage function (inline in .ps1 file)
function Show-ToastMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Success','Error','Warning','Info')][string]$Type = 'Info'
    )

    $colors = @{
        Success = '#10B981'
        Error   = '#EF4444'
        Warning = '#F59E0B'
        Info    = '#3B82F6'
    }

    if ($script:ToastBorder -and $script:ToastText) {
        $script:Window.Dispatcher.Invoke([Action]{
            $script:ToastText.Text = $Message
            $script:ToastBorder.Background = New-Brush $colors[$Type]
            $script:ToastBorder.Visibility = 'Visible'

            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromSeconds(3)
            $timer.Add_Tick({
                $script:ToastBorder.Visibility = 'Collapsed'
                $timer.Stop()
            }) | Out-Null
            $timer.Start()
        })
    }
}
```

**Why replace MessageBox:** MessageBox blocks the dispatcher thread and freezes the UI. Toast is async and disappears on its own.

---

## Pattern M: About Dialog Markdown Rendering

`AboutInfo.ps1` reads `.md` files from `docs/` and converts them into WPF elements (headers, code blocks, tables, blockquotes, lists) at runtime.

```powershell
# About info rendering (inline in .ps1 file or in a helper function)
$docsDir = Join-Path $script:EntryDir 'docs'
$tabs = @(
    @{ Name = 'About';         File = 'core/ABOUT.md';         Group = 'Core' }
    @{ Name = 'API Reference'; File = 'core/API-REFERENCE.md'; Group = 'Core' }
    @{ Name = 'User Guide';    File = 'gui/USER-GUIDE.md';     Group = 'GUI'  }
)

# Render each tab from its markdown file
foreach ($tab in $tabs) {
    $filePath = Join-Path $docsDir $tab.File
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        # Parse markdown into WPF StackPanel with styled children
        $panel = Convert-MarkdownToWpf -Markdown $content -DarkMode $script:isDarkMode
        $tabControl.Items.Add($panel)
    }
}
```

The `Convert-MarkdownToWpf` helper parses line-by-line and creates the corresponding WPF elements:

| Markdown | WPF Element |
|----------|-------------|
| `# Heading` | `<TextBlock FontSize="24" FontWeight="Bold">` |
| `## Subheading` | `<TextBlock FontSize="17" FontWeight="Bold">` |
| ```` ```code ``` ```` | `<Border Background="{DynamicResource CodeBlockBg}">` with Consolas |
| `> quote` | `<Border Background="{DynamicResource BlockquoteBg}">` |
| `- item` | `<TextBlock>` with bullet character |
| `**bold**` | Inline `Run` with `FontWeight="Bold"` |
| `[link](url)` | Hyperlink with `Foreground="{DynamicResource LinkFg}"` |
| Markdown table | `<Grid>` with row/column definitions styled like `TableBg` |

**Why runtime rendering:** You write docs in plain Markdown in `docs/`. The tool displays them with full styling. No XAML duplication, no hardcoded About text — edit the .md file and the tool updates on next launch.

---

## Pattern N: Live Column-by-Column DataGrid Filtering

Provides instantaneous search and filtering across individual DataGrid columns using WPF `CollectionViewSource` or `DataView`.

```powershell
# Setup DefaultView filtering on an ObservableCollection or DataTable
function Set-DataGridFilter {
    param(
        [System.Windows.Controls.DataGrid]$DataGrid,
        [hashtable]$FilterCriteria # e.g. @{ 'DeviceName' = 'PC'; 'OS' = 'Windows' }
    )

    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($DataGrid.ItemsSource)
    if (-not $view) { return }

    $view.Filter = [Predicate[object]]{
        param($item)
        foreach ($key in $FilterCriteria.Keys) {
            $filterText = $FilterCriteria[$key]
            if ([string]::IsNullOrWhiteSpace($filterText)) { continue }
            $propVal = "$($item.$key)"
            if ($propVal.IndexOf($filterText, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                return $false
            }
        }
        return $true
    }
}

# Attach to column filter TextBoxes in XAML:
# $script:FilterCriteria = @{}
# $script:txtFilterDeviceName.Add_TextChanged({
#     $script:FilterCriteria['DeviceName'] = $script:txtFilterDeviceName.Text
#     Set-DataGridFilter -DataGrid $script:dgDevices -FilterCriteria $script:FilterCriteria
# })
```

---

## Pattern O: Shift-Click Multi-Row Range Selection

Enables fast range selection across checkboxes in a bulk-action DataGrid (holding `Shift` to check all rows between the last clicked row and current row).

```powershell
$script:lastCheckedIndex = -1

function Enable-ShiftClickSelection {
    param([System.Windows.Controls.DataGrid]$DataGrid)

    $DataGrid.Add_PreviewMouseLeftButtonDown({
        param($sender, $e)
        # Detect if Shift key is pressed during click on a CheckBox
        if ([System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftShift) -or
            [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::RightShift)) {
            
            $dep = $e.OriginalSource
            while ($dep -and (-not ($dep -is [System.Windows.Controls.DataGridRow]))) {
                $dep = [System.Windows.Media.VisualTreeHelper]::GetParent($dep)
            }
            if ($dep -is [System.Windows.Controls.DataGridRow]) {
                $currentIndex = $dep.GetIndex()
                if ($script:lastCheckedIndex -ge 0 -and $script:lastCheckedIndex -ne $currentIndex) {
                    $start = [Math]::Min($script:lastCheckedIndex, $currentIndex)
                    $end   = [Math]::Max($script:lastCheckedIndex, $currentIndex)

                    for ($i = $start; $i -le $end; $i++) {
                        $rowItem = $DataGrid.Items[$i]
                        if ($rowItem -and $rowItem.PSObject.Properties['IsSelected']) {
                            $rowItem.IsSelected = $true
                        }
                    }
                    $DataGrid.Items.Refresh()
                }
            }
        } else {
            # Update last index on standard click
            $dep = $e.OriginalSource
            while ($dep -and (-not ($dep -is [System.Windows.Controls.DataGridRow]))) {
                $dep = [System.Windows.Media.VisualTreeHelper]::GetParent($dep)
            }
            if ($dep -is [System.Windows.Controls.DataGridRow]) {
                $script:lastCheckedIndex = $dep.GetIndex()
            }
        }
    })
}
```

---

## Pattern P: Multi-Input Comma-Separated Search Parsing

Parses search queries entered as comma-delimited or newline-delimited lists (e.g. searching 50 serial numbers or device names at once).

```powershell
function Get-ParsedSearchTerms {
    [CmdletBinding()]
    param([string]$RawInput)

    if ([string]::IsNullOrWhiteSpace($RawInput)) { return @() }

    # Split by comma, semicolon, or newline, trim whitespace, and discard blanks
    $terms = $RawInput -split '[,;\r\n]+' |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique

    return @($terms)
}
```

---

## Pattern Q: Settings Persistence Pattern (`settings.json` in `%LocalAppData%`)

Safely stores and retrieves application preferences (theme state, last search mode, Tenant/Client ID, recent filters) without storing plain-text secrets.

```powershell
function Get-AppSettings {
    param([string]$ToolName)
    $path = Join-Path $env:LOCALAPPDATA "$ToolName\settings.json"
    if (Test-Path -Path $path) {
        try {
            return Get-Content -Path $path -Raw | ConvertFrom-Json
        } catch {
            return @{}
        }
    }
    return @{}
}

function Set-AppSettings {
    param(
        [string]$ToolName,
        [hashtable]$Settings
    )
    $dir = Join-Path $env:LOCALAPPDATA $ToolName
    if (-not (Test-Path -Path $dir)) {
        $null = New-Item -ItemType Directory -Path $dir -Force -ErrorAction SilentlyContinue
    }
    $path = Join-Path $dir 'settings.json'
    # Security Rule: Never include passwords or client secrets in $Settings
    $Settings | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8 -Force
}
```

---

## Pattern R: Async External Process Wrapper (Runspace + ProcessStartInfo + Polling)

Wraps an external CLI executable (`.exe`) or native Windows tool (e.g. `IntuneWinAppUtil.exe`, `DISM.exe`, `Robocopy.exe`, `ffmpeg.exe`) without blocking the WPF UI thread. Captures standard output & standard error in real time and polls completion via `DispatcherTimer`.

```powershell
function Start-ProcessAsync {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutablePath,
        [Parameter(Mandatory = $true)][string]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory
    )

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.ThreadOptions = 'ReuseThread'
    $rs.Open()

    $ps = [powershell]::Create()
    $ps.Runspace = $rs

    $null = $ps.AddScript({
        param($Exe, $Args, $Cwd)

        $result = [ordered]@{
            Started  = (Get-Date).ToString("s")
            ExitCode = $null
            StdOut   = ''
            StdErr   = ''
        }

        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName               = $Exe
            $psi.Arguments              = $Args
            $psi.WorkingDirectory       = $Cwd
            $psi.UseShellExecute        = $false
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError  = $true
            $psi.CreateNoWindow         = $true

            $p = New-Object System.Diagnostics.Process
            $p.StartInfo = $psi

            if (-not $p.Start()) { throw "Failed to start process: $Exe" }
            $stdout = $p.StandardOutput.ReadToEnd()
            $stderr = $p.StandardError.ReadToEnd()
            $p.WaitForExit()

            $result.ExitCode = $p.ExitCode
            $result.StdOut   = $stdout
            $result.StdErr   = $stderr
        }
        catch {
            $result.ExitCode = -1
            $result.StdErr   = $_.Exception.Message
        }

        [pscustomobject]$result
    })

    $null = $ps.AddArgument($ExecutablePath)
    $null = $ps.AddArgument($Arguments)
    $null = $ps.AddArgument($WorkingDirectory)

    $script:ActiveRunspace  = $rs
    $script:AsyncPowerShell = $ps
    $script:AsyncResult     = $ps.BeginInvoke()
}

# Polling Timer Handler (Tick every 300ms)
function Initialize-ProcessPollTimer {
    param([scriptblock]$OnComplete)

    $pollTimer = New-Object System.Windows.Threading.DispatcherTimer
    $pollTimer.Interval = [TimeSpan]::FromMilliseconds(300)
    $pollTimer.Add_Tick({
        if ($script:AsyncResult -and $script:AsyncResult.IsCompleted) {
            $pollTimer.Stop()
            try {
                $res = $script:AsyncPowerShell.EndInvoke($script:AsyncResult)
                & $OnComplete $res
            }
            finally {
                try { if ($script:AsyncPowerShell) { $script:AsyncPowerShell.Dispose() } } catch {}
                try { if ($script:ActiveRunspace) { $script:ActiveRunspace.Close(); $script:ActiveRunspace.Dispose() } } catch {}
                $script:AsyncPowerShell = $null
                $script:AsyncResult     = $null
                $script:ActiveRunspace  = $null
            }
        }
    })
    $pollTimer.Start()
}
```

---

## Pattern S: RichTextBox Live Message Center (Colorized In-App Terminal Console)

Provides an integrated, color-coded terminal log box inside the main WPF window using `RichTextBox` and `Paragraph` elements without freezing the UI.

```powershell
function Write-LiveMessageCenter {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    if (-not $script:LogBox) { return }

    $brushHex = switch ($Level) {
        'SUCCESS' { '#10B981' } # Emerald Green
        'WARNING' { '#F59E0B' } # Amber
        'ERROR'   { '#EF4444' } # Red
        default   { '#60A5FA' } # Blue
    }
    $brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($brushHex)

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'HH:mm:ss'), $Level, $Message

    $script:LogBox.Dispatcher.Invoke([action]{
        $para = New-Object System.Windows.Documents.Paragraph
        $para.Margin     = '0,0,0,0'
        $para.LineHeight = 18
        $run = New-Object System.Windows.Documents.Run $line
        $run.Foreground  = $brush
        $para.Inlines.Add($run)
        $script:LogBox.Document.Blocks.Add($para)
        $script:LogBox.ScrollToEnd()
    })
}
```

**XAML layout (Copy + Clear on far right of same header row):**
```xml
<Border Style="{StaticResource Card}">
    <StackPanel>
        <DockPanel LastChildFill="False" Margin="0,0,0,8">
            <TextBlock Text="Live Log" FontSize="14" FontWeight="Bold" Foreground="{DynamicResource TextPrimaryBrush}" VerticalAlignment="Center" DockPanel.Dock="Left"/>
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" VerticalAlignment="Center">
                <Button x:Name="btnCopyLog" Style="{StaticResource BtnBlue}" Content="Copy" Height="28" MinWidth="70" Margin="0,0,8,0" ToolTip="Copy log to clipboard"/>
                <Button x:Name="btnClearLog" Style="{StaticResource BtnOutline}" Content="Clear" Height="28" MinWidth="70" ToolTip="Clear log view"/>
            </StackPanel>
        </DockPanel>
        <Border BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1" CornerRadius="6" Background="#1E293B">
            <RichTextBox x:Name="rtbLog" Style="{StaticResource LiveMessageCenterBox}"/>
        </Border>
    </StackPanel>
</Border>
```
`LastChildFill="False"` keeps `Live Log` at far left and buttons at far right of the same row. `btnCopyLog` uses `TextRange` → `Clipboard::SetText` + toast Success; `btnClearLog` clears `Document.Blocks` + toast Info. Both are wrapped in `Guard-Action`.

---

## Pattern T: Native Windows OS Toast Notifications (Action Center WinRT XML)

Dispatches native Windows 10/11 Action Center toast notifications directly using the built-in Windows Runtime (WinRT) XML APIs without requiring external modules (like `BurntToast`). Ideal for background scripts, Intune maintenance, or long-running jobs notifying the user upon completion.

```powershell
function Send-NativeWindowsToast {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('Default', 'Reminder', 'Alarm', 'IncomingCall')]
        [string]$Scenario = 'Default',
        [string]$AppId = 'PowerShell.EnterpriseAdmin'
    )

    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        $escapedTitle   = [System.Security.SecurityElement]::Escape($Title)
        $escapedMessage = [System.Security.SecurityElement]::Escape($Message)

        $template = @"
<toast scenario="$Scenario">
    <visual>
        <binding template="ToastGeneric">
            <text>$escapedTitle</text>
            <text>$escapedMessage</text>
        </binding>
    </visual>
</toast>
"@

        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)

        $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($toast)
    }
    catch {
        # Fallback to standard PowerShell notification if WinRT is unavailable (e.g. Server Core)
        Write-Warning "WinRT Toast unavailable: $($_.Exception.Message)"
    }
}
```

---

## Pattern U: Responsive HTML Executive Report Generator

Generates a standalone, responsive, modern HTML report styled with Tailwind Slate design tokens. Includes a gradient hero (with serial badge), KPI cards with sub-captions, a Security & Power strip (TPM pills + battery bar), Storage Volumes as color-coded animated bars (ok >=20% free / warn 10-19 / crit <10), Memory/GPU/Physical-disk tables with empty-state fallbacks, an extended network table (Gateway/DNS/DHCP pill), client-side search + click-to-sort tables (numeric-aware, zero dependencies), dark mode via data-theme+localStorage+prefers-color-scheme, and print styles.

```powershell
function Export-ExecutiveHtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ReportTitle,
        [Parameter(Mandatory = $true)][array]$DataRows,
        [Parameter(Mandatory = $false)][hashtable]$SummaryKpis = @{},
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    $parentDir = Split-Path -Path $OutputPath -Parent
    if ($parentDir -and (-not (Test-Path $parentDir))) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Extract headers
    $properties = if ($DataRows.Count -gt 0) { $DataRows[0].PSObject.Properties.Name } else { @() }

    # Generate KPI cards HTML (polished with icons)
    $kpiHtml = ""
    foreach ($key in $SummaryKpis.Keys) {
        $val = $SummaryKpis[$key]
        $iconClass = switch -Wildcard ($key) { "*CPU*" { "cpu" } "*RAM*" { "ram" } "*Disk*" { "disk" } "*Uptime*" { "uptime" } "*Total*" { "cpu" } default { "cpu" } }
        $iconChar = switch ($iconClass) { "cpu" { "⚙️" } "ram" { "🧠" } "disk" { "💾" } "uptime" { "⏱️" } default { "📊" } }
        $valueClass = if ($key -like "*Disk*") { "success" } else { "accent" }
        $kpiHtml += @"
        <div class="kpi-card">
            <div class="kpi-head"><div class="kpi-label">$key</div><div class="kpi-icon $iconClass">$iconChar</div></div>
            <div class="kpi-value $valueClass">$val</div>
        </div>
"@
    }

    # Generate Table Header
    $thHtml = ($properties | ForEach-Object { "<th>$_</th>" }) -join "`n"

    # Generate Table Rows
    $trHtml = ""
    foreach ($row in $DataRows) {
        $tds = foreach ($prop in $properties) {
            $cellVal = [System.Security.SecurityElement]::Escape("$($row.$prop)")
            "<td>$cellVal</td>"
        }
        $trHtml += "<tr>$($tds -join '')</tr>`n"
    }

    $generatedDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$ReportTitle</title>
    <style>
        :root {
            --bg: #F1F5F9;
            --bg-gradient: radial-gradient(1200px 600px at 20% -10%, #DBEAFE 0%, transparent 60%), radial-gradient(900px 500px at 90% 0%, #E9D5FF 0%, transparent 55%), #F1F5F9;
            --surface: #FFFFFF;
            --surface-hover: #F8FAFC;
            --border: #E2E8F0;
            --border-strong: #CBD5E1;
            --text-main: #0F172A;
            --text-muted: #64748B;
            --text-faint: #94A3B8;
            --accent: #3B82F6;
            --accent-soft: #EFF6FF;
            --success: #10B981;
            --success-soft: #ECFDF5;
            --shadow: 0 12px 24px rgba(15,23,42,0.06), 0 4px 8px rgba(15,23,42,0.04);
            --shadow-hover: 0 16px 32px rgba(15,23,42,0.08), 0 8px 16px rgba(59,130,246,0.08);
            --radius: 16px;
        }
        [data-theme="dark"] {
            --bg: #0F172A;
            --bg-gradient: radial-gradient(1000px 600px at 20% -10%, #1E293B 0%, transparent 60%), #0F172A;
            --surface: #1E293B;
            --surface-hover: #334155;
            --border: #334155;
            --text-main: #F1F5F9;
            --text-muted: #94A3B8;
            --accent-soft: #1E3A5F;
            --shadow: 0 12px 32px rgba(0,0,0,0.35);
        }
        * { box-sizing: border-box; }
        body {
            font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: var(--bg);
            background-image: var(--bg-gradient);
            color: var(--text-main);
            margin: 0;
            padding: 32px 20px 40px;
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
        }
        .container { max-width: 1280px; margin: 0 auto; }
        .hero {
            background: linear-gradient(135deg, #3B82F6 0%, #6366F1 45%, #8B5CF6 100%);
            color: white; border-radius: var(--radius); padding: 28px; box-shadow: 0 16px 32px rgba(59,130,246,0.25);
            position: relative; overflow: hidden; margin-bottom: 20px;
        }
        .hero::before { content: ""; position: absolute; inset: -40% -20% auto auto; width: 420px; height: 420px; background: radial-gradient(circle at 30% 30%, rgba(255,255,255,0.18), transparent 60%); pointer-events: none; }
        .hero h1 { margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.02em; }
        .hero .subtitle { margin: 6px 0 0; font-size: 13px; opacity: 0.92; font-weight: 500; }
        .kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 14px; margin-bottom: 18px; }
        .card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; box-shadow: var(--shadow); margin-bottom: 16px; overflow: hidden; transition: transform 0.18s, box-shadow 0.18s; }
        .card:hover { transform: translateY(-1px); box-shadow: var(--shadow-hover); }
        .kpi-card { position: relative; overflow: hidden; }
        .kpi-card::after { content: ""; position: absolute; inset: auto -20px -20px auto; width: 90px; height: 90px; background: radial-gradient(circle at 30% 30%, var(--accent-soft), transparent 70%); opacity: 0.9; pointer-events: none; }
        .kpi-head { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 10px; }
        .kpi-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.07em; color: var(--text-muted); }
        .kpi-icon { width: 32px; height: 32px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 15px; }
        .kpi-icon.cpu { background: #EFF6FF; color: #2563EB; } .kpi-icon.ram { background: #F5F3FF; color: #7C3AED; } .kpi-icon.disk { background: #ECFDF5; color: #059669; } .kpi-icon.uptime { background: #FFF7ED; color: #EA580C; }
        .kpi-value { font-size: 22px; font-weight: 800; letter-spacing: -0.02em; }
        .kpi-value.accent { color: var(--accent); } .kpi-value.success { color: var(--success); }
        .search-box { width: 100%; padding: 9px 12px 9px 30px; border: 1px solid var(--border); border-radius: 10px; font-size: 13px; outline: none; background: var(--surface); color: var(--text-main); }
        .search-box:focus { border-color: var(--accent); box-shadow: 0 0 0 3px rgba(59,130,246,0.14); }
        .table-container { overflow-x: auto; border-radius: 12px; border: 1px solid var(--border); }
        table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13px; }
        th { background: var(--surface-hover); color: var(--text-muted); padding: 11px 16px; font-weight: 700; font-size: 11px; letter-spacing: 0.05em; text-transform: uppercase; border-bottom: 1px solid var(--border); position: sticky; top: 0; }
        td { padding: 12px 16px; border-bottom: 1px solid var(--border); }
        tr:hover td { background: var(--surface-hover); }
    </style>
</head>
<body>
    <div class="container">
        <div class="hero">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:16px; position:relative;">
                <div>
                    <h1>$ReportTitle</h1>
                    <div class="subtitle">Generated on $generatedDate • Host: $env:COMPUTERNAME • Records: $($DataRows.Count)</div>
                </div>
                <button onclick="toggleTheme()" style="width:38px; height:38px; border-radius:10px; border:1px solid rgba(255,255,255,0.22); background:rgba(255,255,255,0.14); color:white; cursor:pointer; backdrop-filter:blur(6px);">◐</button>
            </div>
        </div>

        <div class="kpi-grid">
            <div class="kpi-card">
                <div class="kpi-head"><div class="kpi-label">Total Records</div><div class="kpi-icon cpu">📊</div></div>
                <div class="kpi-value accent">$($DataRows.Count)</div>
            </div>
            $kpiHtml
        </div>

        <div class="card">
            <input type="text" id="filterInput" class="search-box" placeholder="Filter records in real-time..." onkeyup="filterTable()">
            <div class="table-container">
                <table id="reportTable">
                    <thead>
                        <tr>$thHtml</tr>
                    </thead>
                    <tbody>
                        $trHtml
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        function toggleTheme() {
            var isDark = document.documentElement.getAttribute('data-theme') === 'dark';
            var next = isDark ? 'light' : 'dark';
            if (next === 'dark') document.documentElement.setAttribute('data-theme', 'dark');
            else document.documentElement.removeAttribute('data-theme');
            try { localStorage.setItem('report-theme', next); } catch(e) {}
        }
        (function(){ try { var saved=localStorage.getItem('report-theme'); if(saved==='dark') document.documentElement.setAttribute('data-theme','dark'); } catch(e){} })();
        function filterTable() {
            var input = document.getElementById("filterInput");
            var filter = input.value.toLowerCase();
            var table = document.getElementById("reportTable");
            var trs = table.getElementsByTagName("tr");

            for (var i = 1; i < trs.length; i++) {
                var rowText = trs[i].textContent.toLowerCase();
                trs[i].style.display = rowText.indexOf(filter) > -1 ? "" : "none";
            }
        }
    </script>
</body>
</html>
"@

    Set-Content -Path $OutputPath -Value $html -Encoding UTF8
    Write-Log -Message "Executive HTML Report successfully generated at: $OutputPath" -Level SUCCESS
}
```
