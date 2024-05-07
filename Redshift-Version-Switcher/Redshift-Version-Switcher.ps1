. "$PSScriptRoot\Function.ps1"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Xml.Linq

[System.Windows.Forms.Application]::EnableVisualStyles()

# 创建主窗体
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Redshift版本切换器'
$form.Size = New-Object System.Drawing.Size(100, 100)
$form.AutoSize = $true
$form.StartPosition = 'CenterScreen'

# 创建表格布局
$tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel.RowCount = 1
$tableLayoutPanel.ColumnCount = 5
$tableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$tableLayoutPanel.AutoSize = $true
$tableLayoutPanel.AutoSizeMode = 'GrowAndShrink'
$form.Controls.Add($tableLayoutPanel)

# 创建文本框用于显示详细信息，调整为常驻在窗体底部
$detailsTextBox = New-Object System.Windows.Forms.TextBox
$detailsTextBox.Multiline = $true
$detailsTextBox.Dock = [System.Windows.Forms.DockStyle]::Bottom
$detailsTextBox.Height = 100
$detailsTextBox.ReadOnly = $true
$detailsTextBox.ScrollBars = 'Vertical'
$detailsTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($detailsTextBox)

# 添加“刷新”按钮
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "刷新"
$refreshButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
$refreshButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$refreshButton.Height = 30
$refreshButton.Add_Click({ Update-GUI })
$form.Controls.Add($refreshButton)

# 添加“应用”按钮
$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Text = "应用"
$applyButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
$applyButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$applyButton.Height = 30
$applyButton.Add_Click({ Invoke-Changes })
$form.Controls.Add($applyButton)

# 读取配置文件
$config = ConvertFrom-Json (Get-Content -Path "config.json" -Raw)

# 使用配置文件中的值
$svnUrl = $config.SvnUrl
$redshiftBasePath = $config.redshiftBasePath
Write-Log "SVN路径为：$svnUrl"
Write-Log "Redshift基础路径为：$redshiftBasePath"

#创建全局变量
$locations = @()
$versions = @()
$names = @()
$redshiftConfigs = @()
$redshiftVersions = @()
$dissZh = @()

# 初始化和显示窗体
New-GUI
$form.ShowDialog()