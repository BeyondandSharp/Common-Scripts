Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Xml.Linq

[System.Windows.Forms.Application]::EnableVisualStyles()

# 在系统中查询支持的软件
function QuerySoftware {
    param(
        [string]$softwareListPath
    )

    $softwareList = Get-Content $softwareListPath
}

# 创建主窗体
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Plug-in Manager'
$form.Size = New-Object System.Drawing.Size(100, 100)
$form.AutoSize = $true
$form.StartPosition = 'CenterScreen'

# 创建tableLayoutPanel
$tableLayoutPanelSoftware = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanelSoftware.Dock = [System.Windows.Forms.DockStyle]::Fill
$tableLayoutPanelSoftware.AutoSize = $true
$tableLayoutPanelSoftware.AutoSizeMode = 'GrowAndShrink'
$form.Controls.Add($tableLayoutPanelSoftware)
# 在tableLayoutPanel中添加下拉栏
$comboBoxSoftware = New-Object System.Windows.Forms.ComboBox
$comboBoxSoftware.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList