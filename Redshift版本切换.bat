::todo:
::渲染器选择


@echo off
chcp 65001
ECHO Redshift版本切换1.1.4
ECHO 编写者:FCH
ECHO 支持C4D，Houdini，Maya

::管理员权限请求
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

::检测是否以管理员身份运行
net.exe session 1>NUL 2>NUL && ( set _isadmin_=1) || ( set _isadmin_=0 )
if %_isadmin_%==0 echo 程序当前不是以管理员身份运行，请右键以管理员身份运行 & pause & exit

setlocal EnableDelayedExpansion


::setvarible
set "rs_path=\\192.168.0.253\mcs\Resource\安装包\redshift\zero-install"
set "rsLoc=%ProgramData%\redshift"
set "r4CPath=%ProgramData%\redshift"
set "r4HPath=%ProgramData%\redshift"

:begin
::检查软件是否存在
set hasC4D=0
set hasHoudini=0
set hasMaya=0
call:c4dCheck
call:houdiniCheck
call:mayaCheck
::从注册表提取软件版本列表
:loop
set "i=0"
if %hasC4D%==1 call:c4dRegExtract
if %hasHoudini%==1 call:houdiniRegExtract
if %hasMaya%==1 call:mayaRegExtract
set /a i+=1
set "vers[%i%]=All"
set "types[%i%]=All"
::用户选择软件版本
call:choiceSoftwareVer
::选择渲染器
call:rendererChoice
::提取对应渲染器与版本
call:rendererVerExtract
call:choiceRendererVer
::去汉化
set tmpa=0
if %_type%==All set /a tmpa+=1
if %_type%==C4D set /a tmpa+=1
if %_typeR%==Redshift set /a tmpa+=1
if %tmpa%==2 call:dezh
::开始安装
call:mainInstall
echo 安装结束
echo 可以关闭在下了
goto:loop


:c4dCheck
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Maxon" /s /f "Maxon Cinema 4D" /k 1>nul
if %errorlevel%==1 (
    echo 找不到C4D
) else (
    echo 找到了C4D
    set hasC4D=1
)
goto:eof
:houdiniCheck
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Side Effects Software" /s /v /f "ActiveVersion" /e 1>nul
if %errorlevel%==1 (
    echo 找不到Houdini
) else (
    echo 找到了Houdini
    set hasHoudini=1
)
goto:eof
:mayaCheck
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Autodesk\Maya" /s /v /f "release" /e 1>nul
if %errorlevel%==1 (
    echo 找不到Maya
) else (
    echo 找到了Maya
    set hasMaya=1
)
goto:eof
:c4dRegExtract
set /a c4dV1=i+1
for /f "tokens=4*" %%a in ('reg query HKEY_LOCAL_MACHINE\SOFTWARE\Maxon /s /f "Maxon Cinema 4D" /k ^| findstr /i "Maxon Cinema 4D"') do (
    set /a i+=1
    set "vers[!i!]=%%a"
    set "types[!i!]=C4D"
)
set /a i+=1
set "vers[%i%]=All"
set "types[%i%]=C4D"
goto:eof
:houdiniRegExtract
set /a houdiniV1=i+1
for /f "tokens=3*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Side Effects Software" /s /v /f "ActiveVersion" /e ^| findstr /i "Version"') do (
    set /a i+=1
    set "vers[!i!]=%%a"
    set "types[!i!]=Houdini"
)
set /a i+=1
set "vers[%i%]=All"
set "types[%i%]=Houdini"
goto:eof
:mayaRegExtract
set /a mayaV1=i+1
for /f "tokens=3*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Autodesk\Maya" /s /v /f "release" /e ^| findstr /i "release"') do (
    set /a i+=1
    set "vers[!i!]=%%a"
    set "types[!i!]=Maya"
)
set /a i+=1
set "vers[%i%]=All"
set "types[%i%]=Maya"
goto:eof
:choiceSoftwareVer
echo 选择软件与版本:
for /l %%a in (1,1,%i%) do (
    echo [%%a] !types[%%a]! !vers[%%a]!
)
set /p _s="输入数字以选择: "
set "_type=!types[%_s%]!"
set "_ver=!vers[%_s%]!"
if not defined _type echo 错误，请重新选择 & goto choiceSoftwareVer
echo 选择了 %_type% %_ver%
goto:eof
:rendererChoice
::渲染器临时列表
set _typesR[1]=Redshift
echo [1] !_typesR[1]!
set /p _sR="输入数字以选择: "
if not defined _typesR[%_sR%] echo 错误，请重新选择 & goto rendererChoice
set _typeR=!_typesR[%_sR%]!
goto:eof
:rendererVerExtract
echo 正在提取渲染器版本
set j=0
set l=0
if "%_type%"=="C4D" call:c4dRenderVerExtract
if "%_type%"=="Houdini" call:houdiniRenderVerExtract
if "%_type%"=="Maya" call:mayaRenderVerExtract
if %_type%==All (
    call:c4dRenderVerExtract
    call:houdiniRenderVerExtract
    call:mayaRenderVerExtract
)
if !vers[%_s%]!==All call:setIntersection
echo 渲染器版本提取结束
goto:eof
:c4dRenderVerExtract
echo 正在提取C4D渲染器版本
if !vers[%_s%]!==All (
    call:c4dRenderVerExtractAll
) else (
    call:c4dRenderVerExtractSingle
)
echo C4D渲染器版本提取结束
goto:eof
:c4dRenderVerExtractAll
set k=%c4dV1%
:c4dRenderVerExtractAllLoop
set /a l+=1
set _ver=!vers[%k%]!
call:addR !vers[%k%]!
for /d %%a in (%rs_path%\*) do (
    if exist %rs_path%\%%~nxa\Redshift\Plugins\C4D\%R_ver% (
        set /a j+=1
        set rendererVersLists[%l%]=!rendererVersLists[%l%]! %%~nxa
    )
)
set /a k+=1
if not !vers[%k%]!==All goto c4dRenderVerExtractAllLoop
goto:eof
:c4dRenderVerExtractSingle
call:addR !vers[%_s%]!
for /d %%a in (%rs_path%\*) do (
    if exist %rs_path%\%%~nxa\Redshift\Plugins\C4D\%R_ver% (
        set /a j+=1
        set rendererVers[!j!]=%%~nxa
    )
)
goto:eof
:houdiniRenderVerExtract
echo 正在提取Houdini渲染器版本
if !vers[%_s%]!==All (
    call:houdiniRenderVerExtractAll
) else (
    call:houdiniRenderVerExtractSingle
)
echo Houdini渲染器版本提取结束
goto:eof
:houdiniRenderVerExtractAll
set k=%houdiniV1%
:houdiniRenderVerExtractAllLoop
set /a l+=1
set _ver=!vers[%k%]!
for /d %%a in (%rs_path%\*) do (
    if exist %rs_path%\%%~nxa\Redshift\Plugins\Houdini\%_ver% (
        set /a j+=1
        set rendererVersLists[%l%]=!rendererVersLists[%l%]! %%~nxa
    )
)
set /a k+=1
if not !vers[%k%]!==All goto houdiniRenderVerExtractAllLoop
goto:eof
:houdiniRenderVerExtractSingle
for /d %%a in (%rs_path%\*) do (
    if exist %rs_path%\%%~nxa\Redshift\Plugins\Houdini\%_ver% (
        set /a j+=1
        set rendererVers[!j!]=%%~nxa
    )
)
goto:eof
:mayaRenderVerExtract
echo 正在提取Maya渲染器版本
if !vers[%_s%]!==All (
    call:mayaRenderVerExtractAll
) else (
    call:mayaRenderVerExtractSingle
)
echo Maya渲染器版本提取结束
goto:eof
:mayaRenderVerExtractAll
set k=%mayaV1%
:mayaRenderVerExtractAllLoop
set /a l+=1
set _ver=!vers[%k%]!
for /d %%a in (%rs_path%\*) do (
    if exist %rs_path%\%%~nxa\Redshift\Plugins\Maya\%_ver% (
        set /a j+=1
        set rendererVersLists[%l%]=!rendererVersLists[%l%]! %%~nxa
    )
)
set /a k+=1
if not !vers[%k%]!==All goto mayaRenderVerExtractAllLoop
goto:eof
:mayaRenderVerExtractSingle
for /d %%a in (%rs_path%\*) do (
    if exist %rs_path%\%%~nxa\Redshift\Plugins\Maya\%_ver% (
        set /a j+=1
        set rendererVers[!j!]=%%~nxa
    )
)
goto:eof
:setIntersection
echo 渲染器版本求交中
set a=1
:setIntersectionLoop
if not defined rendererVersLists[%a%] (
    set /a a+=1
    goto setIntersectionLoop
)
set /a b=%a%+1
set j=1
set i=1
for %%a in (!rendererVersLists[%a%]!) do (
    set rendererVersList[!i!]=%%a
    set /a i+=1
)
set i=1
:setIntersectionLoop1
set c=!rendererVersList[%i%]!
set /a i+=1
for /l %%d in (%b%,1,%l%) do (
    echo "!rendererVersLists[%%d]!" | findstr /c:"%c%" 1>nul
    if not !errorlevel!==0 (
        goto matchFailed
    )
)
set rendererVers[!j!]=%c%
set /a j+=1
:matchFailed
if defined rendererVersList[%i%] goto setIntersectionLoop1
set /a j+=-1
echo 渲染器版本求交结束
goto:eof
:choiceRendererVer
if %j%==0 (
    echo 没有找到匹配版本，将回到开始
    pause
    goto begin
)
echo 选择渲染器版本
for /l %%a in (1,1,%j%) do (
    echo [%%a] %_typeR% !rendererVers[%%a]!
)
set /p _s="输入数字以选择: "
set "_verR=!rendererVers[%_s%]!"
if not defined _typeR echo 错误，请重新选择 & goto choiceRendererVer
echo 选择了 %_typeR% %_verR%
goto:eof
:dezh
set "isen=2"
echo 是否使用英语Redshift
choice /M "使用英语按 Y，否按 N"
set isen=%errorlevel%
if %isen%==1 (echo 使用英语
) else (echo 使用中文)
goto:eof
:mainInstall
if "%_typeR%"=="Redshift" call:rsInstall
if "%_type%"=="C4D" call:c4dInstall
if "%_type%"=="Houdini" call:houdiniInstall
if "%_type%"=="Maya" call:mayaInstall
if "%_type%"=="All" (
    call:c4dInstall
    call:houdiniInstall
    call:mayaInstall
)
goto:eof
:rsInstall
echo 检测是否存在redshift
if exist "%rsLoc%\%_verR%" (
    goto :rsOverride
) else (
    goto :rsCopy
)
:rsOverride
echo 文件夹存在，是否替换
choice /M "替换按 Y，不替换按 N"
if %errorlevel%==2 echo 用户取消 & goto rsInstallEnd
echo 开始删除 & rd /s/q "%rsLoc%\%_verR%"
:rsCopy
echo 创建文件夹中
md "%rsLoc%\%_verR%"
echo 开始复制
xcopy "%rs_path%\%_verR%\redshift" "%rsLoc%\%_verR%" /s /e /y
:rsInstallEnd
goto:eof
:c4dInstall
if !vers[%_s%]!==All set i=%c4dV1%
:c4dInstallLoop
call:addR !_ver!
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Maxon\Maxon Cinema 4D %_ver%" /v "Location" ^| findstr "Location"') do (
    set _loc=%%b
)
echo 当前路径为 %_loc%
%rsLoc:~0,1%:
cd "%rsLoc%\%_verR%\Plugins\C4D"
rd /s/q "%_loc%\plugins\redshift"
call install_c4d.bat %R_ver% "%_loc%\plugins"
call:setPathconfig %_loc%
if %isen%==1 call:_dezh
set tmpa=0
set /a i+=1
if !vers[%_s%]!==All set /a tmpa+=1
if not !vers[%i%]!==All set /a tmpa+=1
if %tmpa%==2 (
	set _ver=!vers[%i%]!
    goto c4dInstallLoop
)
goto:eof
:houdiniInstall 
call:getPersonal
set i=%houdiniV1%
if !vers[%_s%]!==All set _ver=!vers[%i%]!
:houdiniInstallLoop
for /f "delims=. tokens=1,2,*" %%l in ("!vers[%i%]!") do (
    set _ver=%%l.%%m
)
call:findReplaceAndAdd "HOUDINI_DSO_ERROR = " "%_Personal%\houdini%_ver%\houdini.env" "HOUDINI_DSO_ERROR = 2"
call:findReplaceAndAdd "REDSHIFT_COREDATAPATH = " "%_Personal%\houdini%_ver%\houdini.env" "REDSHIFT_COREDATAPATH = "$Programdata/redshift/%_verR%""
call:findReplaceAndAdd "REDSHIFT_LOCALDATAPATH = " "%_Personal%\houdini%_ver%\houdini.env" "REDSHIFT_LOCALDATAPATH = "$Programdata/redshift/%_verR%""
call:findReplaceAndAdd "PATH = $REDSHIFT_LOCALDATAPATH/bin;$PATH" "%_Personal%\houdini%_ver%\houdini.env" "PATH = $REDSHIFT_LOCALDATAPATH/bin;$PATH"
call:findReplaceAndAdd "HOUDINI_PATH = $HOUDINI_PATH;$REDSHIFT_LOCALDATAPATH/Plugins/Houdini/${HOUDINI_VERSION}" "%_Personal%\houdini%_ver%\houdini.env" "HOUDINI_PATH = $HOUDINI_PATH;$REDSHIFT_LOCALDATAPATH/Plugins/Houdini/${HOUDINI_VERSION}"
call:findReplaceAndAdd "PXR_PLUGINPATH_NAME = $REDSHIFT_LOCALDATAPATH/Plugins/Solaris/${HOUDINI_VERSION}" "%_Personal%\houdini%_ver%\houdini.env" "PXR_PLUGINPATH_NAME = $REDSHIFT_LOCALDATAPATH/Plugins/Solaris/${HOUDINI_VERSION}"
set tmpa=0
set /a i+=1
if !vers[%_s%]!==All set /a tmpa+=1
if not !vers[%i%]!==All set /a tmpa+=1
if %tmpa%==2 (
    set _ver=!vers[%i%]!
    goto houdiniInstallLoop
)
goto:eof
:mayaInstall
set i=%mayaV1%
if !vers[%_s%]!==All set _ver=!vers[%i%]!
:mayaInstallLoop
%rsLoc:~0,1%:
cd "%rsLoc%\%_verR%\Plugins\Maya"
set "mayaBatName=install_redshift4maya_%_ver%-64.bat"
call %mayaBatName%
set tmpa=0
set /a i+=1
if !vers[%_s%]!==All set /a tmpa+=1
if not !vers[%i%]!==All set /a tmpa+=1
if %tmpa%==2 (
    set _ver=!vers[%i%]!
    goto mayaInstallLoop
)
goto:eof


:findReplaceAndAdd
set tmpb=0
(for /f "delims=" %%i in (%~2) do (
    set "line=%%i"
    if "!line:%~1=!" neq "!line!" (
        echo %~3
        set "tmpb=1"
    ) else (
        echo %%i
    )
)) > %~2.tmp
if %tmpb%==0 (
    echo %~3>>%~2.tmp
)
move /y %~2.tmp %~2
goto:eof
:addR
set R_ver=%1
if not "!R_ver:~0,1!"=="R" (
    set R_ver=R%R_ver%
)
goto:eof
:_dezh
echo 去汉化开始
cd %_loc%\plugins\Redshift\res
move /-y strings_zh-CN strings_zh-CN_bkp
xcopy "strings_en-US" "strings_zh-CN" /s /e /i
echo 去汉化结束
goto:eof
:setPathconfig
%_loc:~0,1%:
cd %_loc%\plugins\Redshift
echo 当前路径 %_loc%\plugins\Redshift
echo 删除旧pathconfig
del /q pathconfig.xml
echo 创建新pathconfig
echo "<path name="REDSHIFT_COREDATAPATH" value="%rsLoc%\%_verR%" />" >> pathconfig.xml
echo "<path name="REDSHIFT_LOCALDATAPATH" value="%rsLoc%\%_verR%" />" >> pathconfig.xml
echo 创建在 %_loc%\plugins\Redshift\pathconfig.xml
echo 创建结束
goto:eof
:getPersonal
for /f "usebackq tokens=3*" %%i in (`reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal`) do set _Personal=%%i
for /f "usebackq delims=" %%i in (`echo %_Personal%`) do set _Personal=%%i
goto:eof





:end
pause