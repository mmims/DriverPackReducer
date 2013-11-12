@ECHO off
SETLOCAL

SET PLATFORM=
SET BASE=%~dps0
SET REDUCER_TEMPLATE=%BASE%..\..\..\..\scripts\DriverReducer\reducer.bat

IF /I "%~1"=="/?" GOTO :USAGE
IF /I "%~1"=="-?" GOTO :USAGE

IF NOT EXIST %REDUCER_TEMPLATE% GOTO :ERROR_INVALIDRT

IF "%~1"=="" GOTO :REDUCE
SET OUTDIR=%~fs1\

:REDUCE
IF defined OUTDIR (
    CALL "%REDUCER_TEMPLATE%" --platform "%PLATFORM%" --dir="%OUTDIR%" "%BASE%"
) ELSE (
    CALL "%REDUCER_TEMPLATE%" --platform "%PLATFORM%" "%BASE%"
)

IF NOT ERRORLEVEL==0 GOTO :ERROR_REDUCER

ECHO . Removing x86 files
IF defined OUTDIR (SET BASE=%OUTDIR%)


ECHO . Reduction complete
ECHO.
GOTO :EOF

:ERROR_INVALIDRT
ECHO ERROR: Reducer template not found %REDUCER_TEMPLATE%
GOTO :EOF

:ERROR_REDUCER
ECHO ERROR: Reducer failed
GOTO :EOF

:USAGE
ECHO.
ECHO Usage: reduce [^<OutputDirectory^>]
ECHO   OutputDirectory  The output directory for the reduced set
ECHO.

:EOF
ENDLOCAL