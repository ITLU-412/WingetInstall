Add-Type -AssemblyName System.Windows.Forms

# Winget frissíthető csomagok lekérése
Write-Host "Winget adatok lekerese..."
$wingetOutput = winget upgrade | Out-String

# Csomagok feldolgozása
$packages = @()
foreach ($line in $wingetOutput -split "`n") {
    if ($line -match "^\s*[^\s]+\s+[^\s]+\s+[^\s]+") {
        $cols = $line -split "\s{2,}"
        if ($cols.Count -ge 3) {
            $packages += [PSCustomObject]@{
                Name = $cols[0].Trim()
                Id = $cols[1].Trim()
                Version = $cols[2].Trim()
            }
        }
    }
}

# Főablak létrehozása
$form = New-Object System.Windows.Forms.Form
$form.Text = "Winget Frissito"
$form.Size = New-Object System.Drawing.Size(700,640)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
$form.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D4D4D4")
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

# Címke hozzáadása
$label = New-Object System.Windows.Forms.Label
$label.Text = "Válassza ki, mely programokat szeretné frissíteni:"
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Size = New-Object System.Drawing.Size(660,40)
$label.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($label)

# Panel a listához
$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(20,80)
$panel.Size = New-Object System.Drawing.Size(660,400)
$panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($panel)

# ListBox hozzáadása a panelhez
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$listBox.Font = New-Object System.Drawing.Font("Consolas",12)
$listBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#252526")
$listBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D4D4D4")
$listBox.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended
$panel.Controls.Add($listBox)

foreach ($package in $packages) {
    $listBox.Items.Add($package.Name)
}

# ProgressBar hozzáadása
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20,500)
$progressBar.Size = New-Object System.Drawing.Size(660,20)
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$form.Controls.Add($progressBar)

# Frissítés gomb hozzáadása
$btnUpdate = New-Object System.Windows.Forms.Button
$btnUpdate.Text = "Frissites inditasa"
$btnUpdate.Location = New-Object System.Drawing.Point(280,530)
$btnUpdate.Size = New-Object System.Drawing.Size(150,40)
$btnUpdate.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$btnUpdate.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#007ACC")
$btnUpdate.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnUpdate)

# Eseménykezelő a gombhoz
$btnUpdate.Add_Click({
    $selectedItems = $listBox.SelectedItems
    if ($selectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Kérlek, válassz ki legalább egy programot!")
        return
    }

    $progressBar.Value = 0
    $progressBar.Maximum = $selectedItems.Count
    foreach ($item in $selectedItems) {
        $package = $packages | Where-Object { $_.Name -eq $item }
        if ($package) {
            Write-Host "Frissítés indítása: $($package.Id)"
            Start-Process -NoNewWindow -Wait -FilePath "winget" -ArgumentList "upgrade --id $($package.Id)"
        }
        $progressBar.PerformStep()
    }

    [System.Windows.Forms.MessageBox]::Show("Frissítés befejezve!")
    $progressBar.Value = 0
})

# Ablak megjelenítése
$form.ShowDialog()
