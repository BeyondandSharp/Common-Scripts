@chcp 65001
@ECHO 辣鸡清理脚本2.1.1
@ECHO 编写者:FCH
@ECHO.

::管理员权限请求
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

::检测是否以管理员身份运行
@net.exe session 1>NUL 2>NUL && ( @set _isadmin_=1) || ( @set _isadmin_=0 )
@if %_isadmin_%==0 @echo 程序当前不是以以管理员身份运行，一些文件可能无法被清理，请右键以管理员身份运行 & @pause

:_choice
@ECHO ===========================请选择要清理的文件===========================
@ECHO.
@set /p _choice_=0、退出  1、Adobe全家桶的缓存与临时文件  2、着色器缓存（D3D与Nvidia）  3、UE缓存  4、Unity缓存  5、Maxon全家桶的缓存，临时文件与CrashDump  6、Maya缓存  7、其他  8、以上所有呱啊啊啊啊:

@if %_choice_%==0 @echo 清理已被用户取消 & @pause & exit

@set _local_=%UserProfile%\AppData\Local
@set _tmpc_=%UserProfile%\AppData\Local\Temp
@set _roaming_=%UserProfile%\AppData\Roaming

%SystemDrive%

@if %_choice_%==1 @call:_adobeClean & @pause & @goto _choice
@if %_choice_%==2 @call:_shaderClean & @pause & @goto _choice
@if %_choice_%==3 @call:_UEClean & @pause & @goto _choice
@if %_choice_%==4 @call:_unityClean & @pause & @goto _choice
@if %_choice_%==5 @call:_maxonClean & @pause & @goto _choice
@if %_choice_%==6 @call:_mayaClean & @pause & @goto _choice
@if %_choice_%==7 @call:_otherClean & @pause & @goto _choice
@if %_choice_%==8 (
@call:_adobeClean
@call:_shaderClean
@call:_UEClean
@call:_unityClean
@call:_maxonClean
@call:_mayaClean
@call:_otherClean
@pause & @goto _choice
)


::Function
:_adobeClean
@echo 开始清理Adobe全家桶的缓存与临时文件
cd %_tmpc_%
@call:_adobeTmpClean
cd %Temp%
@call:_adobeTmpClean
cd %_roaming_%
for /d %%i in (Adobe Photoshop*\AutoRecover) do rd /s/q "%%i"
rd /s/q "Adobe Substance 3D Sampler\renderCache"
for /d %%i in (After Effects\*\Cache) do rd /s/q "%%i"
rd /s/q "Adobe\Logs"
rd /s/q "Adobe\Common\Media Cache"
rd /s/q "Adobe\Common\Media Cache Files"
rd /s/q "Adobe\Common\Team Projects Cache"
rd /s/q "Allegorithmic\Adobe Substance 3D Sampler\assetsBackup"
rd /s/q "Allegorithmic\Adobe Substance 3D Sampler\renderCache"
rd /s/q "Allegorithmic\Adobe Substance 3D Sampler\thumbnailCache"
rd /s/q "Allegorithmic\Substance Painter\previews"
@echo Adobe全家桶的缓存与临时文件清理结束
@goto:eof
:_adobeTmpClean
rd /s/q "Adobe Substance 3D Sampler"
rd /s/q "Adobe"
del /q "ai*.tmp"
del /q "Photoshop Temp*"
@goto:eof

:_shaderClean
@echo 开始清理着色器缓存（D3D与Nvidia）
cd %_local_%
rd /s/q "D3DSCache"
rd /s/q "NVIDIA\DXCache"
rd /s/q "NVIDIA\GLCache"
rd /s/q "NVIDIA\OptixCache"
cd %_roaming_%
rd /s/q "NVIDIA\ComputeCache"
rd /s/q "NVIDIA\NukeComputeCache"
rd /s/q "NVIDIA\OptixCache"
@echo 着色器缓存（D3D与Nvidia）清理结束
@goto:eof

:_UEClean
@echo 开始清理UE缓存
cd %programdata%
rd /s/q "Epic\EpicGamesLauncher\VaultCache"
cd %_local_%
rd /s/q "UnrealEngine\Common\DerivedDataCache"
cd %_tmpc_%
call:_UETmpClean
cd %Temp%
call:_UETmpClean
@echo UE缓存清理结束
@goto:eof
:_UETmpClean
rd /s/q "UnrealShaderWorkingDir"
@goto:eof

:_unityClean
@echo 开始清理Unity缓存
cd %_local_%
rd /s/q "Unity\cache"
rd /s/q "Unity\Caches\GiCache"
@echo Unity缓存清理结束
@goto:eof

:_maxonClean
@echo 开始清理Maxon全家桶的缓存，临时文件与CrashDump
cd %_local_%
rd /s/q "Redshift\Cache"
cd %_tmpc_%
call:_maxonTmpClean
cd %Temp%
call:_maxonTmpClean
cd %_roaming_%
for /d %%i in (MAXON\_assetcache\MaxonAssets.db_*) do rd /s/q "%%i"
for /d %%i in (MAXON\*\derived.cache) do rd /s/q "%%i"
for /d %%i in (MAXON\*\prefs\cache) do rd /s/q "%%i"
for /d %%i in (MAXON\*\备份) do rd /s/q "%%i"
for /d %%i in (MAXON\*\backup) do rd /s/q "%%i"
for /d %%i in (MAXON\*\Redshift\Cache) do rd /s/q "%%i"
rd %REDSHIFT_CACHEPATH%
rd %REDSHIFT_TEXTURECACHEBUDGET%
::others
rd /s/q "C:\cache"
@echo Maxon全家桶的缓存，临时文件与CrashDump清理结束
@goto:eof
:_maxonTmpClean
rd /s/q "Redshift\Cache"
@goto:eof

:_mayaClean
@echo 开始清理Maya缓存
cd %_tmpc_%
call:_mayaTmpClean
cd %Temp%
call:_mayaTmpClean
@echo Maya缓存清理结束
@goto:eof
:_mayaTmpClean
rd /s/q ".mayaSwatches"
for /d %%i in (maya3dPaint_*) do rd /s/q "%%i"
for /d %%i in (mayaDiskCache_*) do rd /s/q "%%i"
for /d %%i in (mayaGreasePencil_*) do rd /s/q "%%i"
@goto:eof

:_otherClean
@echo 开始清理其他
cd %programdata%
rd /s/q "Package Cache"
cd %_local_%
rd /s/q "cache"
for /d %%i in (*-updater) do rd /s/q "%%i"
rd /s/q "CrashDumps"
rd /s/q "Downloaded Installations"
rd /s/q "Package Cache"
cd %_tmpc_%
call:_otherTmpClean
cd %Temp%
call:_otherTmpClean
cd %_roaming_%
rd /s/q "XneoSoftUpgrade"
::其他位置
del /q "C:\Users\Public\Documents\ZBrushData2022\QuickSave\*.ZPR"
@echo 其他清理结束
@goto:eof
:_otherTmpClean
rd /s/q "nuke"
rd /s/q "PotUpdate"
for /d %%i in (Quixel\Quixel Mixer\*Cache) do rd /s/q "%%i"
rd /s/q "snapshots"
rd /s/q "TeamViewer"
rd /s/q "Thunder"
rd /s/q "VS\Setup"
rd /s/q "XLLiveUD"
rd /s/q "Xunlei"
rd /s/q "odis_download_dest"
rd /s/q "houdini_temp"
rd /s/q "ThunderInstall"
del /q *.7z
del /q *.ico
del /q *.jpeg
del /q *.jpg
del /q *.mp4
del /q *.png
del /q *.exe
del /q *.zip
del /q *.blend
@goto:eof

