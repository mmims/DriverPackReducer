@ECHO off
::SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL

SET BASE=
SET REDUCER=%~dps0DriverReducer.exe
SET NOARG=
SET OUTDIR=
SET APP=%~n0
SET PLATFORM=

IF "%~1"=="" GOTO :USAGE
IF NOT EXIST "%REDUCER%" GOTO :ERROR_MISSING_REDUCER

:LOOP
IF NOT "%~1"=="" (
    SET FOUND=
    IF /I "%~1"=="-?" GOTO :USAGE
    IF /I "%~1"=="/?" GOTO :USAGE
    IF /I "%~1"=="-h" GOTO :USAGE
    IF /I "%~1"=="--help" GOTO :USAGE
    IF /I "%~1"=="-d" (
        IF "%~2"=="" (
            SET NOARG=%1
            GOTO :ERROR_NOARG
        )
        SET OUTDIR=%~2
        SET FOUND=true
        SHIFT
    )
    IF /I "%~1"=="--dir" (
        IF "%~2"=="" (
            SET NOARG=%1
            GOTO :ERROR_NOARG
        )
        SET OUTDIR=%~2
        SET FOUND=true
        SHIFT
    )
    IF /I "%~1"=="-p" (
        IF "%~2"=="" (
            SET NOARG=%1
            GOTO :ERROR_NOARG
        )
        SET PLATFORM=%~2
        SET FOUND=true
        SHIFT
    )
    IF /I "%~1"=="--platform" (
        IF "%~2"=="" (
            SET NOARG=%1
            GOTO :ERROR_NOARG
        )
        SET PLATFORM=%~2
        SET FOUND=true
        SHIFT
    )
    IF /I "%~1"=="-v" (
        SET VERBOSE=true
        SET FOUND=true
    )
    IF /I "%~1"=="-verbose" (
        SET VERBOSE=true
        SET FOUND=true
    )
    IF NOT DEFINED FOUND (
        SET BASE=%~1
    )
    SHIFT
    GOTO :LOOP
)

IF DEFINED VERBOSE (
    ECHO     BASE=%BASE%
    ECHO  REDUCER=%REDUCER%
    ECHO   OUTDIR=%OUTDIR%
    ECHO PLATFORM=%PLATFORM%
)

IF NOT DEFINED BASE GOTO :ERROR_MISSING_BASE
IF NOT EXIST "%BASE%" GOTO :ERROR_INVALID_BASE
REM IF DEFINED OUTDIR (
REM    IF NOT EXIST "%OUTDIR%" GOTO :ERROR_INVALID_OUTDIR
REM )

IF DEFINED PLATFORM (ECHO Drivers reduction for %PLATFORM%)
IF DEFINED OUTDIR (
    IF EXIST "%OUTDIR%reduced" (
        ECHO . Removing old reduction "%OUTDIR%reduced"
        RMDIR /S /Q "%OUTDIR%reduced"
    )
) ELSE (
    IF EXIST "%BASE%reduced" (
       ECHO . Removing old reduction "%BASE%reduced"
       RMDIR /S /Q "%BASE%reduced"
    )
)

ECHO . Reducing full drivers set "%BASE%full"
IF defined OUTDIR (
    "%REDUCER%" --relative --verbose --log --dir="%OUTDIR%" "%BASE%"
) ELSE (
    "%REDUCER%" --relative --verbose --log "%BASE%"
)
GOTO EOF

:ERROR_NOARG
ECHO ERROR: Argument not provided for '%NOARG%'
GOTO USAGE

:ERROR_INVALID_BASE
ECHO ERROR: Base directory invalid %BASE%
EXIT /B 1

:ERROR_INVALID_OUTDIR
ECHO ERROR: Output directory invalid %OUTDIR%
EXIT /B 2

:ERROR_MISSING_BASE
ECHO ERROR: Base directory not specified
EXIT /B 3

:ERROR_MISSING_REDUCER
ECHO ERROR: Reducer not found %REDUCER%
EXIT /B 4

:USAGE
ECHO.
ECHO Usage: %APP% [options] ^<base_directory^>
ECHO   Options:
ECHO     -d, --dir         The output directory for the reduced set
ECHO     -p, --platform    The name of the platform that is being reduced
ECHO     -h, --help        Display this message
ECHO.

:EOF
ENDLOCAL
EXIT /B 0