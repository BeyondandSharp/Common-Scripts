# ��־��¼���������� Write-Host
function Write-Log {
    param([string]$script:message)
    $detailsTextBox.AppendText("$message`r`n")
    Write-Host $message
}

# ��ȡRedshift�汾�б�ĺ���
function Get-SvnRedshiftVersions {
    try {
        # ��ȡ SVN �б�ȥ��β��б��
        $script:svnList = (svn list $svnUrl).Trim() -replace '/', ''
        
        # ���ַ����ָ�Ϊ���飬���Ƴ���ֵ
        $script:versionList = $svnList.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
                
        return $versionList
    }
    catch {
        Write-Log "�����޷��� SVN ��ȡ���ݡ�"
        return @()  # ���ؿ�����
    }
}

# ������汾�����̵�ָ��λ���ĺ���
function ShortenVersion {
    param (
        [string]$version,
        [int]$length
    )
    # ���汾�Ų��Ϊ����
    $versionArray = $version.Split('.')
    # ��������ȡ��ָ�����ȵ�Ԫ��
    $versionShort = $versionArray[0..($length - 1)] -join '.'
    write-host "$version ����Ϊ $versionShort"
    return $versionShort
}

# �������ڲ��Ҳ�����ƥ��İ汾��
function Get-MatchingVersion {
    param (
        [string]$version,
        [object]$object
    )
    # ���汾���Ƿ��ڷ�Χ��
    foreach ($range in $object.PSObject.Properties) {
        $rangeBoundaries = $range.Name -split ' - '
        $lowerBound = [version]$rangeBoundaries[0]
        $upperBound = [version]$rangeBoundaries[1]
        
        $versionLower = ShortenVersion -version $version -length $rangeBoundaries[0].Split('.').Count
        $versionUpper = ShortenVersion -version $version -length $rangeBoundaries[1].Split('.').Count
        $versionLower = [version]$versionLower
        $versionUpper = [version]$versionUpper

        Write-Host "���ڼ�� $lowerBound < $versionLower = $versionUpper < $upperBound"
        if ($versionLower -ge $lowerBound -and $versionUpper -le $upperBound) {
            Write-Host "����İ汾�� $versionInput ���ڷ�Χ $($range.Name) �ڣ���Ӧ��ֵΪ $($range.Value)"
            $result = $range.Value
            break
        }
    }
    return $result
}

# ��һ������ϲ�����һ������ĺ������������Ϊ���򲻺ϲ�
function Merge-Array {
    param (
        [array]$array1,
        [array]$array2
    )
    # ����array2����ӵ�array1
    foreach ($item in $array2) {
        $array1 += $item
    }
    return $array1
}

# �ο�����2����������п�ֵ��������1�Ķ�Ӧλ�õ�ֵ�滻Ϊ��ֵ
function Set-EmptyValue {
    param (
        [array]$array1,
        [array]$array2
    )
    $i = 0
    foreach ($item in $array2) {
        if ($item -eq "") {
            $array1[$i] = ""
        }
        $i++
    }
    return $array1
}

# ����GUI�ĺ���
function New-GUI {
    $keys = @()
    $keys_C4D = @()
    $keys_3dsMax = @()
    $keys_Blender = @()
    $keys_Houdini = @()
    $keys_Maya = @()
    $keysEmpty = @()
    $namesEmpty = @()

    # C4D
    if (Test-Path 'HKLM:\SOFTWARE\Maxon') {
        $keys_C4D = 
        Get-ChildItem 'HKLM:\SOFTWARE\Maxon' -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -match 'Cinema 4D' }
        $names_C4D = @("C4D") * $keys_C4D.Length
    }
    else {
        Write-Log "δ�ҵ�ע���HKLM:\SOFTWARE\Maxon"
    }
    # 3dsMax
    if (Test-Path 'HKLM:\SOFTWARE\Autodesk\3dsMax') {
        $keys_3dsMax = 
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Autodesk\3dsMax' -Recurse | 
        Where-Object { $_.Property -contains 'ProductName' }
        $names_3dsMax = @("3dsMax") * $keys_3dsMax.Length
    }
    else {
        Write-Log "δ�ҵ�ע���HKLM:\SOFTWARE\Autodesk\3dsMax"
    }
    # Blender
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall') {
        $keys_Blender = 
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -Recurse | 
        Where-Object { $_.Property -contains 'DisplayName' } | 
        Where-Object { $_.GetValue('DisplayName') -match 'blender' }
        $names_Blender = @("Blender") * $keys_Blender.Length
    }
    else {
        Write-Log "δ�ҵ�ע���HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    }
    # Houdini
    if (Test-Path 'HKLM:\SOFTWARE\Side Effects Software') {
        $keys_Houdini = 
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Side Effects Software' -Recurse | 
        Where-Object { $_.Property -contains 'Version' }
        $names_Houdini = @("Houdini") * $keys_Houdini.Length
    }
    else {
        Write-Log "δ�ҵ�ע���HKLM:\SOFTWARE\Side Effects Software"
    }
    # Maya
    if (Test-Path 'HKLM:\SOFTWARE\Autodesk\Maya') {
        $keys_Maya = 
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Autodesk\Maya' -Recurse | 
        Where-Object { $_.Property -contains 'UpdateVersion' }
        $names_Maya = @("Maya") * $keys_Maya.Length
    }
    else {
        Write-Log "δ�ҵ�ע���HKLM:\SOFTWARE\Autodesk\Maya"
    }
    
    #$keys = $keys_C4D + $keys_3dsMax + $keys_Blender + $keys_Houdini + $keys_Maya
    #$names = $names_C4D + $names_3dsMax + $names_Blender + $names_Houdini + $names_Maya
    
    $namesEmpty = Merge-Array -array1 $namesEmpty -array2 $names_C4D
    $namesEmpty = Merge-Array -array1 $namesEmpty -array2 $names_3dsMax
    $namesEmpty = Merge-Array -array1 $namesEmpty -array2 $names_Blender
    $namesEmpty = Merge-Array -array1 $namesEmpty -array2 $names_Houdini
    $namesEmpty = Merge-Array -array1 $namesEmpty -array2 $names_Maya

    $keysEmpty = Merge-Array -array1 $keysEmpty -array2 $keys_C4D
    $keysEmpty = Merge-Array -array1 $keysEmpty -array2 $keys_3dsMax
    $keysEmpty = Merge-Array -array1 $keysEmpty -array2 $keys_Blender
    $keysEmpty = Merge-Array -array1 $keysEmpty -array2 $keys_Houdini
    $keysEmpty = Merge-Array -array1 $keysEmpty -array2 $keys_Maya

    $keys = Set-EmptyValue -array1 $keysEmpty -array2 $namesEmpty
    $names = Set-EmptyValue -array1 $namesEmpty -array2 $keysEmpty

    $keys = $keys | Where-Object { $_ -ne "" }
    $names = $names | Where-Object { $_ -ne "" }
    
    Write-Log "�ҵ� $($keys.Length)"
    foreach ($key in $keys) {
        Write-Log $key
    }
    Write-Log "���� $($names.Length)"
    foreach ($name in $names) {
        Write-Log $name
    }

    $global:names = $names
    if ($keys) {
        $i = 0
        foreach ($key in $keys) {
            $name = $names[$i]
            # ��ȡ��װ·��
            if ($name -eq "C4D" -or $name -eq "3dsMax") {
                $location = (Get-ItemProperty $key.PSPath).Location
            }
            elseif ($name -eq "Blender") {
                $location = (Get-ItemProperty $key.PSPath).InstallLocation
            }
            elseif ($name -eq "Houdini") {
                $location = (Get-ItemProperty $key.PSPath).InstallPath
            }
            elseif ($name -eq "Maya") {
                $path = Join-Path -Path $key.PSPath -ChildPath "Setup\InstallPath"
                $location = (Get-ItemProperty $path).MAYA_INSTALL_LOCATION
            }
            else {
                $location = (Get-ItemProperty $key.PSPath).Location
            }
            # ��ȡ�汾��
            if ($name -eq "C4D") {
                $version = (Get-ItemProperty $key.PSPath).Version
                # ����version
                $version = ShortenVersion -version $version -length 1
            }
            elseif ($name -eq "Houdini") {
                $version = (Get-ItemProperty $key.PSPath).Version
            }
            elseif ($name -eq "3dsMax") {
                $version_ = (Get-ItemProperty $key.PSPath).ProductName -split " "
                $version = $version_[-1]
            }
            elseif ($name -eq "Blender") {
                $version_ = (Get-ItemProperty $key.PSPath).DisplayVersion
                # ���DisplayVersion���������ȡ��װ·����blender.exe�еİ汾��
                if (-not $version_) {
                    $version = (Get-Item "$location\blender.exe").VersionInfo.FileVersion
                }
                else {
                    $version = $version_
                }
                # ��$versionת��Ϊ�汾��
                $version = [System.Version]::Parse($version)
                # �鿴������û���޶��ţ�û������0��ȫ
                if ($version.Build -eq -1) {
                    $version = [version]("$version.0")
                }
                # ��ת�����ַ���
                $version = $version.ToString()
            }
            elseif ($name -eq "Maya") {
                $version = (Get-ItemProperty $key.PSPath).UpdateVersion
            }
            else {
                $version = (Get-ItemProperty $key.PSPath).Version
            }
            # д��·����汾��������
            $global:locations += $location
            # д��汾��������
            if ($name -eq "Blender") {
                # Blenderʹ��matchVersion
                $blenderVersion = $config.blenderVersion
                $matchVersion = Get-MatchingVersion -version $version -object $blenderVersion
                $global:versions += $matchVersion
            }
            else {
                $global:versions += $version
            }

            # ������
            $tableLayoutPanel.RowCount++
            $tableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))

            # �汾�ű�ǩ
            $labelVersion = New-Object System.Windows.Forms.Label
            $labelVersion.Text = $name + " " + $version
            $labelVersion.AutoSize = $true
            $labelVersion.Padding = New-Object System.Windows.Forms.Padding(0, 7, 0, 0)
            $tableLayoutPanel.Controls.Add($labelVersion, 0, $tableLayoutPanel.RowCount - 1)

            # ·����ǩ
            $labelPath = New-Object System.Windows.Forms.Label
            $labelPath.Text = "·��: $location"
            $labelPath.AutoSize = $true
            $labelPath.Padding = New-Object System.Windows.Forms.Padding(0, 7, 0, 0)
            $tableLayoutPanel.Controls.Add($labelPath, 1, $tableLayoutPanel.RowCount - 1)
            
            # Redshift�汾��ǩ
            $redshiftVersionLabel = New-Object System.Windows.Forms.Label

            # ��ȡ��ǰRedshift�汾��Ϣ
            # Cinema 4D
            if ($name -eq "C4D") {
                $redshiftConfigPath = "$location\plugins\Redshift\pathconfig.xml"
                if (Test-Path $redshiftConfigPath) {
                    $pathContent = Get-Content $redshiftConfigPath
                    $pattern = '<path name="REDSHIFT_COREDATAPATH" value="C:\\ProgramData\\redshift\\(\d+\.\d+\.\d+)" />'
                    $pathMatches = $pathContent | Select-String -Pattern $pattern
                    if ($pathMatches) {
                        $currentRedshiftVersion = $pathMatches[0].Matches.Groups[1].Value
                        $redshiftVersionLabel.Text = "��ǰRedshift�汾: $currentRedshiftVersion"
                        Write-Log "$name $version ��Redshift $currentRedshiftVersion �ҵ�"
                    }
                    else {
                        $redshiftVersionLabel.Text = "Redshift�����ļ�����ȷ"
                        Write-Log "Redshift�����ļ�����ȷ$redshiftConfigPath"
                    }
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift�����ļ�δ�ҵ�"
                    Write-Log "�Ҳ���$redshiftConfigPath"
                }
            }
            # 3dsMax
            elseif ($name -eq "3dsMax") {
                $redshiftConfigPath = "C:\ProgramData\Autodesk\ApplicationPlugins\Redshift3dsMax$version\PackageContents.xml"
                # ���� XML �ļ�
                if (Test-Path $redshiftConfigPath) {
                    [xml]$xml = Get-Content $redshiftConfigPath

                    # ʹ�� XPath ��ѯ��ȡ AppVersion ����ֵ
                    $currentRedshiftVersion = $xml.SelectSingleNode("//ApplicationPackage").AppVersion

                    $redshiftVersionLabel.Text = "��ǰRedshift�汾: $currentRedshiftVersion"
                    Write-Log "$name $version ��Redshift $currentRedshiftVersion �ҵ�"
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift�����ļ�δ�ҵ�"
                    Write-Log "�Ҳ���$redshiftConfigPath"
                }
            }
            # Blender
            elseif ($name -eq "Blender") {
                $versionShort = $version -replace "\.\d+$", ""
                $redshiftConfigPath = "$location$versionShort\scripts\addons\redshift\__init__.py"
                if (Test-Path $redshiftConfigPath) {
                    $pathContent = Get-Content $redshiftConfigPath -Raw
                    $pattern = "os\.environ\['REDSHIFT_COREDATAPATH'\] = ""C:/ProgramData/redshift/([0-9]+\.[0-9]+\.[0-9]+)"""
                    if ($pathContent -match $pattern) {
                        $currentRedshiftVersion = $matches[1]
                        $redshiftVersionLabel.Text = "��ǰRedshift�汾: $currentRedshiftVersion"
                        Write-Log "$name $version ��Redshift $currentRedshiftVersion �ҵ�"
                    }
                    else {
                        $redshiftVersionLabel.Text = "Redshift�����ļ�����ȷ"
                        Write-Log "Redshift�����ļ�����ȷ$redshiftConfigPath"
                    }
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift�����ļ�δ�ҵ�"
                    Write-Log "�Ҳ���$redshiftConfigPath"
                }
            }
            # Houdini
            elseif ($name -eq "Houdini") {
                #ȡHoudini�汾�ŵ����汾����ΰ汾��
                $versionShort = $version -replace '\.\d+$', ''
                #��ȡ��ǰ�û��ĵ���·��
                $userDocPath = [System.Environment]::GetFolderPath('MyDocuments')
                $redshiftConfigPath = "$userDocPath\houdini$versionShort\houdini.env"
                if (Test-Path $redshiftConfigPath) {
                    # ��ȡ�ļ�����
                    $content = Get-Content -Path $redshiftConfigPath -Raw
                    # ת��Ϊ����
                    $contentArrary = $content -split "`n"
                    $pattern = "REDSHIFT_COREDATAPATH = *"
                    $line = $contentArrary -like $pattern
                    if ($null -ne $line) {
                        $lineArrary = $line -split '/'
                        $currentRedshiftVersion = $lineArrary[-1]
                        $redshiftVersionLabel.Text = "��ǰRedshift�汾: $currentRedshiftVersion"
                        Write-Log "$name $version ��Redshift $currentRedshiftVersion �ҵ�"
                    }
                    else {
                        $redshiftVersionLabel.Text = "Redshift�����ļ�����ȷ"
                        Write-Log "Redshift�����ļ�����ȷ$redshiftConfigPath"
                    }
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift�����ļ�δ�ҵ�"
                    Write-Log "�Ҳ���$redshiftConfigPath"
                }
            }
            # Maya
            elseif ($name -eq "Maya") {
                $userDocPath = [System.Environment]::GetFolderPath('MyDocuments')
                $redshiftConfigPath = "$userDocPath\maya\$version\Maya.env"
                if (Test-Path $redshiftConfigPath) {
                    $line = Select-String -Path $redshiftConfigPath -Pattern 'REDSHIFT_COREDATAPATH = '
                    if ($line) {
                        # line��\�ָ�Ϊ����
                        $lineArrary = $line -split '\\'
                        # ȡ���һ��Ԫ��
                        $currentRedshiftVersion = $lineArrary[-1]
                        $redshiftVersionLabel.Text = "��ǰRedshift�汾: $currentRedshiftVersion"
                        Write-Log "$name $version ��Redshift $currentRedshiftVersion �ҵ�"
                    }
                    else {
                        $redshiftVersionLabel.Text = "Redshift�����ļ�����ȷ"
                        Write-Log "Redshift�����ļ�����ȷ$redshiftConfigPath"
                    }
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift�����ļ�δ�ҵ�"
                    Write-Log "$name $version ��Redshift�����ļ�δ�ҵ�"
                }
            }
            # ���·����������
            $global:redshiftConfigs += $redshiftConfigPath

            $redshiftVersionLabel.AutoSize = $true
            # ��������7������
            $redshiftVersionLabel.Padding = New-Object System.Windows.Forms.Padding(0, 7, 0, 0)
            $tableLayoutPanel.Controls.Add($redshiftVersionLabel, 2, $tableLayoutPanel.RowCount - 1)

            # Redshift�汾������
            $comboBox = New-Object System.Windows.Forms.ComboBox
            $comboBox.Dock = [System.Windows.Forms.DockStyle]::Fill
            $tableLayoutPanel.Controls.Add($comboBox, 3, $tableLayoutPanel.RowCount - 1)
            # ���������ѡ��
            $redshiftVersions = Get-SvnRedshiftVersions
            $comboBox.Items.Add("���޸�")
            foreach ($redshiftVersion in $redshiftVersions) {
                $testVersion = $version
                if ($name -eq "C4D") {
                    #���version��ͷû��R�������
                    if ($testVersion -notlike "R*") {
                        $testVersion = "R$testVersion"
                    }                    
                }
                elseif ($name -eq "Blender") {
                    $blenderVersion = $config.blenderVersion
                    $testVersion = $matchVersion
                }
                if ($null -ne $testVersion) {
                    if (svn list $svnUrl/$redshiftVersion/Plugins/$name/$testVersion) {
                        Write-Host "�ҵ� $svnUrl/$redshiftVersion/Plugins/$name/$testVersion"
                        $comboBox.Items.Add($redshiftVersion)
                    }
                }
            }
            $comboBox.SelectedIndex = 0

            # ȥ�����Ĺ�ѡ��
            $checkBox = New-Object System.Windows.Forms.CheckBox
            $checkBox.Text = "ȥ����"
            $checkBox.AutoSize = $true
            $tableLayoutPanel.Controls.Add($checkBox, 4, $tableLayoutPanel.RowCount - 1)
            $checkBox.Checked = $true
            # ��C4D�����������֧��ȥ����
            if ($name -ne "C4D") {
                $checkBox.Checked = $false
                $checkBox.Enabled = $false
            }
            else {
                #����Ƿ��Ѿ�ȥ����
                if (Test-Path "$location\plugins\Redshift\res\strings_zh-CN_backup") {
                    $checkBox.Checked = $true
                }
                else {
                    $checkBox.Checked = $false
                }
            }

            $i += 1
        }
    }
    else {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "δ�ҵ��κ�֧�ֵ���������߳�����������ֵֹ�����"
        $label.AutoSize = $true
        $tableLayoutPanel.Controls.Add($label, 0, 0)
        $tableLayoutPanel.SetColumnSpan($label, 4)
    }
}

# �ԱȲο��ļ��к�Ŀ���ļ��е��ļ�
function Compare-Folders {
    param(
        [string]$sourcePath,
        [string]$destinationPath
    )
    $sourcePathFiles = Get-ChildItem -Recurse -Path $sourcePath
    $destinationPathFiles = Get-ChildItem -Recurse -Path $destinationPath
    $differences = Compare-Object $sourcePathFiles $destinationPathFiles -Property Name, Length
    # ���destinationPath�в����ڵ��ļ�
    $i = 0
    foreach ($difference in $differences) {
        if ($difference.SideIndicator -eq "<=") {
            Write-Host "�ļ� $($difference.Name) ������"
            $i++
        }
    }
    return $i
}

# �����л�
function Switch-RedshiftZh {
    param(
        [string]$location,
        [bool]$switcher)
    $zhPath = "$location\plugins\Redshift\res\strings_zh-CN"
    $zhPathBackup = "$location\plugins\Redshift\res\strings_zh-CN_backup"
    if ($switcher -eq $true) {
        Write-Host "ȥ����$location"
        # ����ԭ�ļ���
        if (-not (Test-Path $zhPathBackup)) {
            Copy-Item -Recurse -Force $zhPath $zhPathBackup
            if (Test-Path $zhPathBackup) {
                # ɾ��ԭ�ļ���
                Remove-Item -Recurse -Force $zhPath
                if (-not (Test-Path $zhPath)) {
                    # ����Ӣ���ļ���Ϊ�����ļ���
                    Copy-Item -Recurse -Force "$location\plugins\Redshift\res\strings_en-US" $zhPath
                }                
            }
        }
        else {
            Write-Host "�Ѿ�ȥ�����˵�˵"
        }        
    }
    else {
        Write-Host "�ָ�����$location"
        # �ָ�ԭ�ļ���
        if (Test-Path $zhPathBackup){
            Copy-Item -Recurse -Force $zhPathBackup $zhPath
            Remove-Item -Recurse -Force $zhPathBackup
        }
        else {
            Write-Host "�Ѿ��Ǻ����˵�˵"
        }
    }
}

# ��ѯcontent���Ƿ���ƥ����ַ�����û�о���Ӹ��ַ���
function Add-ContentNotFind {
    param(
        [string[]]$contentArrary,
        [string]$pattern,
        [string]$addContent
    )
    Write-Host "���� $addContent"
    if ($contentArrary -contains $addContent -eq $false) {
        Write-Host "��� $addContent"
        $contentArrary += $addContent
    }
    return $contentArrary
}


# ��װRedshift
function Install-Redshift {
    param(
        [string]$svnUrl,
        [string]$redshiftBasePath,
        [string]$software,
        [string]$version,
        [string]$redshiftVersion,
        [string]$redshiftConfigPath,
        [string]$location
    )
    # Cinema 4D
    Write-Host "��װRedshift $redshiftVersion �� $software $version"
    if ($software -eq "C4D") {
        #���versionǰ�Ƿ��С�R����û�������
        if ($version -notlike "R*") {
            $version = "R$version"
        }
        #���location�Ƿ���ڣ��������򴴽�
        if (-not (Test-Path "$location\plugins")) {
            New-Item -ItemType Directory -Path "$location\plugins"
        }
        Set-Location "$redshiftBasePath\$redshiftVersion\Plugins\C4D"
        # ɾ��$location\plugins\Redshift�ļ���
        Write-Host "ɾ�� $location\plugins\Redshift"
        Remove-Item -Recurse -Force "$location\plugins\Redshift"
        #����Ա������нű�bat
        .\install_c4d.bat "$version" "$location\plugins"
        #д���µ�pathconfig.xml
        $pathConfig = "<path name=`"REDSHIFT_COREDATAPATH`" value=`"$redshiftBasePath\$redshiftVersion`" />"
        Write-host "д���µ�$redshiftConfigPath"
        $pathConfig | Set-Content "$location\plugins\Redshift\pathconfig.xml"
        # ��֤��װ�Ƿ�ɹ�
        $sourcePath = "$redshiftBasePath\$redshiftVersion\Plugins\C4D\$version\Redshift"
        $destinationPath = "$location\plugins\Redshift"
        $differences = Compare-Folders -sourcePath $sourcePath -destinationPath $destinationPath
        if ($differences -eq 0) {
            Write-Host "��֤ͨ����û������"
        }
        else {
            Write-Host "��֤ʧ�ܣ���������"
        }
    }
    # 3dsMax
    elseif ($software -eq "3dsMax") {
        Set-Location "$redshiftBasePath\$redshiftVersion\Plugins\3dsMax"
        #����bat�������к��Զ��ر�
        Start-Process -FilePath "install_redshift4max_$version.bat" -Verb RunAs -Wait
    }
    # Blender
    elseif ($software -eq "Blender") {
        Set-Location "$redshiftBasePath\$redshiftVersion\Plugins\Blender"
        # ɾ��location���б��
        $location = $location.TrimEnd("\")
        # ��locationת��λб�ָܷ�������
        $locationArray = $location.Split("\")
        $versionShort = [regex]::Match($locationArray[-1], "\d+\.\d+")
        #$addonsPath = "$location\$($versionShort.Value)\scripts\addons"
        # �°�Blender����֧���ڰ�װĿ¼�°�װ���
        $addonsPath = "$env:APPDATA\Blender Foundation\Blender\$($versionShort.Value)\scripts\addons"
        # ɾ���ɰ汾
        Write-Host "ɾ���ɰ汾"
        Remove-Item -Recurse -Force "$addonsPath\redshift"
        # ��ѹ��redshift4blender.zip��Blender��װ·���µĲ��Ŀ¼
        Write-Host "��ѹ�� $redshiftBasePath\$redshiftVersion\Plugins\Blender\$version\redshift4blender.zip"
        Write-Host "�� $addonsPath"
        Expand-Archive -Path "$version\redshift4blender.zip" -DestinationPath $addonsPath
        # �ҵ�__init__.py�ļ�
        $initPath = "$addonsPath\redshift\__init__.py"
        # ��ȡ�ļ�����
        $content = Get-Content $initPath
        # �滻REDSHIFT_ROOT = NoneΪREDSHIFT_ROOT = Noneos.environ['REDSHIFT_COREDATAPATH'] = "C:/ProgramData/redshift/3.5.24"
        $redshiftCoreDataPath = "$redshiftBasePath/$redshiftVersion"
        # �滻\Ϊ/
        $redshiftCoreDataPath = $redshiftCoreDataPath -replace "\\", "/"
        $content = $content -replace "REDSHIFT_ROOT = None", "REDSHIFT_ROOT = None`nos.environ['REDSHIFT_COREDATAPATH'] = `"$redshiftCoreDataPath`""
        # д���ļ�
        $content | Set-Content $initPath
    }
    # Houdini
    elseif ($software -eq "Houdini") {
        # ��ȡ�ļ����������и�ʽ
        Write-Host "��ȡ $redshiftConfigPath"
        $content = Get-Content -Path $redshiftConfigPath -Raw
        $contentArrary = $content -split "`n"
        # ���������Ƿ���REDSHIFT_COREDATAPATH = "$Programdata/redshift/$redshiftVersion",����о��滻�汾�ţ�û�о����
        $pattern = "REDSHIFT_COREDATAPATH = *"
        $addContent = "REDSHIFT_COREDATAPATH = `$Programdata/redshift/$redshiftVersion"
        # �������鲢�滻�����
        $i = 0
        foreach ($line in $contentArrary) {
            if ($line -match $pattern) {
                Write-Host "�ҵ� $line"
                $contentArrary[$i] = $addContent
                break
            }
            $i++
        }
        # ���û���ҵ������
        if ($i -eq $contentArrary.Length) {
            Write-Host "��� $addContent"
            $contentArrary += $addContent
        }
        # ��ѯ�����������
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "HOUDINI_DSO_ERROR = 2"
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "REDSHIFT_LOCALDATAPATH = `$REDSHIFT_COREDATAPATH"
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "PATH = `$REDSHIFT_LOCALDATAPATH/bin;`$PATH"
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "HOUDINI_PATH = `$HOUDINI_PATH;`$REDSHIFT_LOCALDATAPATH/Plugins/Houdini/`${HOUDINI_VERSION}"
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "PXR_PLUGINPATH_NAME = `$REDSHIFT_LOCALDATAPATH/Plugins/Solaris/`${HOUDINI_VERSION}"
        # ���һ��Ԫ����Ϊ�վ�ɾ��
        if ($contentArrary[-1] -eq "") {
            $contentArrary = $contentArrary[0..($contentArrary.Length - 2)]
        }
        # contentArraryת��Ϊ�ַ���
        $content = $contentArrary -join "`n"
        # ʹ��.net����д��
        Write-Host "д�� $redshiftConfigPath"
        Write-Host $content
        [System.IO.File]::WriteAllLines($redshiftConfigPath, $content)
    }
    # Maya
    elseif ($software -eq "Maya") {
        Set-Location "$redshiftBasePath\$redshiftVersion\Plugins\Maya"
        #����bat
        Start-Process -FilePath "install_redshift4maya_$version-64.bat" -Verb RunAs -Wait
    }
    else {
        Write-Host "δ֪���"
    }
}
# ��װTortoiseSVN
function Invoke-SvnCommand {
    param(
        [string]$tortoiseSVNBackup,
        [string]$packagePath
    )
    $svn = Get-Command svn -ErrorAction SilentlyContinue
    if (-not $svn) {
        # ѯ���û��Ƿ��ֶ���װTortoiseSVN���Ǿ����а�װ����
        $install = [System.Windows.Forms.MessageBox]::Show("δ�ҵ�svn����Ƿ��ֶ���װTortoiseSVN`n��װҲ������ʱ��һ�£�����װ�˸�����ȶ���", "��ʾ", [System.Windows.Forms.MessageBoxButtons]::YesNo)
        if ($install -eq "Yes") {
            [System.Windows.Forms.MessageBox]::Show("��װʱ��ע�⹴ѡcommond line client tools`n����Ѱ�װ��ѡModify���޸�", "��ʾ", [System.Windows.Forms.MessageBoxButtons]::OK)
            # ����packagePath�����µĿ�ͷΪTortoiseSVN���ļ�
            $packageName = Get-ChildItem -Path $packagePath -Filter "TortoiseSVN*.msi" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
            Write-Log "��װ $packagePath\$packageName"
            Start-Process -FilePath "$packagePath\$packageName" -Wait
            # ���»�������
        }
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $svn = Get-Command svn -ErrorAction SilentlyContinue
        if (-not $svn) {
            # �ڻ�������path�м���tortoiseSVNBackup
            Write-Log "���Լ��뱸��SVN����������"
            $env:Path += ";$tortoiseSVNBackup"
            $svn = Get-Command svn -ErrorAction SilentlyContinue
            if (-not $svn) {
                Write-Log "δ�ҵ�svn����"
                [System.Windows.Forms.MessageBox]::Show("δ�ҵ�svn������ֶ���װTortoiseSVN����ѡcommond line client tools", "��ʾ", [System.Windows.Forms.MessageBoxButtons]::OK)
                exit
            }
        }
    }
    return $svn
}
