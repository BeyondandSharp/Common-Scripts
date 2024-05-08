# ����Function.ps1
. "$PSScriptRoot\Function.ps1"

# ��鵱ǰ�û��Ƿ�Ϊ����Ա
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ������ǹ���Ա�����Թ���Ա������������ű�
if (-not $isAdmin) {
    Start-Process powershell.exe "-File $PSCommandPath" -Verb RunAs
    exit
}

#��ȡ�û��ĵ�·��
$userDocPath = [System.Environment]::GetFolderPath("MyDocuments")
#��json�ļ��ж�ȡ����
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
$path = $config.path

Write-Host "���Redshift�汾�С�"
# ����Ƿ���svn
$svn = Get-Command svn -ErrorAction SilentlyContinue
if (-not $svn) {
    $env:Path = $path
}
# ɾ��$redshiftVersion���ظ���Ԫ��
$redshiftVersions2Checkout = $redshiftVersions | Select-Object -Unique
$redshiftVersions2Checkout = $redshiftVersions2Checkout | Where-Object {$_ -ne "���޸�"}
# ʹ��svn checkout redshiftVersions2Checkout�����еİ汾
foreach ($redshiftVersion in $redshiftVersions2Checkout) {
    svn checkout "$svnUrl/$redshiftVersion" "$redshiftBasePath\$redshiftVersion" 
}
Write-Host "���Redshift�汾����"

$i = 0
foreach ($redshiftVersion in $redshiftVersions) {
    # ��װ
    if($redshiftVersion -ne "���޸�") {
        Install-Redshift `
            -svnUrl $svnUrl `
            -redshiftBasePath $redshiftBasePath `
            -software $names[$i] `
            -version $versions[$i] `
            -location $locations[$i] `
            -redshiftVersion $redshiftVersion `
            -redshiftConfigPath $redshiftConfigs[$i]
    }
    # �����л�
    if($names[$i] -eq "C4D") {
        Switch-RedshiftZh -location $locations[$i] -switcher $dissZh[$i]
    }
    $i += 1
}

Write-Host "Redshift�汾�л���ɣ�"
pause