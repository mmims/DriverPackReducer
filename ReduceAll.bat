@ECHO off

REM SETLOCAL ENABLEEXTENSIONS
SET DRIVERPACKS=%~dp0
SET REDUCEBAT=reduce.bat
SET SHOWONLY=
SET OUTDIR=

:LOOP
IF NOT "%~1"=="" (
    IF /I "%~1"=="-h" GOTO :USAGE
    IF /I "%~1"=="--help" GOTO :USAGE
    IF /I "%~1"=="-s" SET SHOWONLY=true
    IF /I "%~1"=="--stats" SET SHOWONLY=true
    IF /I "%~1"=="-d" (
        IF "%~2"=="" GOTO :ERROR_DNG
        SET OUTDIR=%~2\
        SHIFT
    )
    IF /I "%~1"=="--dir" (
        IF "%~2"=="" GOTO :ERROR_DNG
        SET OUTDIR=%~2\
        SHIFT
    )
    SHIFT
    GOTO :LOOP
)

IF DEFINED SHOWONLY (GOTO :SHOWALLSTATS)

IF DEFINED OUTDIR (
    ECHO Reducing drivers to "%OUTDIR%"
    ECHO.

    REM  Dell drivers section
    REM  Dell M90
    CALL :REDUCE_PLATFORM "Dell\M90\Vista\x64" "%OUTDIR%Dell_M90_Vista_x64"

    REM  Dell M6300 ::
    CALL :REDUCE_PLATFORM "Dell\M6300\Vista\x64" "%OUTDIR%Dell_M6300_Vista_x64"

    REM  Dell M6400 
    CALL :REDUCE_PLATFORM "Dell\M6400\Win7\x64" "%OUTDIR%Dell_M6400_Win7_x64"

    REM  Dell M6500 
    CALL :REDUCE_PLATFORM "Dell\M6500\win7\x64" "%OUTDIR%Dell_M6500_Win7_x64"

    REM  Dell M6700 
    CALL :REDUCE_PLATFORM "Dell\M6700\win7\x64" "%OUTDIR%Dell_M6700_Win7_x64"

    REM  DTECH drivers section 
    REM  DTECH M3-SE APP1 
    CALL :REDUCE_PLATFORM "DTECH\M3-SE\APP1\Win7\x64" "%OUTDIR%DTECH_M3-SE_APP1_Win7_x64"

    REM  DTECH M3-SE SVR2 
    CALL :REDUCE_PLATFORM "DTECH\M3-SE\SVR2\Win7\x64" "%OUTDIR%DTECH_M3-SE_SVR2_Win7_x64"

    REM  HP drivers section 
    REM  HP 6930p 
    CALL :REDUCE_PLATFORM "HP\6930p\Win7\x64" "%OUTDIR%HP_6930p_Win7_x64"
    
    REM  HP 8570p 
    CALL :REDUCE_PLATFORM "HP\8570p\Win7\x64" "%OUTDIR%HP_8570p_Win7_x64"
    
    REM  Panasonic drivers section 
    REM  Panasonic CF-19
    CALL :REDUCE_PLATFORM "Panasonic\CF-19(mk5)\Win7\x64" "%OUTDIR%Panasonic_CF-19(mk5)_Win7_x64"
) ELSE (
    ECHO Reducing drivers to relative paths
    ECHO.

    REM  Dell drivers section 
    REM  Dell M90 
    CALL :REDUCE_PLATFORM "Dell\M90\Vista\x64"

    REM  Dell M6300 
    CALL :REDUCE_PLATFORM "Dell\M6300\Vista\x64"

    REM  Dell M6400 
    CALL :REDUCE_PLATFORM "Dell\M6400\Win7\x64"

    REM  Dell M6500 
    CALL :REDUCE_PLATFORM "Dell\M6500\win7\x64"

    REM  Dell M6700 
    CALL :REDUCE_PLATFORM "Dell\M6700\win7\x64"

    REM  DTECH drivers section 
    REM  DTECH M3-SE APP1 
    CALL :REDUCE_PLATFORM "DTECH\APP1\Win7\x64"

    REM  DTECH M3-SE SVR2 
    CALL :REDUCE_PLATFORM "DTECH\SVR2\Win7\x64"

    REM  HP drivers section 
    REM  HP 6930p 
    CALL :REDUCE_PLATFORM "HP\6930p\Win7\x64"

    REM  HP 8570p 
    CALL :REDUCE_PLATFORM "HP\8570p\Win7\x64"

    REM  Panasonic drivers section 
    REM  Panasonic CF-19 
    CALL :REDUCE_PLATFORM "Panasonic\CF-19(mk5)\Win7\x64"
)

:SHOWALLSTATS
REM Stats for all drivers sets
IF DEFINED OUTDIR (
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M90\Vista\x64" "%OUTDIR%Dell_M90_Vista_x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M6300\Vista\x64" "%OUTDIR%Dell_M6300_Vista_x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M6400\Win7\x64" "%OUTDIR%Dell_M6400_Win7_x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M6500\Win7\x64" "%OUTDIR%Dell_M6500_Win7_x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M6700\Win7\x64" "%OUTDIR%Dell_M6700_Win7_x64"
    CALL :SHOWSTATS "%DRIVERPACKS%DTECH\M3-SE\APP1\Win7\x64" "%OUTDIR%DTECH_M3-SE_APP1_Win7_x64"
    CALL :SHOWSTATS "%DRIVERPACKS%DTECH\M3-SE\SVR2\Win7\x64" "%OUTDIR%DTECH_M3-SE_SVR2_Win7_x64"
    CALL :SHOWSTATS "%DRIVERPACKS%HP\6930p\Win7\x64" "%OUTDIR%HP_6930p_Win7_x64"
    CALL :SHOWSTATS "%DRIVERPACKS%HP\8570p\Win7\x64" "%OUTDIR%HP_8570p_Win7_x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Panasonic\CF-19(mk5)\Win7\x64" "%OUTDIR%Panasonic_CF-19(mk5)_Win7_x64"
) ELSE (
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M90\Vista\x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M6300\Vista\x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M6400\Win7\x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M6500\Win7\x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Dell\M6700\Win7\x64"
    CALL :SHOWSTATS "%DRIVERPACKS%DTECH\M3-SE\APP1\Win7\x64"
    CALL :SHOWSTATS "%DRIVERPACKS%DTECH\M3-SE\SVR2\Win7\x64"
    CALL :SHOWSTATS "%DRIVERPACKS%HP\6930p\Win7\x64"
    CALL :SHOWSTATS "%DRIVERPACKS%HP\8570p\Win7\x64"
    CALL :SHOWSTATS "%DRIVERPACKS%Panasonic\CF-19(mk5)\Win7\x64"
)
GOTO :EOF


:REDUCE_PLATFORM
IF NOT "%~2"=="" (
    IF NOT EXIST "%~2" (
        ECHO Creating output directory "%~2"
        MKDIR "%~2"
    )
    CALL "%DRIVERPACKS%%~1\%REDUCEBAT%" "%~2"
) ELSE (
    CALL "%DRIVERPACKS%%~1\%REDUCEBAT%"
)
GOTO :EOF


:SHOWSTATS
ECHO Stats for %~1
IF NOT "%~2"=="" (
    "%DRIVERPACKS%scripts\DriverReducer\DriverReducer.exe" -s=M -d="%~2" "%~1"
) ELSE (
    "%DRIVERPACKS%scripts\DriverReducer\DriverReducer.exe" -s=M "%~1"
)
GOTO :EOF


:USAGE
ECHO Usage: %~n0 [options]
ECHO     -d, --dir ^<path^>    Specifies the directory for the reduced sets
ECHO     -s, --stats         Show the reduction stats (does not perform reduction)
ECHO     -h, --help          Display usage information
ECHO.
GOTO :EOF


:ERROR_DNG
ECHO ERROR: Directory not given for arg -dir
GOTO :EOF


:EOF
ENDLOCAL