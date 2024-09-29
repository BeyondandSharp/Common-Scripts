# 日志记录函数，代替 Write-Host
function Write-Log {
    param([string]$script:message)
    $detailsTextBox.AppendText("$message`r`n")
    Write-Host $message
}

# 获取Redshift版本列表的函数
function Get-SvnRedshiftVersions {
    try {
        # 获取 SVN 列表并去除尾部斜线
        $script:svnList = (svn list $svnUrl).Trim() -replace '/', ''
        
        # 将字符串分割为数组，并移除空值
        $script:versionList = $svnList.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
                
        return $versionList
    }
    catch {
        Write-Log "错误：无法从 SVN 获取数据。"
        return @()  # 返回空数组
    }
}

# 将任意版本号缩短到指定位数的函数
function ShortenVersion {
    param (
        [string]$version,
        [int]$length
    )
    # 将版本号拆分为数组
    $versionArray = $version.Split('.')
    # 从数组中取出指定长度的元素
    $versionShort = $versionArray[0..($length - 1)] -join '.'
    write-host "$version 缩短为 $versionShort"
    return $versionShort
}

# 函数用于查找并返回匹配的版本号
function Get-MatchingVersion {
    param (
        [string]$version,
        [object]$object
    )
    # 检查版本号是否在范围内
    foreach ($range in $object.PSObject.Properties) {
        $rangeBoundaries = $range.Name -split ' - '
        $lowerBound = [version]$rangeBoundaries[0]
        $upperBound = [version]$rangeBoundaries[1]
        
        $versionLower = ShortenVersion -version $version -length $rangeBoundaries[0].Split('.').Count
        $versionUpper = ShortenVersion -version $version -length $rangeBoundaries[1].Split('.').Count
        $versionLower = [version]$versionLower
        $versionUpper = [version]$versionUpper

        Write-Host "正在检查 $lowerBound < $versionLower = $versionUpper < $upperBound"
        if ($versionLower -ge $lowerBound -and $versionUpper -le $upperBound) {
            Write-Host "输入的版本号 $versionInput 处于范围 $($range.Name) 内，对应的值为 $($range.Value)"
            $result = $range.Value
            break
        }
    }
    return $result
}

# 将一个数组合并到另一个数组的函数，如果数组为空则不合并
function Merge-Array {
    param (
        [array]$array1,
        [array]$array2
    )
    # 遍历array2并添加到array1
    foreach ($item in $array2) {
        $array1 += $item
    }
    return $array1
}

# 参考数组2，如果其中有空值，则将数组1的对应位置的值替换为空值
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

# 创建GUI的函数
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
        Write-Log "未找到注册表HKLM:\SOFTWARE\Maxon"
    }
    # 3dsMax
    if (Test-Path 'HKLM:\SOFTWARE\Autodesk\3dsMax') {
        $keys_3dsMax = 
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Autodesk\3dsMax' -Recurse | 
        Where-Object { $_.Property -contains 'ProductName' }
        $names_3dsMax = @("3dsMax") * $keys_3dsMax.Length
    }
    else {
        Write-Log "未找到注册表HKLM:\SOFTWARE\Autodesk\3dsMax"
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
        Write-Log "未找到注册表HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    }
    # Houdini
    if (Test-Path 'HKLM:\SOFTWARE\Side Effects Software') {
        $keys_Houdini = 
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Side Effects Software' -Recurse | 
        Where-Object { $_.Property -contains 'Version' }
        $names_Houdini = @("Houdini") * $keys_Houdini.Length
    }
    else {
        Write-Log "未找到注册表HKLM:\SOFTWARE\Side Effects Software"
    }
    # Maya
    if (Test-Path 'HKLM:\SOFTWARE\Autodesk\Maya') {
        $keys_Maya = 
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Autodesk\Maya' -Recurse | 
        Where-Object { $_.Property -contains 'UpdateVersion' }
        $names_Maya = @("Maya") * $keys_Maya.Length
    }
    else {
        Write-Log "未找到注册表HKLM:\SOFTWARE\Autodesk\Maya"
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
    
    Write-Log "找到 $($keys.Length)"
    foreach ($key in $keys) {
        Write-Log $key
    }
    Write-Log "名称 $($names.Length)"
    foreach ($name in $names) {
        Write-Log $name
    }

    $global:names = $names
    if ($keys) {
        $i = 0
        foreach ($key in $keys) {
            $name = $names[$i]
            # 获取安装路径
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
            # 获取版本号
            if ($name -eq "C4D") {
                $version = (Get-ItemProperty $key.PSPath).Version
                # 缩短version
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
                # 如果DisplayVersion不存在则读取安装路径下blender.exe中的版本号
                if (-not $version_) {
                    $version = (Get-Item "$location\blender.exe").VersionInfo.FileVersion
                }
                else {
                    $version = $version_
                }
                # 将$version转换为版本号
                $version = [System.Version]::Parse($version)
                # 查看其中有没有修订号，没有则用0补全
                if ($version.Build -eq -1) {
                    $version = [version]("$version.0")
                }
                # 再转换回字符串
                $version = $version.ToString()
            }
            elseif ($name -eq "Maya") {
                $version = (Get-ItemProperty $key.PSPath).UpdateVersion
            }
            else {
                $version = (Get-ItemProperty $key.PSPath).Version
            }
            # 写入路径与版本到数组中
            $global:locations += $location
            # 写入版本到数组中
            if ($name -eq "Blender") {
                # Blender使用matchVersion
                $blenderVersion = $config.blenderVersion
                $matchVersion = Get-MatchingVersion -version $version -object $blenderVersion
                $global:versions += $matchVersion
            }
            else {
                $global:versions += $version
            }

            # 增加行
            $tableLayoutPanel.RowCount++
            $tableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))

            # 版本号标签
            $labelVersion = New-Object System.Windows.Forms.Label
            $labelVersion.Text = $name + " " + $version
            $labelVersion.AutoSize = $true
            $labelVersion.Padding = New-Object System.Windows.Forms.Padding(0, 7, 0, 0)
            $tableLayoutPanel.Controls.Add($labelVersion, 0, $tableLayoutPanel.RowCount - 1)

            # 路径标签
            $labelPath = New-Object System.Windows.Forms.Label
            $labelPath.Text = "路径: $location"
            $labelPath.AutoSize = $true
            $labelPath.Padding = New-Object System.Windows.Forms.Padding(0, 7, 0, 0)
            $tableLayoutPanel.Controls.Add($labelPath, 1, $tableLayoutPanel.RowCount - 1)
            
            # Redshift版本标签
            $redshiftVersionLabel = New-Object System.Windows.Forms.Label

            # 读取当前Redshift版本信息
            # Cinema 4D
            if ($name -eq "C4D") {
                $redshiftConfigPath = "$location\plugins\Redshift\pathconfig.xml"
                if (Test-Path $redshiftConfigPath) {
                    $pathContent = Get-Content $redshiftConfigPath
                    $pattern = '<path name="REDSHIFT_COREDATAPATH" value="C:\\ProgramData\\redshift\\(\d+\.\d+\.\d+)" />'
                    $pathMatches = $pathContent | Select-String -Pattern $pattern
                    if ($pathMatches) {
                        $currentRedshiftVersion = $pathMatches[0].Matches.Groups[1].Value
                        $redshiftVersionLabel.Text = "当前Redshift版本: $currentRedshiftVersion"
                        Write-Log "$name $version 的Redshift $currentRedshiftVersion 找到"
                    }
                    else {
                        $redshiftVersionLabel.Text = "Redshift配置文件不正确"
                        Write-Log "Redshift配置文件不正确$redshiftConfigPath"
                    }
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift配置文件未找到"
                    Write-Log "找不到$redshiftConfigPath"
                }
            }
            # 3dsMax
            elseif ($name -eq "3dsMax") {
                $redshiftConfigPath = "C:\ProgramData\Autodesk\ApplicationPlugins\Redshift3dsMax$version\PackageContents.xml"
                # 加载 XML 文件
                if (Test-Path $redshiftConfigPath) {
                    [xml]$xml = Get-Content $redshiftConfigPath

                    # 使用 XPath 查询获取 AppVersion 属性值
                    $currentRedshiftVersion = $xml.SelectSingleNode("//ApplicationPackage").AppVersion

                    $redshiftVersionLabel.Text = "当前Redshift版本: $currentRedshiftVersion"
                    Write-Log "$name $version 的Redshift $currentRedshiftVersion 找到"
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift配置文件未找到"
                    Write-Log "找不到$redshiftConfigPath"
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
                        $redshiftVersionLabel.Text = "当前Redshift版本: $currentRedshiftVersion"
                        Write-Log "$name $version 的Redshift $currentRedshiftVersion 找到"
                    }
                    else {
                        $redshiftVersionLabel.Text = "Redshift配置文件不正确"
                        Write-Log "Redshift配置文件不正确$redshiftConfigPath"
                    }
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift配置文件未找到"
                    Write-Log "找不到$redshiftConfigPath"
                }
            }
            # Houdini
            elseif ($name -eq "Houdini") {
                #取Houdini版本号的主版本号与次版本号
                $versionShort = $version -replace '\.\d+$', ''
                #获取当前用户文档的路径
                $userDocPath = [System.Environment]::GetFolderPath('MyDocuments')
                $redshiftConfigPath = "$userDocPath\houdini$versionShort\houdini.env"
                if (Test-Path $redshiftConfigPath) {
                    # 读取文件内容
                    $content = Get-Content -Path $redshiftConfigPath -Raw
                    # 转换为数组
                    $contentArrary = $content -split "`n"
                    $pattern = "REDSHIFT_COREDATAPATH = *"
                    $line = $contentArrary -like $pattern
                    if ($null -ne $line) {
                        $lineArrary = $line -split '/'
                        $currentRedshiftVersion = $lineArrary[-1]
                        $redshiftVersionLabel.Text = "当前Redshift版本: $currentRedshiftVersion"
                        Write-Log "$name $version 的Redshift $currentRedshiftVersion 找到"
                    }
                    else {
                        $redshiftVersionLabel.Text = "Redshift配置文件不正确"
                        Write-Log "Redshift配置文件不正确$redshiftConfigPath"
                    }
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift配置文件未找到"
                    Write-Log "找不到$redshiftConfigPath"
                }
            }
            # Maya
            elseif ($name -eq "Maya") {
                $userDocPath = [System.Environment]::GetFolderPath('MyDocuments')
                $redshiftConfigPath = "$userDocPath\maya\$version\Maya.env"
                if (Test-Path $redshiftConfigPath) {
                    $line = Select-String -Path $redshiftConfigPath -Pattern 'REDSHIFT_COREDATAPATH = '
                    if ($line) {
                        # line用\分隔为数组
                        $lineArrary = $line -split '\\'
                        # 取最后一个元素
                        $currentRedshiftVersion = $lineArrary[-1]
                        $redshiftVersionLabel.Text = "当前Redshift版本: $currentRedshiftVersion"
                        Write-Log "$name $version 的Redshift $currentRedshiftVersion 找到"
                    }
                    else {
                        $redshiftVersionLabel.Text = "Redshift配置文件不正确"
                        Write-Log "Redshift配置文件不正确$redshiftConfigPath"
                    }
                }
                else {
                    $redshiftVersionLabel.Text = "Redshift配置文件未找到"
                    Write-Log "$name $version 的Redshift配置文件未找到"
                }
            }
            # 添加路径到数组中
            $global:redshiftConfigs += $redshiftConfigPath

            $redshiftVersionLabel.AutoSize = $true
            # 文字下移7个像素
            $redshiftVersionLabel.Padding = New-Object System.Windows.Forms.Padding(0, 7, 0, 0)
            $tableLayoutPanel.Controls.Add($redshiftVersionLabel, 2, $tableLayoutPanel.RowCount - 1)

            # Redshift版本下拉框
            $comboBox = New-Object System.Windows.Forms.ComboBox
            $comboBox.Dock = [System.Windows.Forms.DockStyle]::Fill
            $tableLayoutPanel.Controls.Add($comboBox, 3, $tableLayoutPanel.RowCount - 1)
            # 添加下拉框选项
            $redshiftVersions = Get-SvnRedshiftVersions
            $comboBox.Items.Add("不修改")
            foreach ($redshiftVersion in $redshiftVersions) {
                $testVersion = $version
                if ($name -eq "C4D") {
                    #如果version开头没有R，则添加
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
                        Write-Host "找到 $svnUrl/$redshiftVersion/Plugins/$name/$testVersion"
                        $comboBox.Items.Add($redshiftVersion)
                    }
                }
            }
            $comboBox.SelectedIndex = 0

            # 去汉化的勾选框
            $checkBox = New-Object System.Windows.Forms.CheckBox
            $checkBox.Text = "去汉化"
            $checkBox.AutoSize = $true
            $tableLayoutPanel.Controls.Add($checkBox, 4, $tableLayoutPanel.RowCount - 1)
            $checkBox.Checked = $true
            # 除C4D外其他软件不支持去汉化
            if ($name -ne "C4D") {
                $checkBox.Checked = $false
                $checkBox.Enabled = $false
            }
            else {
                #检查是否已经去汉化
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
        $label.Text = "未找到任何支持的软件，或者出了其他奇奇怪怪的问题"
        $label.AutoSize = $true
        $tableLayoutPanel.Controls.Add($label, 0, 0)
        $tableLayoutPanel.SetColumnSpan($label, 4)
    }
}

# 对比参考文件夹和目标文件夹的文件
function Compare-Folders {
    param(
        [string]$sourcePath,
        [string]$destinationPath
    )
    $sourcePathFiles = Get-ChildItem -Recurse -Path $sourcePath
    $destinationPathFiles = Get-ChildItem -Recurse -Path $destinationPath
    $differences = Compare-Object $sourcePathFiles $destinationPathFiles -Property Name, Length
    # 输出destinationPath中不存在的文件
    $i = 0
    foreach ($difference in $differences) {
        if ($difference.SideIndicator -eq "<=") {
            Write-Host "文件 $($difference.Name) 不存在"
            $i++
        }
    }
    return $i
}

# 汉化切换
function Switch-RedshiftZh {
    param(
        [string]$location,
        [bool]$switcher)
    $zhPath = "$location\plugins\Redshift\res\strings_zh-CN"
    $zhPathBackup = "$location\plugins\Redshift\res\strings_zh-CN_backup"
    if ($switcher -eq $true) {
        Write-Host "去汉化$location"
        # 备份原文件夹
        if (-not (Test-Path $zhPathBackup)) {
            Copy-Item -Recurse -Force $zhPath $zhPathBackup
            if (Test-Path $zhPathBackup) {
                # 删除原文件夹
                Remove-Item -Recurse -Force $zhPath
                if (-not (Test-Path $zhPath)) {
                    # 复制英文文件夹为中文文件夹
                    Copy-Item -Recurse -Force "$location\plugins\Redshift\res\strings_en-US" $zhPath
                }                
            }
        }
        else {
            Write-Host "已经去汉化了的说"
        }        
    }
    else {
        Write-Host "恢复汉化$location"
        # 恢复原文件夹
        if (Test-Path $zhPathBackup){
            Copy-Item -Recurse -Force $zhPathBackup $zhPath
            Remove-Item -Recurse -Force $zhPathBackup
        }
        else {
            Write-Host "已经是汉化了的说"
        }
    }
}

# 查询content中是否有匹配的字符串，没有就添加该字符串
function Add-ContentNotFind {
    param(
        [string[]]$contentArrary,
        [string]$pattern,
        [string]$addContent
    )
    Write-Host "查找 $addContent"
    if ($contentArrary -contains $addContent -eq $false) {
        Write-Host "添加 $addContent"
        $contentArrary += $addContent
    }
    return $contentArrary
}


# 安装Redshift
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
    Write-Host "安装Redshift $redshiftVersion 到 $software $version"
    if ($software -eq "C4D") {
        #检查version前是否有“R”，没有则添加
        if ($version -notlike "R*") {
            $version = "R$version"
        }
        #检查location是否存在，不存在则创建
        if (-not (Test-Path "$location\plugins")) {
            New-Item -ItemType Directory -Path "$location\plugins"
        }
        Set-Location "$redshiftBasePath\$redshiftVersion\Plugins\C4D"
        # 删除$location\plugins\Redshift文件夹
        Write-Host "删除 $location\plugins\Redshift"
        Remove-Item -Recurse -Force "$location\plugins\Redshift"
        #管理员身份运行脚本bat
        .\install_c4d.bat "$version" "$location\plugins"
        #写入新的pathconfig.xml
        $pathConfig = "<path name=`"REDSHIFT_COREDATAPATH`" value=`"$redshiftBasePath\$redshiftVersion`" />"
        Write-host "写入新的$redshiftConfigPath"
        $pathConfig | Set-Content "$location\plugins\Redshift\pathconfig.xml"
        # 验证安装是否成功
        $sourcePath = "$redshiftBasePath\$redshiftVersion\Plugins\C4D\$version\Redshift"
        $destinationPath = "$location\plugins\Redshift"
        $differences = Compare-Folders -sourcePath $sourcePath -destinationPath $destinationPath
        if ($differences -eq 0) {
            Write-Host "验证通过，没问题哒"
        }
        else {
            Write-Host "验证失败，有问题哒"
        }
    }
    # 3dsMax
    elseif ($software -eq "3dsMax") {
        Set-Location "$redshiftBasePath\$redshiftVersion\Plugins\3dsMax"
        #运行bat并在运行后自动关闭
        Start-Process -FilePath "install_redshift4max_$version.bat" -Verb RunAs -Wait
    }
    # Blender
    elseif ($software -eq "Blender") {
        Set-Location "$redshiftBasePath\$redshiftVersion\Plugins\Blender"
        # 删除location后的斜杠
        $location = $location.TrimEnd("\")
        # 将location转换位斜杠分隔的数组
        $locationArray = $location.Split("\")
        $versionShort = [regex]::Match($locationArray[-1], "\d+\.\d+")
        #$addonsPath = "$location\$($versionShort.Value)\scripts\addons"
        # 新版Blender好像不支持在安装目录下安装插件
        $addonsPath = "$env:APPDATA\Blender Foundation\Blender\$($versionShort.Value)\scripts\addons"
        # 删除旧版本
        Write-Host "删除旧版本"
        Remove-Item -Recurse -Force "$addonsPath\redshift"
        # 解压缩redshift4blender.zip到Blender安装路径下的插件目录
        Write-Host "解压缩 $redshiftBasePath\$redshiftVersion\Plugins\Blender\$version\redshift4blender.zip"
        Write-Host "到 $addonsPath"
        Expand-Archive -Path "$version\redshift4blender.zip" -DestinationPath $addonsPath
        # 找到__init__.py文件
        $initPath = "$addonsPath\redshift\__init__.py"
        # 读取文件内容
        $content = Get-Content $initPath
        # 替换REDSHIFT_ROOT = None为REDSHIFT_ROOT = Noneos.environ['REDSHIFT_COREDATAPATH'] = "C:/ProgramData/redshift/3.5.24"
        $redshiftCoreDataPath = "$redshiftBasePath/$redshiftVersion"
        # 替换\为/
        $redshiftCoreDataPath = $redshiftCoreDataPath -replace "\\", "/"
        $content = $content -replace "REDSHIFT_ROOT = None", "REDSHIFT_ROOT = None`nos.environ['REDSHIFT_COREDATAPATH'] = `"$redshiftCoreDataPath`""
        # 写入文件
        $content | Set-Content $initPath
    }
    # Houdini
    elseif ($software -eq "Houdini") {
        # 读取文件并保留所有格式
        Write-Host "读取 $redshiftConfigPath"
        $content = Get-Content -Path $redshiftConfigPath -Raw
        $contentArrary = $content -split "`n"
        # 查找其中是否有REDSHIFT_COREDATAPATH = "$Programdata/redshift/$redshiftVersion",如果有就替换版本号，没有就添加
        $pattern = "REDSHIFT_COREDATAPATH = *"
        $addContent = "REDSHIFT_COREDATAPATH = `$Programdata/redshift/$redshiftVersion"
        # 遍历数组并替换或添加
        $i = 0
        foreach ($line in $contentArrary) {
            if ($line -match $pattern) {
                Write-Host "找到 $line"
                $contentArrary[$i] = $addContent
                break
            }
            $i++
        }
        # 如果没有找到就添加
        if ($i -eq $contentArrary.Length) {
            Write-Host "添加 $addContent"
            $contentArrary += $addContent
        }
        # 查询并添加其他行
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "HOUDINI_DSO_ERROR = 2"
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "REDSHIFT_LOCALDATAPATH = `$REDSHIFT_COREDATAPATH"
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "PATH = `$REDSHIFT_LOCALDATAPATH/bin;`$PATH"
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "HOUDINI_PATH = `$HOUDINI_PATH;`$REDSHIFT_LOCALDATAPATH/Plugins/Houdini/`${HOUDINI_VERSION}"
        $contentArrary = Add-ContentNotFind -content $contentArrary -addContent "PXR_PLUGINPATH_NAME = `$REDSHIFT_LOCALDATAPATH/Plugins/Solaris/`${HOUDINI_VERSION}"
        # 最后一个元素若为空就删除
        if ($contentArrary[-1] -eq "") {
            $contentArrary = $contentArrary[0..($contentArrary.Length - 2)]
        }
        # contentArrary转换为字符串
        $content = $contentArrary -join "`n"
        # 使用.net重新写入
        Write-Host "写入 $redshiftConfigPath"
        Write-Host $content
        [System.IO.File]::WriteAllLines($redshiftConfigPath, $content)
    }
    # Maya
    elseif ($software -eq "Maya") {
        Set-Location "$redshiftBasePath\$redshiftVersion\Plugins\Maya"
        #运行bat
        Start-Process -FilePath "install_redshift4maya_$version-64.bat" -Verb RunAs -Wait
    }
    else {
        Write-Host "未知软件"
    }
}
# 安装TortoiseSVN
function Invoke-SvnCommand {
    param(
        [string]$tortoiseSVNBackup,
        [string]$packagePath
    )
    $svn = Get-Command svn -ErrorAction SilentlyContinue
    if (-not $svn) {
        # 询问用户是否手动安装TortoiseSVN，是就运行安装程序
        $install = [System.Windows.Forms.MessageBox]::Show("未找到svn命令，是否手动安装TortoiseSVN`n不装也可以临时用一下，但是装了更快更稳定捏。", "提示", [System.Windows.Forms.MessageBoxButtons]::YesNo)
        if ($install -eq "Yes") {
            [System.Windows.Forms.MessageBox]::Show("安装时请注意勾选commond line client tools`n如果已安装就选Modify来修改", "提示", [System.Windows.Forms.MessageBoxButtons]::OK)
            # 查找packagePath下最新的开头为TortoiseSVN的文件
            $packageName = Get-ChildItem -Path $packagePath -Filter "TortoiseSVN*.msi" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
            Write-Log "安装 $packagePath\$packageName"
            Start-Process -FilePath "$packagePath\$packageName" -Wait
            # 更新环境变量
        }
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $svn = Get-Command svn -ErrorAction SilentlyContinue
        if (-not $svn) {
            # 在环境变量path中加入tortoiseSVNBackup
            Write-Log "尝试加入备用SVN到环境变量"
            $env:Path += ";$tortoiseSVNBackup"
            $svn = Get-Command svn -ErrorAction SilentlyContinue
            if (-not $svn) {
                Write-Log "未找到svn命令"
                [System.Windows.Forms.MessageBox]::Show("未找到svn命令，请手动安装TortoiseSVN并勾选commond line client tools", "提示", [System.Windows.Forms.MessageBoxButtons]::OK)
                exit
            }
        }
    }
    return $svn
}
