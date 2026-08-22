# XAML Styles — Canonical Enterprise Required Styles

Every `MainWindow.xaml` MUST define these styles in `Window.Resources`. They are the visual identity of every tool. Do not modify them, do not skip them, do not create alternatives.

---

## Table of Contents

1. [ProgressBar Style](#progressbar-style)
2. [BtnBase — Root Button](#btnbase--root-button)
3. [BtnPrimary / BtnBlue / BtnGreen / BtnRed / BtnPurple](#btn-variants)
4. [BtnOutline](#btnoutline)
5. [NavBtnBase — Sidebar Navigation](#navbtnbase--sidebar-navigation)
6. [Card — Content Container](#card--content-container)
7. [StatCard — KPI Card](#statcard--kpi-card)
8. [InputBox / InputBoxNoHover](#inputbox--inputboxnohover)
9. [FieldLabel](#fieldlabel)
10. [BottomActionBtn — Sidebar Footer](#bottomactionbtn--sidebar-footer)

---

## ProgressBar Style

A custom ProgressBar with rounded corners and an indeterminate-mode animation glow. Define this without a key (it applies to all `<ProgressBar>` elements):

```xml
<Style TargetType="{x:Type ProgressBar}">
    <Setter Property="Background" Value="{DynamicResource BorderBrush}" />
    <Setter Property="Foreground" Value="{DynamicResource SuccessBrush}" />
    <Setter Property="BorderThickness" Value="0" />
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="{x:Type ProgressBar}">
                <Grid>
                    <Border Background="{TemplateBinding Background}" CornerRadius="6" />
                    <Border x:Name="PART_Indicator"
                        Background="{TemplateBinding Foreground}" CornerRadius="6"
                        HorizontalAlignment="Left" />
                    <Border x:Name="IndeterminateGlow"
                        Background="{TemplateBinding Foreground}" CornerRadius="6"
                        HorizontalAlignment="Left" Width="100" Visibility="Hidden">
                        <Border.RenderTransform>
                            <TranslateTransform x:Name="GlowTransform" X="-100" />
                        </Border.RenderTransform>
                    </Border>
                </Grid>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsIndeterminate" Value="True">
                        <Setter TargetName="PART_Indicator" Property="Visibility" Value="Hidden" />
                        <Setter TargetName="IndeterminateGlow" Property="Visibility" Value="Visible" />
                        <Trigger.EnterActions>
                            <BeginStoryboard x:Name="IndeterminateStoryboard">
                                <Storyboard RepeatBehavior="Forever">
                                    <DoubleAnimation Storyboard.TargetName="GlowTransform"
                                        Storyboard.TargetProperty="X" From="-100" To="400"
                                        Duration="0:0:1.5" />
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
```

---

## BtnBase — Root Button

The foundation every other button style builds on. **Always** define this first because all other button styles use `BasedOn="{StaticResource BtnBase}"`.

```xml
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
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                            BorderBrush="{TemplateBinding BorderBrush}"
                            BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8"
                            SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center"
                                VerticalAlignment="Center" Margin="{TemplateBinding Padding}" />
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
                                <Setter TargetName="border" Property="Background"
                                    Value="{DynamicResource SurfaceHoverBrush}" />
                                <Setter TargetName="border" Property="BorderBrush"
                                    Value="{DynamicResource BorderBrush}" />
                                <Setter TargetName="border" Property="BorderThickness" Value="1" />
                                <Setter Property="Foreground"
                                    Value="{DynamicResource TextMutedBrush}" />
                                <Setter TargetName="border" Property="UIElement.Opacity" Value="0.55" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
```

**Critical pitfalls (see `pitfalls.md` for full list):**

- `UIElement.Opacity` MUST be fully qualified in control template triggers. Plain `Opacity` may resolve wrong.
- `SnapsToDevicePixels="True"` prevents text blur on high-DPI displays.
- Disabled state changes Background, Border, Foreground — not just opacity — to look distinct.

---

## Btn Variants

All built on `BtnBase`. Just specify the color token.

```xml
<!-- Primary CTA — purple-blue, used for the main action -->
<Style x:Key="BtnPrimary" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
    <Setter Property="Background" Value="{DynamicResource BtnPrimaryBg}" />
    <Setter Property="Foreground" Value="White" />
</Style>

<!-- Blue — secondary actions, info buttons -->
<Style x:Key="BtnBlue" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
    <Setter Property="Background" Value="{DynamicResource BtnBlueBg}" />
    <Setter Property="Foreground" Value="White" />
</Style>

<!-- Green — success, save, apply -->
<Style x:Key="BtnGreen" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
    <Setter Property="Background" Value="{DynamicResource BtnGreenBg}" />
    <Setter Property="Foreground" Value="White" />
</Style>

<!-- Red — delete, destructive -->
<Style x:Key="BtnRed" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
    <Setter Property="Background" Value="{DynamicResource BtnRedBg}" />
    <Setter Property="Foreground" Value="White" />
</Style>

<!-- Purple — About tab selector -->
<Style x:Key="BtnPurple" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
    <Setter Property="Background" Value="{DynamicResource BtnPurpleBg}" />
    <Setter Property="Foreground" Value="White" />
</Style>

<!-- Ghost — minimal, text-only with hover tint -->
<Style x:Key="BtnGhost" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
    <Setter Property="Background" Value="Transparent" />
    <Setter Property="Foreground" Value="{DynamicResource BtnGhostFg}" />
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="{x:Type Button}">
                <Border x:Name="border" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="border" Property="Background"
                            Value="{DynamicResource BtnGhostHoverBg}" />
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
```

---

## BtnOutline

Transparent fill, 1px border. Use for secondary actions that should look less prominent than filled buttons.

```xml
<Style x:Key="BtnOutline" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
    <Setter Property="Background" Value="Transparent" />
    <Setter Property="Foreground" Value="{DynamicResource TextBodyBrush}" />
    <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
    <Setter Property="BorderThickness" Value="1" />
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="{x:Type Button}">
                <Border x:Name="border" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="border" Property="Background"
                            Value="{DynamicResource SurfaceHoverBrush}" />
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
```

---

## NavBtnBase — Sidebar Navigation

Tall (46px), rounded (10px corner), left-aligned text, hover changes background only.

```xml
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
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                            BorderBrush="{TemplateBinding BorderBrush}"
                            BorderThickness="{TemplateBinding BorderThickness}"
                            CornerRadius="10" SnapsToDevicePixels="True">
                            <ContentPresenter
                                HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                VerticalAlignment="{TemplateBinding VerticalContentAlignment}"
                                Margin="{TemplateBinding Padding}" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background"
                                    Value="{DynamicResource AccentTintBrush}" />
                                <Setter TargetName="border" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                                <Setter TargetName="border" Property="BorderThickness" Value="1"/>
                                <Setter TargetName="border" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect BlurRadius="8" ShadowDepth="1" Color="#3B82F6" Opacity="0.12" Direction="270"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background"
                                    Value="{DynamicResource AccentBrush}" />
                                <Setter TargetName="border" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
```

**Active state pattern** (the current page's nav button): set `Background="{DynamicResource AccentTintBrush}"` and `Foreground="{DynamicResource AccentHoverBrush}"` directly on the active button. Do NOT add a new style — just override these two properties.

---

## Card — Content Container

White/surface background, 12px corner, drop shadow. Used for sections, forms, results. **STATIC** — no IsMouseOver trigger.

```xml
<Style x:Key="Card" TargetType="{x:Type Border}">
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="CornerRadius" Value="14" />
            <Setter Property="Padding" Value="18" />
            <Setter Property="Margin" Value="0,0,0,14" />
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect BlurRadius="24" ShadowDepth="6" Color="#0F172A" Opacity="0.045"
                        Direction="270" />
                </Setter.Value>
            </Setter>
        </Style>
```

Usage: `<Border Style="{StaticResource Card}"> ... </Border>`

---

## StatCard — KPI Card

Like Card but with hover-border highlight. Used for dashboard KPI tiles (number + label).

```xml
<Style x:Key="StatCard" TargetType="{x:Type Border}">
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="CornerRadius" Value="14" />
            <Setter Property="Padding" Value="18,16" />
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect BlurRadius="16" ShadowDepth="4" Color="#0F172A" Opacity="0.05"
                        Direction="270" />
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="BorderBrush" Value="{DynamicResource BorderHoverBrush}" />
                    <Setter Property="Background" Value="{DynamicResource SurfaceHoverBrush}" />
                    <Setter Property="Effect">
                        <Setter.Value>
                            <DropShadowEffect BlurRadius="20" ShadowDepth="6" Color="#3B82F6" Opacity="0.08" Direction="270" />
                        </Setter.Value>
                    </Setter>
                </Trigger>
            </Style.Triggers>
        </Style>
```

---

## InputBox / InputBoxNoHover

Text input with focus highlight (AccentBrush border on `IsKeyboardFocused`). **`InputBox` has NO IsMouseOver trigger** — keyboard focus only. `InputBoxNoHover` exists for cases where you want the border to never change at all.

```xml
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
                <Border x:Name="bdInput" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6"
                    SnapsToDevicePixels="True">
                    <ScrollViewer x:Name="PART_ContentHost"
                        Margin="{TemplateBinding Padding}" VerticalAlignment="Center"
                        Focusable="False" HorizontalScrollBarVisibility="Hidden"
                        VerticalScrollBarVisibility="Hidden" />
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsKeyboardFocused" Value="True">
                        <Setter TargetName="bdInput" Property="BorderBrush"
                            Value="{DynamicResource AccentBrush}" />
                        <Setter TargetName="bdInput" Property="BorderThickness" Value="1.5" />
                    </Trigger>
                    <Trigger Property="IsEnabled" Value="False">
                        <Setter Property="Opacity" Value="0.55" />
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>

<Style x:Key="InputBoxNoHover" TargetType="TextBox" BasedOn="{StaticResource InputBox}">
    <!-- Override the IsKeyboardFocused trigger to do nothing if you need a totally static input -->
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="TextBox">
                <Border x:Name="bdInput" Background="{TemplateBinding Background}"
                    BorderBrush="{DynamicResource BorderBrush}"
                    BorderThickness="1" CornerRadius="6">
                    <ScrollViewer x:Name="PART_ContentHost"
                        Margin="{TemplateBinding Padding}" VerticalAlignment="Center"
                        Focusable="False" />
                </Border>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
```

---

## StyledCheckBox

Modern CheckBox matching the Tailwind Slate design system.

```xml
<Style x:Key="StyledCheckBox" TargetType="CheckBox">
    <Setter Property="Foreground" Value="{DynamicResource TextPrimaryBrush}" />
    <Setter Property="FontSize" Value="13" />
    <Setter Property="FontWeight" Value="SemiBold" />
    <Setter Property="VerticalContentAlignment" Value="Center" />
    <Setter Property="Cursor" Value="Hand" />
</Style>
```

---

## StyledComboBox

Modern ComboBox matching the Tailwind Slate design system.

```xml
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
```

---

## FieldLabel

Small label text above form fields.

```xml
<Style x:Key="FieldLabel" TargetType="TextBlock">
    <Setter Property="Foreground" Value="{DynamicResource TextSecondaryBrush}" />
    <Setter Property="VerticalAlignment" Value="Center" />
    <Setter Property="FontSize" Value="14" />
    <Setter Property="FontWeight" Value="SemiBold" />
</Style>
```

---

## BottomActionBtn — Sidebar Footer

The 34px tall button used in the sidebar bottom for About + Logs. Hover state changes background AND border to accent.

```xml
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
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect BlurRadius="8" ShadowDepth="2" Color="#0F172A" Opacity="0.06" Direction="270" />
                </Setter.Value>
            </Setter>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Button}">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                            BorderBrush="{TemplateBinding BorderBrush}"
                            BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8"
                            SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center"
                                VerticalAlignment="Center" Margin="{TemplateBinding Padding}" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background"
                                    Value="{DynamicResource AccentTintBrush}" />
                                <Setter TargetName="border" Property="BorderBrush"
                                    Value="{DynamicResource AccentBrush}" />
                                <Setter Property="Foreground"
                                    Value="{DynamicResource AccentHoverBrush}" />
                                <Setter TargetName="border" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect BlurRadius="12" ShadowDepth="3" Color="#3B82F6" Opacity="0.12" Direction="270"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background"
                                    Value="{DynamicResource AccentBrush}" />
                                <Setter Property="Foreground" Value="White" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
```

---

## Style Usage Cheat Sheet

| Want | Use |
|------|-----|
| Primary CTA button | `Style="{StaticResource BtnPrimary}"` |
| Secondary blue button | `Style="{StaticResource BtnBlue}"` |
| Success / save button | `Style="{StaticResource BtnGreen}"` |
| Destructive button | `Style="{StaticResource BtnRed}"` |
| Minimal button | `Style="{StaticResource BtnGhost}"` |
| Border-only button | `Style="{StaticResource BtnOutline}"` |
| Sidebar nav item | `Style="{StaticResource NavBtnBase}"` |
| Sidebar footer (About/Logs) | `Style="{StaticResource BottomActionBtn}"` |
| Form section | `Style="{StaticResource Card}"` |
| KPI tile | `Style="{StaticResource StatCard}"` |
| Text input | `Style="{StaticResource InputBox}"` |
| Form field label | `Style="{StaticResource FieldLabel}"` |
| Progress bar (any) | No style needed (the default ProgressBar style applies automatically) |
| In-app terminal log | `Style="{StaticResource LiveMessageCenterBox}"` |
| Session / elevation widget | `Style="{StaticResource SessionCard}"` |

**Never hardcode** `Background="#..."` on a Button or Border. Always use a style or `{DynamicResource ...}`.

---

## LiveMessageCenterBox — In-App Terminal Console

Dark console-themed `RichTextBox` for real-time streaming logs and command line output.

```xml
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
```

---

## SessionCard & ElevationPill — Runtime Context Widget

Sidebar session details card displaying ComputerName, User, and Administrator elevation pill.

**Style definition** (required so the `SessionCard` canonical key exists):

```xml
<Style x:Key="SessionCard" TargetType="{x:Type Border}">
    <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
    <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
    <Setter Property="BorderThickness" Value="1" />
    <Setter Property="CornerRadius" Value="8" />
    <Setter Property="Padding" Value="10" />
    <Setter Property="Margin" Value="0,0,0,10" />
</Style>
```

**Usage** — apply the style to the Border; the inner controls keep their `x:Name` bindings:

```xml
<Border Style="{StaticResource SessionCard}">
    <StackPanel>
        <TextBlock Text="SESSION" FontSize="11" FontWeight="Bold" Foreground="{DynamicResource TextMutedBrush}" Margin="0,0,0,6"/>
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <TextBlock Grid.Row="0" Grid.Column="0" Text="Host:" Foreground="{DynamicResource TextBodyBrush}" FontWeight="SemiBold" Margin="0,0,8,4"/>
            <TextBlock x:Name="SessionMachineTxt" Grid.Row="0" Grid.Column="1" Text="--" Foreground="{DynamicResource TextPrimaryBrush}" Margin="0,0,0,4"/>

            <TextBlock Grid.Row="1" Grid.Column="0" Text="User:" Foreground="{DynamicResource TextBodyBrush}" FontWeight="SemiBold" Margin="0,0,8,4"/>
            <TextBlock x:Name="SessionUserTxt" Grid.Row="1" Grid.Column="1" Text="--" Foreground="{DynamicResource TextPrimaryBrush}" Margin="0,0,0,4"/>

            <TextBlock Grid.Row="2" Grid.Column="0" Text="Role:" Foreground="{DynamicResource TextBodyBrush}" FontWeight="SemiBold" Margin="0,0,8,0"/>
            <Border x:Name="SessionElevationPill" Grid.Row="2" Grid.Column="1" Background="#ECFDF3" CornerRadius="4" Padding="6,1" HorizontalAlignment="Left">
                <TextBlock x:Name="SessionElevationTxt" Text="Administrator" FontSize="11" FontWeight="Bold" Foreground="#166534"/>
            </Border>
        </Grid>
    </StackPanel>
</Border>
```

