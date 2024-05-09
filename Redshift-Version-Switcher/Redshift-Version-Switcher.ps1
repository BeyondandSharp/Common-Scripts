. "$PSScriptRoot\Function.ps1"

# ˢ�º���
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

# ��Ӧ�á���ť����¼��ĺ���
function Invoke-Changes {
    # ���ȫ�ֱ���
    $redshiftVersionsLocal = @()
    $dissZhLocal = @()
    # ��������е�ÿһ��
    for ($i = 1; $i -lt $tableLayoutPanel.RowCount; $i++) {
        $comboBox = $tableLayoutPanel.GetControlFromPosition(3, $i) # 3 �����������ڵ���
        $checkBox = $tableLayoutPanel.GetControlFromPosition(4, $i) # 4 �ǹ�ѡ�����ڵ���
        $redshiftVersionsLocal += $comboBox.SelectedItem
        $dissZhLocal += $checkBox.Checked
        $global:redshiftVersions = $redshiftVersionsLocal
        $global:dissZh = $dissZhLocal
    }

    # �������ļ�д�뵽�û��ĵ���
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
    Write-Log "�����ļ�д�뵽 $configPath\config.json"
    # ������װ�ű�
    . "$PSScriptRoot\Install-Redshift.bat"
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Xml.Linq

[System.Windows.Forms.Application]::EnableVisualStyles()

# ����������
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Redshift�汾�л���'
$form.Size = New-Object System.Drawing.Size(100, 100)
$form.AutoSize = $true
$form.StartPosition = 'CenterScreen'

# ������񲼾�
$tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel.RowCount = 1
$tableLayoutPanel.ColumnCount = 5
$tableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$tableLayoutPanel.AutoSize = $true
$tableLayoutPanel.AutoSizeMode = 'GrowAndShrink'
$form.Controls.Add($tableLayoutPanel)

# �����ı���������ʾ��ϸ��Ϣ������Ϊ��פ�ڴ���ײ�
$detailsTextBox = New-Object System.Windows.Forms.TextBox
$detailsTextBox.Multiline = $true
$detailsTextBox.Dock = [System.Windows.Forms.DockStyle]::Bottom
$detailsTextBox.Height = 100
$detailsTextBox.ReadOnly = $true
$detailsTextBox.ScrollBars = 'Vertical'
$detailsTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($detailsTextBox)

# ��ӡ�ˢ�¡���ť
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "ˢ��"
$refreshButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
$refreshButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$refreshButton.Height = 30
$refreshButton.Add_Click({ Update-GUI })
$form.Controls.Add($refreshButton)

# ��ӡ�Ӧ�á���ť
$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Text = "Ӧ��"
$applyButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
$applyButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$applyButton.Height = 30
$applyButton.Add_Click({ Invoke-Changes })
$form.Controls.Add($applyButton)

# ��ȡ�����ļ�
$config = ConvertFrom-Json (Get-Content -Path "$PSScriptRoot\config.json" -Raw)

# ʹ�������ļ��е�ֵ
$svnUrl = $config.SvnUrl
$redshiftBasePath = $config.redshiftBasePath
$tortoiseSVNInstaller = $config.tortoiseSVNInstaller
$tortoiseSVNBackup = $config.tortoiseSVNBackup
Write-Log "SVN·��Ϊ��$svnUrl"
Write-Log "Redshift����·��Ϊ��$redshiftBasePath"

#����ȫ�ֱ���
$locations = @()
$versions = @()
$names = @()
$redshiftConfigs = @()
$redshiftVersions = @()
$dissZh = @()

# ���TortoiseSVN�Ƿ�װ
if (Invoke-SvnCommand -tortoiseSVNBackup $tortoiseSVNBackup -packagePath $tortoiseSVNInstaller) {
    # ��ʼ������ʾ����
    New-GUI
    $form.ShowDialog()
}
