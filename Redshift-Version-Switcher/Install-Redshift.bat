::管理员权限请求
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

::运行Redshift-Version-Switcher.ps1脚本
Powershell.exe -ExecutionPolicy Bypass -File "%~dp0\Install-Redshift.ps1" %*