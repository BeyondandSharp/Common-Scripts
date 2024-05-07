# 导入Function.ps1
. "$PSScriptRoot\Function.ps1"

# 检查当前用户是否为管理员
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# 如果不是管理员，则以管理员身份重新启动脚本
if (-not $isAdmin) {
    Start-Process powershell.exe "-File $PSCommandPath" -Verb RunAs
    exit
}

$temp = [System.IO.Path]::GetTempPath()

#获取用户文档路径
$userDocPath = [System.Environment]::GetFolderPath("MyDocuments")
#从json文件中读取参数
$config = Get-Content "$userDocPath\Redshift-Version-Switcher\config.json" | ConvertFrom-Json

$svnUrl = $config.svnUrl
$redshiftBasePath = $config.redshiftBasePath

$locations = @()
$versions = @()
$names = @()
$redshiftConfigs = @()
$redshiftVersions = @()
$dissZh = @()

$names = $config.names
$versions = $config.versions
$locations = $config.locations
$redshiftConfigs = $config.redshiftConfigs
$redshiftVersions = $config.redshiftVersions
$dissZh = $config.dissZh

$i = 0
foreach ($redshiftVersion in $redshiftVersions) {
    # 安装
    if($redshiftVersion -ne "不修改") {
        Install-Redshift `
            -svnUrl $svnUrl `
            -redshiftBasePath $redshiftBasePath `
            -software $names[$i] `
            -version $versions[$i] `
            -location $locations[$i] `
            -redshiftVersion $redshiftVersion `
            -redshiftConfigPath $redshiftConfigs[$i]
    }
    # 汉化切换
    if($names[$i] -eq "C4D") {
        Switch-RedshiftZh -location $locations[$i] -switcher $dissZh[$i]
    }
    $i += 1
}

pause