#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_AU3Check_Parameters= -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#NoTrayIcon
#include <Array.au3>
#include <File.au3>
#include <WinAPIEx.au3>
#include "..\log4a\log4a.au3"
#include "..\OptParse\_OptParse.au3"

Global Const $gSourceDisksNames[5] = [ _
	  "SourceDisksNames" _
	, "SourceDisksNames.x86" _
	, "SourceDisksNames.amd64" _
	, "SourceDisksNames.NTx86" _
	, "SourceDisksNames.NTamd64" _
	]
Global Const $gSourceDisksFiles[5] = [ _
	  "SourceDisksFiles" _
	, "SourceDisksFiles.x86" _
	, "SourceDisksFiles.amd64" _
	, "SourceDisksFiles.NTx86" _
	, "SourceDisksFiles.NTamd64" _
	]
Global Const $gCatalogFileEntries[5] = [ _
	  "CatalogFile" _
	, "CatalogFile.x86" _
	, "CatalogFile.amd64" _
	, "CatalogFile.NTx86" _
	, "CatalogFile.NTamd64" _
	]
Global Const _
	  $_DESC    = "Creates a reduced driver set using symbolic links." _
	, $_TITLE   = "Driver Reducer" _
	, $_VERSION = "0.6.0"
Global Const $gValidSizePrefixes[6] = ["k","ki","m","mi","g","gi"]
Global Enum Step *2 $_ERROR_NONE=0,$_ERROR_INVALIDARG=1,$_ERROR_DUPLICATEARG,$_ERROR_INVALIDSWITCH,$_ERROR_NOBASEDIR _
	,$_ERROR_BASEDIRDNE,$_ERROR_FULLDIRDNE,$_ERROR_REDUCEDDIRDNE
Global $_OPT_RELATIVE = False, $_OPT_SIZES = False, $_OPT_SIZES_PREFIX = "", $_OPT_REDUCED_DIR = ""

; Default logger settings
_log4a_SetEnable(False)
_log4a_SetCompiledOutput($LOG4A_OUTPUT_CONSOLE)
_log4a_SetMinLevel($LOG4A_LEVEL_WARN)

_Main()

Func _Main()
	Local $aValidOpts, $aOptions, $aCmdLine = $CmdLine

	If _ParseOptions($aValidOpts, $aOptions, $aCmdLine) Then
		Local $iOption
		If _OptParse_MatchOption("h,help,?", $aOptions, $iOption) Then
			_OptParse_ShowUsage($aValidOpts)
			Exit($_ERROR_NONE)
		EndIf
		If _OptParse_MatchOption("l,log", $aOptions, $iOption) Then _log4a_SetCompiledOutput($LOG4A_OUTPUT_FILE)
		If _OptParse_MatchOption("d,dir", $aOptions, $iOption) Then
			$_OPT_REDUCED_DIR = $aOptions[$iOption][1]
			If StringRight($_OPT_REDUCED_DIR, 1) <> "\" Then $_OPT_REDUCED_DIR &= "\"
		EndIf
		If _OptParse_MatchOption("r,relative", $aOptions, $iOption) Then $_OPT_RELATIVE = True
		If _OptParse_MatchOption("s,sizes", $aOptions, $iOption) Then
			$_OPT_SIZES = True
			If _ArraySearch($gValidSizePrefixes, StringLower($aOptions[$iOption][1])) >= 0 Then _
				$_OPT_SIZES_PREFIX = StringLower($aOptions[$iOption][1])
		EndIf
		If _OptParse_MatchOption("v,verbose", $aOptions, $iOption) Then _log4a_SetEnable()
	EndIf

	If $aCmdLine[0] > 0 Then
		If $_OPT_SIZES Then
			_Driver_CalculateSetSizes($aCmdLine[1])
			Switch @error
				Case 1
					_ExitWithError($_ERROR_BASEDIRDNE)
				Case 2
					_ExitWithError($_ERROR_FULLDIRDNE)
				Case 3
					_ExitWithError($_ERROR_REDUCEDDIRDNE)
			EndSwitch
		Else
			_Driver_CreateReducedLinks($aCmdLine[1])
			If @error Then _ExitWithError($_ERROR_BASEDIRDNE)
		EndIf
	Else
		_OptParse_Display("Driver base directory not specified.", "Error")
		Exit($_ERROR_NOBASEDIR)
	EndIf

EndFunc  ;==>Main

Func _CalculateFolderSize($sFolder)
	If Not FileExists($sFolder) Then Return SetError(1, 0, 0)
	If StringRight($sFolder, 1) <> "\" Then $sFolder &= "\"
	Local $hSearch, $iSize, $sFile, $bIsDir, $sFullPath, $aSizeFolder
	Local $aSize[3] = [0, 0, 0]

	$hSearch = FileFindFirstFile($sFolder & "*")
	If $hSearch == -1 Then Return SetError(1, 0, 0)

	While 1
		$sFile = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		$bIsDir = @extended
		$sFullPath = $sFolder & $sFile

		If $bIsDir == 1 Then
			$aSizeFolder = _CalculateFolderSize($sFullPath)
			If IsArray($aSizeFolder) Then
				$aSize[0] += $aSizeFolder[0]
				$aSize[1] += $aSizeFolder[1]
				$aSize[2] += $aSizeFolder[2]
			EndIf
			$aSize[2] += 1
		Else
			$iSize = FileGetSize(_ResolvePath($sFullPath))
			$aSize[0] += $iSize
			$aSize[1] += 1
		EndIf
	WEnd

	Return $aSize
EndFunc  ;==>_CaclulateFolderSize

Func _Driver_CalculateSetSizes($sBaseDir)
	If Not FileExists($sBaseDir) Then Return SetError(1, 0, 0)
	If StringRight($sBaseDir, 1) <> "\" Then $sBaseDir &= "\"
	Local $aFullSize, $aReducedSize, $sOutput _
		, $sFullDir = StringFormat("%sfull", $sBaseDir) _
		, $sReducedDir = StringFormat("%sreduced", $sBaseDir)
	If $_OPT_REDUCED_DIR <> "" Then $sReducedDir = StringFormat("%sreduced", $_OPT_REDUCED_DIR)

	; Check for directory existence
	If Not FileExists($sFullDir) Then Return SetError(2, 0, 0)
	If Not FileExists($sReducedDir) Then Return SetError(3, 0, 0)

	; Calculate full directory
	$aFullSize = DirGetSize($sFullDir, 1)
	If Not IsArray($aFullSize) Then Local $aFullSize[3] = [0, 0, 0]

	; Calculate reduced directory
	$aReducedSize = _CalculateFolderSize($sReducedDir)
	If Not IsArray($aReducedSize) Then Local $aReducedSize[3] = [0, 0, 0]

	; Display stats
	$sOutput =  StringFormat("%10s  %-20s %-20s %-20s\r\n", "", "Full set", "Reduced set", "Difference")
	$sOutput &= StringFormat("            -----------------------------------------------------------------\r\n")
	$sOutput &= StringFormat("%10s  %-20s %-20s %-15s (%.1f%%)\r\n", "Size", _GetSizeString($aFullSize[0]), _
		_GetSizeString($aReducedSize[0]), _GetSizeString($aFullSize[0] - $aReducedSize[0]), ($aFullSize[0] - $aReducedSize[0]) / $aFullSize[0] * 100.0)
	$sOutput &= StringFormat("%10s  %-20s %-20s %-15s (%.1f%%)\r\n", "Files", $aFullSize[1], $aReducedSize[1], _
		$aFullSize[1] - $aReducedSize[1], ($aFullSize[1] - $aReducedSize[1]) / $aFullSize[1] * 100.0)
	$sOutput &= StringFormat("%10s  %-20s %-20s %-15s (%.1f%%)\r\n\r\n", "Folders", $aFullSize[2], $aReducedSize[2], _
		$aFullSize[2] - $aReducedSize[2], ($aFullSize[2] - $aReducedSize[2]) / $aFullSize[2] * 100.0)

	ConsoleWrite($sOutput)
EndFunc  ;==>_Driver_CalculateSetSizes

Func _Driver_CreateReducedLinks($sBaseDir)
	If Not FileExists($sBaseDir) Then Return SetError(1, 0, 0)
	If StringRight($sBaseDir, 1) <> "\" Then $sBaseDir &= "\"
	Local $aSet, $aFiles

	_Driver_GetDriverFiles($aSet, $sBaseDir & "full")
	If Not @error Then
		Local $sPartialDir, $sReducedDir, $sReducedBase, $sFullFile, $sRelativePath, $sAltFile, $sAltFullFile
		$sReducedBase = StringFormat("%sreduced", $sBaseDir)
		If $_OPT_REDUCED_DIR <> "" Then $sReducedBase = StringFormat("%sreduced", $_OPT_REDUCED_DIR)
		DirCreate($sReducedBase)
		_log4a_SetLogFile($sReducedBase & "\driverreducer.log")

		For $i=1 To $aSet[0]
			_log4a_Info("Processing " & $aSet[$i])
			$sPartialDir = StringRegExpReplace(StringTrimLeft($aSet[$i], StringLen($sBaseDir & "full")), "(?i)(.+)\\.+\.inf", "\1")
			$sReducedDir = StringFormat("%s%s\\", $sReducedBase, $sPartialDir)
			$aFiles = _Driver_GetSourceDisksFiles($aSet[$i])
			If Not IsArray($aFiles) Then ContinueLoop

			For $j=0 To UBound($aFiles) - 1
				$sFullFile = StringFormat("%sfull%s\\%s", $sBaseDir, $sPartialDir, $aFiles[$j])
				If FileExists($sFullFile) Then
					DirCreate(StringRegExpReplace($sReducedDir & $aFiles[$j], "\A(.+)\\.+\Z", "\1"))
					If $_OPT_RELATIVE Then
						$sRelativePath = _PathGetRelative(StringRegExpReplace($sReducedDir & $aFiles[$j], "\A(.+)\\.+\Z", "\1"), $sFullFile)
						_log4a_Info("[symlink] Creating: " & $sReducedDir & $aFiles[$j] & " => " & $sRelativePath)
						_WinAPI_CreateSymbolicLink($sReducedDir & $aFiles[$j], $sRelativePath)
					Else
						_log4a_Info("[symlink] Creating: " & $sReducedDir & $aFiles[$j] & " => " & $sFullFile)
						_WinAPI_CreateSymbolicLink($sReducedDir & $aFiles[$j], $sFullFile)
					EndIf
					If @error Then
						If FileExists($sReducedDir & $aFiles[$j]) Then
							_log4a_Warn("[symlink] File or link already exists: " & $sReducedDir & $aFiles[$j], True)
						Else
							_log4a_Warn("[symlink] Failed to create: " & $sReducedDir & $aFiles[$j] & " => " & $sFullFile, True)
						EndIf
					EndIf
				Else
					$sAltFile = StringTrimRight($aFiles[$j], "1") & "_"
					$sAltFullFile = StringFormat("%sfull%s\\%s", $sBaseDir, $sPartialDir, $sAltFile)
					If FileExists($sAltFullFile) Then
						DirCreate(StringRegExpReplace($sReducedDir & $sAltFile, "\A(.+)\\.+\Z", "\1"))
						If $_OPT_RELATIVE Then
							$sRelativePath = _PathGetRelative(StringRegExpReplace($sReducedDir & $sAltFile, "\A(.+)\\.+\Z", "\1"), $sAltFullFile)
							_log4a_Info("[symlink] Creating: " & $sReducedDir & $sAltFile & " => " & $sRelativePath)
							_WinAPI_CreateSymbolicLink($sReducedDir & $sAltFile, $sRelativePath)
						Else
							_log4a_Info("[symlink] Creating: " & $sReducedDir & $sAltFile & " => " & $sAltFullFile)
							_WinAPI_CreateSymbolicLink($sReducedDir & $sAltFile, $sAltFullFile)
						EndIf
						If @error Then
							If FileExists($sReducedDir & $sAltFile) Then
								_log4a_Warn("[symlink] File or link already exists: " & $sReducedDir & $sAltFile, True)
							Else
								_log4a_Warn("[symlink] Failed to create: " & $sReducedDir & $sAltFile & " => " & $sAltFullFile, True)
							EndIf
						EndIf
					Else
						_log4a_Error("[symlink] Target does not exist: " & $sFullFile, True)
					EndIf
				EndIf
			Next
		Next
	EndIf
EndFunc  ;==>_Driver_CreateReducedLinks

Func _Driver_GetDriverFiles(ByRef $aDriverFiles, $sBaseDir, $bRecurse = True)
	If Not FileExists($sBaseDir) Then Return SetError(1, 0, 0)
	Local $hSearch, $bIsDir, $sFile, $sFullPath, $sSignature

	If Not IsArray($aDriverFiles) Then Dim $aDriverFiles[1] = [0]
	If StringRight($sBaseDir, 1) <> "\" Then $sBaseDir &= "\"

	$hSearch = FileFindFirstFile($sBaseDir & "*")
	If $hSearch == -1 Then Return SetError(2, 0, 0)

	While 1
		$bIsDir = False
		$sFile = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		If @extended Then $bIsDir = True

		$sFullPath = $sBaseDir & $sFile
		If $bIsDir And $bRecurse Then
			_Driver_GetDriverFiles($aDriverFiles, $sFullPath)
		ElseIf StringRegExp($sFile, "(?i)\A.+\.inf\Z") == 1 Then
			$sSignature = IniRead($sFullPath, "Version", "Signature", "")
			If @error Then ContinueLoop
			If StringCompare($sSignature, "$Windows NT$") == 0 Then
				_ArrayAdd($aDriverFiles, $sFullPath)
				$aDriverFiles[0] += 1
			EndIf
		EndIf
	WEnd

	Return 1
EndFunc  ;==>_Driver_GetDriverFiles

Func _Driver_GetSourceDisksFiles($sDriverFile)
	Local $aKeyValue _
		, $sFile _
		, $aNames = _Driver_GetSourceDisksNames($sDriverFile) _
		, $aResult[1] = [StringRegExpReplace($sDriverFile, "(?i)\A.+\\(.+\.inf)\Z", "\1")]

	; Add source files
	For $section In $gSourceDisksFiles
		$aKeyValue = IniReadSection($sDriverFile, $section)
		If Not @error Then
			For $i=1 To $aKeyValue[0][0]
				If $aNames[0] > 0 Then
					For $j=1 To $aNames[0]
						_ArrayAdd($aResult, $aNames[$j] & "\" & $aKeyValue[$i][0])
					Next
				ElseIf StringRegExp($aKeyValue[$i][1], "\A(.*,){1}[\d\w\h\-]+\Z") Then
;~  					_log4a_Debug("[SourceDisksFile] " & $sDriverFile & ": " & $aKeyValue[$i][0] & "=" & $aKeyValue[$i][1], True)
					_ArrayAdd($aResult, StringStripWS(StringRegExpReplace($aKeyValue[$i][1], "\A(?:.*,){1}([\d\w\h\-]+)\Z", "\1"), 3) & "\" & $aKeyValue[$i][0])
				Else
					_ArrayAdd($aResult, $aKeyValue[$i][0])
				EndIf
			Next
		EndIf
	Next

	; Add Security catalogs
	For $entry In $gCatalogFileEntries
		$sFile = IniRead($sDriverFile, "Version", $entry, "")
		If $sFile <> "" Then _ArrayAdd($aResult, $sFile)
	Next

	Return $aResult
EndFunc  ;==>_Driver_GetSourceDisksFiles

Func _Driver_GetSourceDisksNames($sDriverFile)
	Local $aKeyValue _
		, $aName _
		, $aNames[1] = [0]

	; Find disk directories
	For $section In $gSourceDisksNames
		$aKeyValue = IniReadSection($sDriverFile, $section)
		If Not @error Then
			For $i=1 To $aKeyValue[0][0]
				$aName = StringRegExp($aKeyValue[$i][1], "(?i)\A(?:.*,){3}(.+)\\?\Z", 3)
				If Not @error And $aName[0] <> "" And $aName[0] <> '""' Then
					_ArrayAdd($aNames, StringRegExpReplace(StringStripWS($aName[0], 3), "\A(?:\.\\|\\)(.+)\Z", "\1"))
					$aNames[0] += 1
				EndIf
			Next
		EndIf
	Next

	Return $aNames
EndFunc  ;==>_Driver_GetSourceDisksNames

Func _ExitWithError($iError)
	Switch $iError
		Case $_ERROR_BASEDIRDNE
			_log4a_Error("Base directory does not exist", True)
		Case $_ERROR_FULLDIRDNE
			_log4a_Error("Full set directory does not exist", True)
		Case $_ERROR_REDUCEDDIRDNE
			_log4a_Error("Reduced set directory does not exist", True)
	EndSwitch
	Exit($iError)
EndFunc  ;==>_ExitWithError

Func _GetSizeString($iSize, $sPrefix = $_OPT_SIZES_PREFIX)
	Local $sSize
	Switch $sPrefix
		Case "k"
			$sSize = StringFormat("%.3f KB", $iSize / 1000)
		Case "ki"
			$sSize = StringFormat("%.3f KiB", $iSize / 1024)
		Case "m"
			$sSize = StringFormat("%.2f MB", $iSize / 1000000)
		Case "mi"
			$sSize = StringFormat("%.2f MiB", $iSize / 1048576)
		Case "g"
			$sSize = StringFormat("%.1f GB", $iSize / 1000000000)
		Case "gi"
			$sSize = StringFormat("%.1f GiB", $iSize / 1073741824)
		Case Else
			$sSize = $iSize & " bytes"
	EndSwitch
	Return $sSize
EndFunc  ;==>_GetSizeString

Func _ParseOptions(ByRef $aValidOpts, ByRef $aOptions, ByRef $aCmdLine)
	$aValidOpts = 0
	$aOptions = 0

	; Create the valid options list
	_OptParse_Init($aValidOpts, @ScriptName & " [options] driver_base_directory\n", $_TITLE & " v" & $_VERSION & "\n", $_DESC & "\n")
	_OptParse_Add($aValidOpts, "d", "dir", $OPT_ARG_OPTIONAL, "Specify the reduced set directory.")
	_OptParse_Add($aValidOpts, "l", "log", $OPT_ARG_NONE, "Save output to a log file.")
	_OptParse_Add($aValidOpts, "r", "relative", $OPT_ARG_NONE, "Use relative paths for links.")
	_OptParse_Add($aValidOpts, "s", "stats", $OPT_ARG_OPTIONAL, "Display stats of full and reduced sets.")
	_OptParse_Add($aValidOpts, "v", "verbose", $OPT_ARG_NONE, "Enable verbose output.")
	_OptParse_Add($aValidOpts, "h", "help", $OPT_ARG_NONE, "Display this message.")
	_OptParse_Add($aValidOpts, "?", "?", $OPT_ARG_NONE, "Display this message.")

	$aOptions = _OptParse_GetOpts($aCmdLine, $aValidOpts)
	Switch @error
		Case 0
			Return True
		Case 1
			Return False
		Case 2
			Exit($_ERROR_INVALIDARG)
		Case 3
			Exit($_ERROR_DUPLICATEARG)
		Case 4
			Exit($_ERROR_INVALIDSWITCH)
	EndSwitch
EndFunc   ;==>_ParseOptions

Func _ResolvePath($sFullPath)
	Local $sResolved = $sFullPath
	Local $hFile = _WinAPI_CreateFile($sFullPath, 2)
	If $hFile <> 0 Then
		$sResolved = _WinAPI_GetFinalPathNameByHandleEx($hFile, 0)
		If @error Then
			$sResolved = $sFullPath
		Else
			$sResolved = StringRegExpReplace($sResolved, "(?i).*([a-z]\:.+)", "\1")
		EndIf
		_WinAPI_CloseHandle($hFile)
	EndIf
	Return $sResolved
EndFunc  ;==>_ResolvePath