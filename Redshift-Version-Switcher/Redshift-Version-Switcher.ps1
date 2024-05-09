. "$PSScriptRoot\Function.ps1"

# 刷新函数
function Update-GUI {
    $tableLayoutPanel.Controls.Clear()
    $tableLayoutPanel.RowCount = 1
    $tableLayoutPanel.RowStyles.Clear()
    $global:locations = @()
    $global:versions = @()
    $global:names = @()
    $global:redshiftConfigs = @()
    $global:redshiftVersions = @()
    $global:dissZh = @()
    New-GUI
}

# “应用”按钮点击事件的函数
function Invoke-Changes {
    # 清空全局变量
    $redshiftVersionsLocal = @()
    $dissZhLocal = @()
    # 遍历表格中的每一行
    for ($i = 1; $i -lt $tableLayoutPanel.RowCount; $i++) {
        $comboBox = $tableLayoutPanel.GetControlFromPosition(3, $i) # 3 是下拉框所在的列
        $checkBox = $tableLayoutPanel.GetControlFromPosition(4, $i) # 4 是勾选框所在的列
        $redshiftVersionsLocal += $comboBox.SelectedItem
        $dissZhLocal += $checkBox.Checked
        $global:redshiftVersions = $redshiftVersionsLocal
        $global:dissZh = $dissZhLocal
    }

    # 将配置文件写入到用户文档中
    $config = @{
        svnUrl           = $svnUrl
        redshiftBasePath = $redshiftBasePath
        names            = $names
        versions         = $versions
        locations        = $locations
        redshiftConfigs  = $redshiftConfigs
        redshiftVersions = $redshiftVersions
        dissZh           = $dissZh
        path             = $env:Path
    } | ConvertTo-Json
    $userDocPath = [System.Environment]::GetFolderPath("MyDocuments")
    $configPath = "$userDocPath" + "\Redshift-Version-Switcher"
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType Directory -Path $configPath
    }
    $config | Set-Content -Path "$configPath\config.json"
    Write-Log "配置文件写入到 $configPath\config.json"
    # 启动安装脚本
    . "$PSScriptRoot\Install-Redshift.bat"
}

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
$config = ConvertFrom-Json (Get-Content -Path "$PSScriptRoot\config.json" -Raw)

# 使用配置文件中的值
$svnUrl = $config.SvnUrl
$redshiftBasePath = $config.redshiftBasePath
$tortoiseSVNInstaller = $config.tortoiseSVNInstaller
$tortoiseSVNBackup = $config.tortoiseSVNBackup
Write-Log "SVN路径为：$svnUrl"
Write-Log "Redshift基础路径为：$redshiftBasePath"

#创建全局变量
$locations = @()
$versions = @()
$names = @()
$redshiftConfigs = @()
$redshiftVersions = @()
$dissZh = @()

# 检查TortoiseSVN是否安装
if (Invoke-SvnCommand -tortoiseSVNBackup $tortoiseSVNBackup -packagePath $tortoiseSVNInstaller) {
    # 初始化和显示窗体
    New-GUI
    $form.ShowDialog()
}
