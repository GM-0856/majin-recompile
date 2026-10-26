param([switch]$ValidateOnly, [ValidateSet('Debug','Release')][string]$Configuration='Release')
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'reports') | Out-Null
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$settingsPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'private/launcher.json'
. (Join-Path $PSScriptRoot 'frame-rate.ps1')
$nativePath=Join-Path (Split-Path $PSScriptRoot -Parent) ('prototype/out/build/win-amd64-'+$Configuration.ToLower()+'/majin.exe')
$has60=Test-Majin60Binary -Path $nativePath
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Majin FK Launcher'
$form.ClientSize = New-Object System.Drawing.Size(1060,670)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Segoe UI',10)
$form.BackColor = [System.Drawing.Color]::FromArgb(20,29,28)
$form.ForeColor = [System.Drawing.Color]::FromArgb(235,235,218)
$assetRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets/launcher'
$imagePath = Join-Path $assetRoot 'background.png'
$logoPath = Join-Path $assetRoot 'logo.png'
$launcherLogo = $null
if (Test-Path -LiteralPath $logoPath) { $launcherLogo = [System.Drawing.Image]::FromFile($logoPath) }
$iconPath = Join-Path $assetRoot 'majin-fk.ico'
$launcherIcon = $null
if (Test-Path -LiteralPath $iconPath) {
    $launcherIcon = New-Object System.Drawing.Icon($iconPath)
    $form.Icon = $launcherIcon
}
$form.BackgroundImageLayout = 'Zoom'
if (Test-Path -LiteralPath $imagePath) { $form.BackgroundImage = [System.Drawing.Image]::FromFile($imagePath) }
$paintBackground={
    param($sender,$eventArgs)
    # Minimized/transitional windows may have an empty client area.
    if($sender.ClientSize.Width -le 0 -or $sender.ClientSize.Height -le 0){return}
    $rect = New-Object System.Drawing.Rectangle(0,0,[Math]::Min(520,$sender.ClientSize.Width),$sender.ClientSize.Height)
    $shade = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,
        [System.Drawing.Color]::FromArgb(250,12,23,22),
        [System.Drawing.Color]::FromArgb(0,12,23,22),0.0)
    try {$eventArgs.Graphics.FillRectangle($shade,$rect)} finally {$shade.Dispose()}
}
$form.Add_Paint($paintBackground)
function Add-Label($text,$y,$width=385) {
    $label = New-Object System.Windows.Forms.Label
    $label.BackColor=[System.Drawing.Color]::Transparent; $label.Text=$text; $label.SetBounds(32,$y,$width,28); $form.Controls.Add($label)
}
function Add-Choice($title,$y,$items) {
    Add-Label $title $y 150
    $box=New-Object System.Windows.Forms.ComboBox
    $box.DropDownStyle='DropDownList'; $box.SetBounds(187,$y,230,28)
    $box.BackColor=[System.Drawing.Color]::FromArgb(38,49,46); $box.ForeColor=$form.ForeColor; $box.FlatStyle='Flat'
    $box.Items.AddRange([object[]]$items); $box.SelectedIndex=0
    $form.Controls.Add($box); $box.BringToFront(); return $box
}
$heading = New-Object System.Windows.Forms.Label
$heading.BackColor=[System.Drawing.Color]::Transparent
$heading.SetBounds(28,12,720,124)
$heading.Add_Paint({
    param($sender,$eventArgs)
    if (!$launcherLogo) {return}
    # Ignore the supplied logo's transparent outer padding only while drawing.
    # Keep the original PNG unchanged, and preserve the lettering's aspect ratio.
    $sourceRect=New-Object System.Drawing.Rectangle(24,168,2067,385)
    $factor=[Math]::Min($sender.ClientSize.Width/[double]$sourceRect.Width,
        $sender.ClientSize.Height/[double]$sourceRect.Height)
    if($factor -le 0){return}
    $destination=New-Object System.Drawing.Rectangle(0,0,
        [int][Math]::Round($sourceRect.Width*$factor),[int][Math]::Round($sourceRect.Height*$factor))
    $eventArgs.Graphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $eventArgs.Graphics.DrawImage($launcherLogo,$destination,$sourceRect,[System.Drawing.GraphicsUnit]::Pixel)
})
$form.Controls.Add($heading)

Add-Label 'DISPLAY SETTINGS' 145
$size=Add-Choice 'Window size' 185 @('1280x720','1920x1080','2560x1440','3840x2160')
$mode=Add-Choice 'Display mode' 225 @('Fullscreen','Windowed')
$scale=Add-Choice 'Render scale' 265 @('1x - Native (720p)','2x - 1440p (experimental)','3x - 2160p (experimental)')
$effect=Add-Choice 'Anti-aliasing' 305 @('Original','FXAA')
$sync=Add-Choice 'VSync / FPS' 345 @('On','Off')
$sync.Width=82
$frameRate=New-Object System.Windows.Forms.ComboBox
$frameRate.DropDownStyle='DropDownList';$frameRate.SetBounds(277,345,140,28)
$frameRate.BackColor=$sync.BackColor;$frameRate.ForeColor=$sync.ForeColor;$frameRate.FlatStyle='Flat'
$frameRate.Items.AddRange([object[]]@('Original','60 FPS (test)'));$frameRate.SelectedIndex=0
$form.Controls.Add($frameRate)
$frameRate.Enabled=$has60
$api=Add-Choice 'Graphics API' 385 @('Direct3D 12')
$api.Enabled=$false
$renderingPath=Add-Choice 'Rendering path' 425 @('Default','ROV Compatibility')
$renderTooltip=New-Object System.Windows.Forms.ToolTip
$renderTooltip.SetToolTip($frameRate,'Optional 60 FPS candidate. Original keeps previous timing. VSync is independent; movies may remain 30 FPS. See FPS_60.md.')
if(!$has60){$renderTooltip.SetToolTip($frameRate,'This native build uses Original mode. Open the separate 60 FPS candidate to test the new option.')}
$renderTooltip.SetToolTip($renderingPath,'Try ROV if the image turns black. It may reduce performance. Each mode keeps its own shader cache.')
$inputMode=Add-Choice 'Input' 465 @('Controller','Keyboard + mouse (test)')
$controlHelp=New-Object System.Windows.Forms.Button
$controlHelp.Text='Controls / sensitivity'
$controlHelp.SetBounds(187,497,230,28)
$controlHelp.FlatStyle='Flat'
$controlHelp.BackColor=[System.Drawing.Color]::FromArgb(38,49,46)
$form.Controls.Add($controlHelp)
$script:mouseSensitivity=1.0
$controlHelp.Add_Click({
    $dialog=New-Object System.Windows.Forms.Form
    $dialog.Text='Keyboard + mouse (experimental)'
    $dialog.ClientSize=New-Object System.Drawing.Size(480,390)
    $dialog.StartPosition='CenterParent'; $dialog.FormBorderStyle='FixedDialog'
    $dialog.MaximizeBox=$false; $dialog.MinimizeBox=$false
    $dialog.Font=$form.Font; $dialog.BackColor=$form.BackColor; $dialog.ForeColor=$form.ForeColor
    $help=New-Object System.Windows.Forms.Label
    $help.SetBounds(20,16,440,270)
    $help.Text="WASD: move | Mouse / IJKL: camera`nSpace: A (jump / confirm)`nHold Shift: B (run / dash)`nE: B (interact / back)`nLeft mouse: X (attack) | R: Y (roll)`nHold Q: LT (crouch) | Right mouse: RT (command)`nF: LB (throw mode) | C: RB (ability)`nArrows: D-pad | V: LS click | Middle mouse: RS click`nEnter: pause (Start) | Tab: map (Back) | Esc: quit`n`nXbox prompts remain in-game. Controller stays available.`nAlt+Tab releases the mouse. Use this profile for testing;`nremapping and in-game keyboard icons will follow."
    $dialog.Controls.Add($help)
    $caption=New-Object System.Windows.Forms.Label
    $caption.Text='Mouse sensitivity'; $caption.SetBounds(20,290,180,28)
    $dialog.Controls.Add($caption)
    $sensitivity=New-Object System.Windows.Forms.NumericUpDown
    $sensitivity.SetBounds(220,290,120,28); $sensitivity.DecimalPlaces=2
    $sensitivity.Minimum=0.01; $sensitivity.Maximum=10; $sensitivity.Increment=0.1
    $sensitivity.Value=[decimal]$script:mouseSensitivity
    $dialog.Controls.Add($sensitivity)
    $ok=New-Object System.Windows.Forms.Button
    $ok.Text='OK'; $ok.SetBounds(340,340,120,32); $ok.DialogResult='OK'
    $dialog.Controls.Add($ok); $dialog.AcceptButton=$ok
    if($dialog.ShowDialog($form) -eq 'OK'){$script:mouseSensitivity=[double]$sensitivity.Value}
    $dialog.Dispose()
})

$script:recordPerformance=$true
$script:includeHardware=$false
function Show-MajinDiagnosticsOptions([switch]$ValidateOnly) {
    $dialog=New-Object System.Windows.Forms.Form
    $dialog.Text='Local diagnostics / privacy'
    $dialog.ClientSize=New-Object System.Drawing.Size(570,355)
    $dialog.StartPosition='CenterParent';$dialog.FormBorderStyle='FixedDialog'
    $dialog.MaximizeBox=$false;$dialog.MinimizeBox=$false
    $dialog.Font=$form.Font;$dialog.BackColor=$form.BackColor;$dialog.ForeColor=$form.ForeColor
    $frames=New-Object System.Windows.Forms.CheckBox
    $frames.Text='Record FPS / frame times locally'
    $frames.SetBounds(20,16,530,30);$frames.Checked=$script:recordPerformance
    $dialog.Controls.Add($frames)
    $hardware=New-Object System.Windows.Forms.CheckBox
    $hardware.Text='Include optional CPU, RAM and GPU/driver details'
    $hardware.SetBounds(20,54,530,30);$hardware.Checked=$script:includeHardware
    $dialog.Controls.Add($hardware)
    $explanation=New-Object System.Windows.Forms.Label
    $explanation.SetBounds(20,98,530,150)
    $explanation.Text="Files stay in reports. No automatic upload or online tracking.`nFrame CSV measures guest swap intervals, including pauses/loading;`nthis is not GPU execution or monitor display timing.`nThe active graphics adapter already appears in the game log.`nOptional hardware details exclude account/computer names, serial`nnumbers, UUIDs, IP/MAC addresses and installed applications.`nReview the diagnostic ZIP before sharing it."
    $dialog.Controls.Add($explanation)
    $collect=New-Object System.Windows.Forms.Button
    $collect.Text='Create diagnostic ZIP';$collect.SetBounds(20,280,220,40)
    $dialog.Controls.Add($collect)
    $collect.Add_Click({
        $dialog.UseWaitCursor=$true;$collect.Enabled=$false
        try {
            $result=& (Join-Path $PSScriptRoot 'collect-diagnostics.ps1') -IncludeHardware:$hardware.Checked -SkipHardware:(!$hardware.Checked)
            [void][System.Windows.Forms.MessageBox]::Show(($result -join "`n"),'Local diagnostic ZIP')
        }catch{[void][System.Windows.Forms.MessageBox]::Show('Unable to collect diagnostics. Game logs remain in reports.','Diagnostics')}
        finally{$dialog.UseWaitCursor=$false;$collect.Enabled=$true}
    }.GetNewClosure())
    $ok=New-Object System.Windows.Forms.Button
    $ok.Text='OK';$ok.SetBounds(430,280,120,40);$ok.DialogResult='OK'
    $dialog.Controls.Add($ok);$dialog.AcceptButton=$ok
    if($ValidateOnly){
        foreach($control in $dialog.Controls){
            if(!$dialog.ClientRectangle.Contains($control.Bounds)){throw 'Diagnostic privacy control is clipped.'}
            foreach($other in $dialog.Controls){if($other -ne $control -and $control.Bounds.IntersectsWith($other.Bounds)){throw 'Diagnostic privacy controls overlap.'}}
        }
        if($frames.Checked -ne $script:recordPerformance -or $hardware.Checked -ne $script:includeHardware){throw 'Diagnostic preferences were not restored.'}
        Write-Output 'Diagnostic privacy layout and preferences verified; no collection or upload.'
    }elseif($dialog.ShowDialog($form) -eq 'OK'){
        $script:recordPerformance=$frames.Checked;$script:includeHardware=$hardware.Checked
    }
    $dialog.Dispose()
}
$diagnostics=New-Object System.Windows.Forms.Button
$diagnostics.Text='Diagnostics / privacy'
$diagnostics.SetBounds(430,538,204,46)
$diagnostics.FlatStyle='Flat';$diagnostics.BackColor=[System.Drawing.Color]::FromArgb(38,49,46)
$form.Controls.Add($diagnostics)
$diagnostics.Add_Click({Show-MajinDiagnosticsOptions})

# Keep the command reference visible before starting a session.
$guide=New-Object System.Windows.Forms.Panel
$guide.SetBounds(650,150,380,444)
$guide.BackColor=[System.Drawing.Color]::FromArgb(28,40,36)
$form.Controls.Add($guide)
$guideHeading=New-Object System.Windows.Forms.Label
$guideHeading.Text='KEYBOARD + MOUSE'
$guideHeading.SetBounds(16,12,348,26)
$guideHeading.ForeColor=[System.Drawing.Color]::FromArgb(236,225,173)
$guide.Controls.Add($guideHeading)
$rows=@(
    @('WASD','Move (left stick)'),
    @('Mouse / IJKL','Camera (right stick)'),
    @('Space','Jump / confirm (A)'),
    @('Hold Shift','Run / dash (B)'),
    @('E','Interact / back (B)'),
    @('Left mouse','Attack (X)'),
    @('R','Roll (Y)'),
    @('Hold Q','Crouch (LT)'),
    @('Right mouse','Command Majin (RT)'),
    @('F / C','Throw mode (LB) / ability (RB)'),
    @('Arrow keys','D-pad'),
    @('V / Middle mouse','Stick clicks (LS / RS)'),
    @('Enter / Tab','Pause menu / map'),
    @('Esc','Quit confirmation')
)
$y=46
foreach($row in $rows){
    $key=New-Object System.Windows.Forms.Label
    $key.Text=$row[0]; $key.SetBounds(16,$y,145,25)
    $key.ForeColor=[System.Drawing.Color]::FromArgb(236,225,173)
    $guide.Controls.Add($key)
    $action=New-Object System.Windows.Forms.Label
    $action.Text=$row[1]; $action.SetBounds(163,$y,210,25)
    $action.Font=New-Object System.Drawing.Font('Segoe UI',9)
    $guide.Controls.Add($action)
    $y+=25
}
$note=New-Object System.Windows.Forms.Label
$note.Text='Xbox prompts remain in-game. Actions depend on context.'
$note.SetBounds(16,402,348,38)
$note.Font=New-Object System.Drawing.Font('Segoe UI',9)
$guide.Controls.Add($note)

if (Test-Path -LiteralPath $settingsPath) {
    try {
        $saved=Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
        if ($size.Items.Contains([string]$saved.WindowSize)) { $size.SelectedItem=[string]$saved.WindowSize }
        if ($saved.Fullscreen -is [bool]) { $mode.SelectedIndex=[int](-not $saved.Fullscreen) }
        if ($saved.VSync -is [bool]) { $sync.SelectedIndex=[int](-not $saved.VSync) }
        if ($saved.RenderScale -in @(1,2,3)) { $scale.SelectedIndex=[int]$saved.RenderScale-1 }
        if ($has60 -and $saved.FrameRateMode -eq '60') { $frameRate.SelectedIndex=1 }
        if ($saved.RenderingPath -eq 'ROV') { $renderingPath.SelectedIndex=1 }
        if ($saved.PostEffect -eq 'fxaa') { $effect.SelectedIndex=1 }
        if ($saved.RecordPerformance -is [bool]) { $script:recordPerformance=$saved.RecordPerformance }
        if ($saved.IncludeHardware -is [bool]) { $script:includeHardware=$saved.IncludeHardware }
        if ($saved.InputMode -eq 'KeyboardMouse') { $inputMode.SelectedIndex=1 }
        if ($saved.MouseSensitivity -is [ValueType] -and $saved.MouseSensitivity -ge 0.01 -and $saved.MouseSensitivity -le 10) {
            $script:mouseSensitivity=[double]$saved.MouseSensitivity
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show('Saved settings could not be read. Defaults will be used.','Majin') | Out-Null
    }
}
. (Join-Path $PSScriptRoot 'game-data.ps1')
$dataLabel=New-Object System.Windows.Forms.Label
$dataLabel.Text='Game data folder'; $dataLabel.SetBounds(32,610,150,26)
$dataLabel.BackColor=[System.Drawing.Color]::Transparent
$form.Controls.Add($dataLabel)
$dataPath=New-Object System.Windows.Forms.TextBox
$dataPath.SetBounds(187,607,500,28)
try {$dataPath.Text=Get-MajinGameDataPath} catch {$dataPath.Text=''}
$form.Controls.Add($dataPath)
$browse=New-Object System.Windows.Forms.Button
$browse.Text='Browse...'; $browse.SetBounds(703,605,140,32)
$form.Controls.Add($browse)
$browse.Add_Click({
    $dialog=New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description='Select the extracted Majin game folder containing default.xex.'
    $dialog.ShowNewFolderButton=$false
    if(Test-Path -LiteralPath $dataPath.Text -PathType Container){$dialog.SelectedPath=$dataPath.Text}
    try {if($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){$dataPath.Text=$dialog.SelectedPath}}
    finally {$dialog.Dispose()}
})
$import=New-Object System.Windows.Forms.Button
$import.Text='Import ISO...'; $import.SetBounds(853,605,150,32)
$form.Controls.Add($import)
$import.Add_Click({
    $picker=New-Object System.Windows.Forms.OpenFileDialog
    $picker.Title='Select your Xbox 360 disc image'
    $picker.Filter='Xbox 360 disc image (*.iso)|*.iso'
    $disc=$null; $progressWindow=$null
    try {
        if($picker.ShowDialog($form) -ne 'OK'){return}
        . (Join-Path $PSScriptRoot 'disc-import.ps1')
        $form.UseWaitCursor=$true
        $disc=New-Object MajinDisc.Image($picker.FileName)
        $info=$disc.Details
        $details="Title ID: $($info.TitleId)`nMedia ID: $($info.MediaId)`nVersion: $($info.Version)`nAllowed regions: $($info.Regions)`nRegion mask: $($info.RegionMask)`n`nRegion permissions do not identify a retail edition."
        if(!$info.Supported){
            [void][System.Windows.Forms.MessageBox]::Show("$details`n`nThis game/revision is not supported yet. Nothing was imported.",'Unsupported disc')
            return
        }
        $gb=[Math]::Round($info.Bytes/1GB,2)
        if([System.Windows.Forms.MessageBox]::Show("$details`n`nSupported revision. Import $gb GB into the project?`nYour existing saves will be preserved.",'Import ISO','OKCancel') -ne 'OK'){return}
        $progressWindow=New-Object System.Windows.Forms.Form
        $progressWindow.Text='Importing ISO'; $progressWindow.ClientSize=New-Object System.Drawing.Size(440,85)
        $progressWindow.StartPosition='CenterParent'; $progressWindow.ControlBox=$false
        $progressWindow.FormBorderStyle='FixedDialog'
        $bar=New-Object System.Windows.Forms.ProgressBar
        $bar.SetBounds(20,25,400,30); $progressWindow.Controls.Add($bar)
        $progressWindow.Show($form); $form.Enabled=$false
        $progress=[Action[int]]{param($percent) $bar.Value=$percent; [System.Windows.Forms.Application]::DoEvents()}
        $dataPath.Text=Import-MajinDisc -Image $disc -Progress $progress
        [void][System.Windows.Forms.MessageBox]::Show('Import complete. You can now press Play.','Majin')
    } catch {
        [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Unable to import disc')
    } finally {
        if($disc){$disc.Dispose()}
        if($progressWindow){$progressWindow.Close();$progressWindow.Dispose()}
        $form.Enabled=$true; $form.UseWaitCursor=$false; $picker.Dispose()
    }
})
$play=New-Object System.Windows.Forms.Button
$play.Text='Play'; $play.SetBounds(207,538,210,46); $form.Controls.Add($play)
$cancel=New-Object System.Windows.Forms.Button
$cancel.Text='Cancel'; $cancel.SetBounds(32,538,155,46); $form.Controls.Add($cancel)
$play.FlatStyle='Flat'
$play.BackColor=[System.Drawing.Color]::FromArgb(191,165,104)
$play.ForeColor=[System.Drawing.Color]::FromArgb(20,29,28)
$cancel.FlatStyle='Flat'
$cancel.BackColor=[System.Drawing.Color]::FromArgb(38,49,46)
$cancel.Add_Click({$form.Close()})
$form.CancelButton=$cancel
$play.Add_Click({
    try {
        $selectedGameData=Save-MajinGameDataPath -Path $dataPath.Text
        $options=@{Configuration=$Configuration; GameDataRoot=$selectedGameData; WindowSize=[string]$size.SelectedItem; Fullscreen=($mode.SelectedIndex -eq 0);
            VSync=($sync.SelectedIndex -eq 0); RenderScale=($scale.SelectedIndex+1);
            PostEffect=(@('none','fxaa')[$effect.SelectedIndex]);
            FrameRateMode=(@('Original','60')[$frameRate.SelectedIndex]);
            RenderingPath=(@('Default','ROV')[$renderingPath.SelectedIndex]);
            InputMode=(@('Controller','KeyboardMouse')[$inputMode.SelectedIndex]);
            MouseSensitivity=$script:mouseSensitivity;RecordPerformance=$script:recordPerformance;IncludeHardware=$script:includeHardware}
        $folder=Split-Path $settingsPath -Parent
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        $tempPath="$settingsPath.tmp"
        $options | ConvertTo-Json | Set-Content -LiteralPath $tempPath -Encoding UTF8
        Move-Item -LiteralPath $tempPath -Destination $settingsPath -Force
        $form.Hide()
        & (Join-Path $PSScriptRoot 'run.ps1') @options
        $form.Close()
    } catch {
        $form.Show()
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Unable to launch Majin') | Out-Null
    }
})
if ($ValidateOnly) {
    Show-MajinDiagnosticsOptions -ValidateOnly
    if (!$form.BackgroundImage -or !$launcherIcon -or !$launcherLogo) {throw 'Packaged launcher background, logo or icon was not loaded.'}
    Write-Output 'Launcher background, transparent logo and custom icon loaded from relative asset paths.'
    $expectedPath=if($saved -and $saved.RenderingPath -eq 'ROV'){1}else{0}
    if($renderingPath.SelectedIndex -ne $expectedPath){throw 'Saved rendering path was not restored.'}
    $expectedFrame=if($has60 -and $saved -and $saved.FrameRateMode -eq '60'){1}else{0}
    if($frameRate.SelectedIndex -ne $expectedFrame){throw 'Saved frame mode was not restored.'}
    Write-Output ('Restored rendering choice: '+$renderingPath.SelectedItem)
    # Exercise the same callback with the zero-height size reported on the laptop.
    $testBitmap=New-Object System.Drawing.Bitmap(32,32)
    $testGraphics=[System.Drawing.Graphics]::FromImage($testBitmap)
    try {
        foreach($dimensions in @(@(520,0),@(0,670),@(0,0),@(32,32))){
            $testSender=[pscustomobject]@{ClientSize=(New-Object System.Drawing.Size($dimensions[0],$dimensions[1]))}
            & $paintBackground $testSender ([pscustomobject]@{Graphics=$testGraphics})
        }
        Write-Output 'Paint regression passed: zero-height, zero-width, empty and normal client areas.'
    } finally {$testGraphics.Dispose();$testBitmap.Dispose()}
    $form.ShowInTaskbar=$false
    $form.StartPosition='Manual'
    $form.Location=New-Object System.Drawing.Point(-10000,-10000)
    $form.Show()
    $form.CreateControl()
    $form.PerformLayout()
    foreach ($choice in @($size,$mode,$scale,$effect,$sync,$frameRate,$api,$renderingPath,$inputMode,$dataPath,$browse,$import)) {
        foreach ($control in $form.Controls) {
            if ($control -ne $choice -and $control.Bounds.IntersectsWith($choice.Bounds)) {
                throw 'A selection field overlaps another control.'
            }
        }
    }
    $size.SelectedItem='2560x1440'
    $mode.SelectedIndex=1
    $scale.SelectedIndex=1
    $effect.SelectedIndex=1
    $sync.SelectedIndex=1
    $frameRate.SelectedIndex=1
    $inputMode.SelectedIndex=1
    $renderingPath.SelectedIndex=1
    if($renderingPath.SelectedItem -ne 'ROV Compatibility'){throw 'Rendering path selection failed.'}
    if($inputMode.SelectedItem -ne 'Keyboard + mouse (test)'){throw 'Input selection failed.'}
    if ($size.SelectedItem -ne '2560x1440' -or $scale.SelectedIndex -ne 1) { throw 'Selection validation failed.' }
    $bitmap=New-Object System.Drawing.Bitmap($form.Width,$form.Height)
    $form.DrawToBitmap($bitmap,(New-Object System.Drawing.Rectangle(0,0,$form.Width,$form.Height)))
    $bitmap.Save((Join-Path (Split-Path $PSScriptRoot -Parent) 'reports/launcher-preview.png'))
    $bitmap.Dispose()
    Write-Output 'Settings and import controls are unobstructed; editable selections verified. Preview rendered.'
} else {
    [void]$form.ShowDialog()
}
if ($form.BackgroundImage) { $form.BackgroundImage.Dispose() }
$renderTooltip.Dispose()
$form.Dispose()
if ($launcherIcon) { $launcherIcon.Dispose() }
if ($launcherLogo) { $launcherLogo.Dispose() }
