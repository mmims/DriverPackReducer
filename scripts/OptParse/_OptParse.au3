#include-once
#AutoIt3Wrapper_Run_Au3check= y
#AutoIt3Wrapper_Au3Check_Parameters= -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6

; #INDEX# =======================================================================================================================
; Title .........: _OptParse
; AutoIt Version : 3.2.10++
; Language       : English
; Description ...: Provides core functions for command line parsing of arguments into an array.
; Author(s)      : Stephen Podhajecki (eltorro)
; ===============================================================================================================================
; Updated for AutoIt version 3.3.0.0

; #VARIABLES# ===================================================================================================================
Global $OPTPARSE_VERSION = "0.0.1.4"
Global Enum $OPT_SHORT, $OPT_LONG, $OPT_TYPE, $OPT_DESC, $OPT_COUNT, $OPT_MAX
Global $OPT_ARG_NONE = 1
Global Enum Step *2 $OPT_ARG_REQ=2, $OPT_ARG_OPTIONAL, $OPT_ARG_MULTI, $OPT_ARG_HIDDEN, $OPT_ARG_MAX
Global $OPT_DISPLAY = 0 ;0= console 1=MsgBox
; ===============================================================================================================================
; #CURRENT# =====================================================================================================================
;_OptParse_Init
;_OptParse_Add
;_OptParse_ShowUsage
;_OptParse_ShowVersion
;_OptParse_GetOpts
;_OptParse_Scrub
;_OptParse_SetDisplay
;_OptParse_Display
;_OptParse_MatchOption
; ===============================================================================================================================

; #INTERNAL_USE_ONLY#============================================================================================================
; _OptParse_Scrub
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _OptParse_Init
; Description ...: Intialize the Valid Options/switches array
; Parameters ....: $aOptions - IN/OUT - Variable to hold the options/switches
;                  $s1 - IN/OPTIONAL - Version display string 1
;                  $s2 - IN/OPTIONAL - Version display string 2
;                  $s3 - IN/OPTIONAL - Version display string 3
; Return values .: On Success - 1
;                  On Failure - 0, @error set to 1
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......; [yes/no]
; ===============================================================================================================================
Func _OptParse_Init(ByRef $aOptions, $s1 = "", $s2 = "", $s3 = "")
	Dim $aOptions[1][$OPT_MAX]
	If @error Then Return SetError(1, 0, 0)
	$aOptions[0][0] = 0
	$aOptions[0][1] = StringFormat($s1)
	$aOptions[0][2] = StringFormat($s2)
	$aOptions[0][3] = StringFormat($s3)
	Return 1
EndFunc   ;==>_OptParse_Init

; #FUNCTION# ====================================================================================================================
; Name ..........: _OptParse_Add
; Description ...: Adds an option/switch to the list of valid options/switches created with _OptParse_Init
; Parameters ....: $aOptions - IN/OUT - Options array created with _OptParse_Init
;                  $sOpt_short - IN - Short option name
;                  $sOpt_long - IN/OPTIONAL - Long option name
;                  $iOpt_type - IN/OPTIONAL - Requirement type
;                  |0 - No expected value
;                  |1 - Required value
;                  |2 - Optional value
;                  |3 - Multiple values expected
;                  $sOpt_desc - IN/OPTIONAL - Usage description
; Return values .: On Success - The next index number
;                  On Failure - 0 and @error set to 1
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......; [yes/no]
; ===============================================================================================================================
Func _OptParse_Add(ByRef $aOptions, $sOpt_short = "", $sOpt_long = "", $iOpt_type = 0, $sOpt_desc = "")
	If $iOpt_type < $OPT_ARG_NONE Then
		Return SetError(1, 0, 0)
	EndIf
	If $iOpt_type > (($OPT_ARG_MAX / 2) - 1) * 2 Then Return SetError(1, 0, 0)
	Local $iIndex = $aOptions[0][0]
	For $iOptIndex = 1 to $aOptions[0][0]
	;	If $aOptions[$iOptIndex][$OPT_SHORT] == $sOpt_short Or $aOptions[$iOptIndex][$OPT_LONG] == $sOpt_long Then
		If $aOptions[$iOptIndex][$OPT_SHORT] == $sOpt_short Or $aOptions[$iOptIndex][$OPT_LONG] = $sOpt_long Then
			Return SetError(1,0,0); Option has already been added.
		EndIf
	Next
	$iIndex += 1
	ReDim $aOptions[$iIndex + 1][$OPT_MAX]
	If @error Then
		;		ConsoleWrite(StringFormat("Error adding option:%s,%s,%s,%s,%s\n",$iIndex,$sOpt_short,$sOpt_long,$iOpt_type,$sOpt_desc))
		Return SetError(1, 0, 0)
	EndIf
	$aOptions[$iIndex][$OPT_SHORT] = $sOpt_short
	$aOptions[$iIndex][$OPT_LONG] = $sOpt_long
	$aOptions[$iIndex][$OPT_TYPE] = $iOpt_type
	$aOptions[$iIndex][$OPT_DESC] = $sOpt_desc
	$aOptions[$iIndex][$OPT_COUNT] = 0
	$aOptions[0][0] = $iIndex
	Return $iIndex
EndFunc   ;==>_OptParse_Add

; #FUNCTION# =====================================================================================================================
; Description ...: Checks a comma separated list of options for a match.
; Parameters ....: $vArgs - IN - The options to check for
;                  $aOpt_options - IN - The options list returned by _GetOpt()
;                  $iIndex - IN/OUT - The index of the item, if found.
; Return values .: On Success - True
;                  On Failure - False, @error set to 1
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Remarks .......: The $iIndex variable is used to hold the index of a match.It's initial value is always set to -1.
;                  If a match is found, it is set to the index.
; Related .......:
; ================================================================================================================================
Func _OptParse_MatchOption($vArgs, $aOpt_options, ByRef $iIndex)
	$iIndex = -1
	Local $i, $j
	Local $aArgs = StringSplit($vArgs & ",", ",")
	If @error Or Not (IsArray($aArgs)) Then Return SetError(1, 0, "")
	_OptParse_Scrub($aArgs)
	For $j In $aArgs
		If $j <> "" Then
			For $i = 0 To UBound($aOpt_options) - 1
				;If $j == $aOpt_options[$i][0] Then
				If $j == $aOpt_options[$i][0] Then
					$iIndex = $i
					Return True
				EndIf
			Next
		EndIf
	Next
	Return SetError(1, 0, False)
EndFunc   ;==>_OptParse_MatchOption

; #FUNCTION# ====================================================================================================================
; Name ..........: _OptParse_ShowUsage
; Description ...: Displays a usage message
; Parameters ....: $aOptions - IN - An array of options/switches
;                  $iFlag - IN/OPTIONAL - Specifies where to display message
;                  |0 - Display to console
;                  |1 - Display in a messagebox
; Return values .:
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Modified.......:
; Remarks .......: If iFlag =0 then the message is sent to the console, if iFlag >0 displays in a messagebox
; Related .......: _OptParse_ShowVersion
; Link ..........;
; Example .......; [yes/no]
; ===============================================================================================================================
Func _OptParse_ShowUsage($aOptions, $iFlag = 0)
	Local $x, $msg = ""
	$msg &= $aOptions[0][1] & $aOptions[0][2] & $aOptions[0][3] & @CRLF
	Local $iIndex = $aOptions[0][0]
	If $iIndex > 0 Then
		$msg &= "   Usage:\n"
		Local $szfmt = "\t%-6s%-15s  %s\r\n", $arg0, $arg1
		For $x = 1 To $iIndex
			If BitAND($aOptions[$x][$OPT_TYPE],$OPT_ARG_HIDDEN) <> $OPT_ARG_HIDDEN Then
				$arg0 = $aOptions[$x][0]
				$arg1 = $aOptions[$x][1]
				If $arg0 <> "" Then $arg0 = "-" & $arg0
				If $arg1 <> "" Then $arg1 = "--" & $arg1
				$msg &= StringFormat($szfmt, $arg0, $arg1, $aOptions[$x][3])
			EndIf
		Next
		$msg = StringFormat($msg) & @CRLF
		_OptParse_Display($msg, "Usage", $iFlag)
		Return 1
	EndIf
	Return SetError(1, 0, 0)
EndFunc   ;==>_OptParse_ShowUsage

; #FUNCTION# ====================================================================================================================
; Name ..........: _OptParse_ShowVersion
; Description ...: Displays a version message
; Parameters ....: $aOptions - IN - An array of options/switches
;                  $iFlag - IN/OPTIONAL - Specifies where to display message
;                  |0 - Display to console
;                  |1 - Display in a messagebox
; Return values .:
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Modified.......:
; Remarks .......: The version message is comprised of the version information supplied to _OptParse_Init.
;                  Each of the 3 string values is displayed on a new line.
;                  If iFlag =0 then the message is sent to the console, if iFlag >0 displays in a messagebox
; Related .......: _OptParse_ShowUsage
; Link ..........;
; Example .......; [yes/no]
; ===============================================================================================================================
Func _OptParse_ShowVersion($aOptions, $iFlag = 0)
	_OptParse_Display(StringFormat($aOptions[0][1] & $aOptions[0][2] & $aOptions[0][3]), "Version", $iFlag)
EndFunc   ;==>_OptParse_ShowVersion

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OptParse_Scrub
; Description ...: Removes an element from an array and re-dimensions the array
; Parameters ....: $aOpt_Array - IN/OUT - The array to redimension
; Return values .: On Success - True
;                  On Failure - False
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Modified.......:
; Remarks .......: For internal use only
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _OptParse_Scrub(ByRef $aOpt_Array)
	Local $x
	If Not IsArray($aOpt_Array) Then Return SetError(1, 0, False)
	For $x = 1 To UBound($aOpt_Array) - 1
		$aOpt_Array[$x - 1] = $aOpt_Array[$x]
	Next
	$aOpt_Array[UBound($aOpt_Array) - 1] = ""
	If UBound($aOpt_Array) > 1 Then
		ReDim $aOpt_Array[UBound($aOpt_Array) - 1]
	EndIf
	Return True
EndFunc   ;==>_OptParse_Scrub

; #FUNCTION# ====================================================================================================================
; Name ..........: _OptParse_Display
; Description ...: Wrapper for displaying a message.
; Parameters ....: $szMsg - IN - The message to display
;                  $szTitle - IN/OPTIONAL - The title to display
;                  $iFlag - IN/OPTIONAL - Specifies where to display the message
;                  |0 - Display to console
;                  |1 - Display in a messagebox
; Return values .: None
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Modified.......:
; Remarks .......: If iFlag is not specified, then iFlag is set to the Global variable $OPT_DISPLAY.
;                  If iFlag =0 then the message is sent to the console, if iFlag >0 displays in a messagebox

; Related .......:
; Link ..........;
; Example .......; [yes/no]
; ===============================================================================================================================
Func _OptParse_Display($szMsg, $szTitle = "Notice", $iFlag = -1)
	If $iFlag = -1 Then $iFlag = $OPT_DISPLAY
	If $iFlag = 0 Then
		ConsoleWrite(StringFormat("%s: %s\r\n", $szTitle, $szMsg))
	Else
		MsgBox(266288, $szTitle, $szMsg)
	EndIf
EndFunc   ;==>_OptParse_Display

; #FUNCTION# ====================================================================================================================
; Name ..........: _OptParse_SetDisplay
; Description ...: Sets the Global $OPT_DISPLAY variable
; Parameters ....: $iDisplay - IN/OPTIONAL - Specifies the display
; Return values .: The old display value
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Modified.......:
; Remarks .......: If iDisplay =0 then the display is set to console, If >0 then to a messagebox
;                  A convenience funtion.
; Related .......:
; Link ..........;
; Example .......; [yes/no]
; ===============================================================================================================================
Func _OptParse_SetDisplay($iDisplay = 0)
	Local $iTemp = $OPT_DISPLAY
	If $iDisplay > 1 Then $iDisplay = 1
	$OPT_DISPLAY = $iDisplay
	Return $iTemp
EndFunc   ;==>_OptParse_SetDisplay

; #FUNCTION# =====================================================================================================================
; Name ..........: _OptParse_GetOpts
; Description ...: Parses the command line arguments into a 2 dim array
; Parameters ....: $aOpt_args - IN/OUT - Commandline arguments.  This variable is modified.
;                  $aValidOptions - IN - String of short options  "abco:"  etc.
; Return values .: On Success - A two dim array with the option in element 0 of second dim and param (if any) in elememt 1
;                  On Failure - 0 and @error set to one of the following
;                  |1 - No arguments passed
;                  |2 - Invalid argument
;                  |3 - Duplicate argument
;                  |4 - Invalid switch or parameter
; Author ........: Stephen Podhajecki {gehossafats at netmdc. com}
; Remarks .......: When a commandline option is found, it is removes from the list and places in the 2D array.
;                  $aOpt_args will contain only non-option arguments when the function returns. If a param is designated
;                  as type $OPT_ARG_MULTI, then each item following is added to the value string until the end of the
;                  params is reached or another valid parameter is found. The value string will be comma delimited.
; Related .......:
; ================================================================================================================================
Func _OptParse_GetOpts(ByRef $aOpt_args, $aValidOptions)
	If Not IsArray($aOpt_args) Then Return SetError(1, 0, 0)
	If Not IsArray($aValidOptions) Then Return SetError(1, 0, 0)
	If $aOpt_args[0] = 0 Then Return SetError(1, 0, 0)
	Local $aCmdLn[StringLen($CmdLineRaw)]
	Local $aOpts[StringLen($CmdLineRaw)][2]
	Local $sOpt_argv0, $sOpt_argv1, $i, $x
	$aCmdLn[0] = 0
	For $x = 1 To $aOpt_args[0]
		If StringLeft($aOpt_args[$x], 2) = "--" Then $aOpt_args[$x] = StringTrimLeft($aOpt_args[$x], 1)
		If StringLeft($aOpt_args[$x], 1) = "-" Or StringLeft($aOpt_args[$x], 1) = "/" Then
			$i = StringInStr($aOpt_args[$x], "=")
			If $i > 0 Then
				$sOpt_argv0 = StringTrimLeft(StringLeft($aOpt_args[$x], $i - 1), 1)
				$sOpt_argv1 = StringTrimLeft($aOpt_args[$x], $i - 1)
			Else
				If $x < $aOpt_args[0] Then
					If StringLeft($aOpt_args[$x + 1], 1) <> "-" And StringLeft($aOpt_args[$x + 1], 1) <> "/" Then
						$sOpt_argv0 = StringTrimLeft($aOpt_args[$x], 1)
						$sOpt_argv1 = $aOpt_args[$x + 1]
						$x += 1
					Else
						$sOpt_argv0 = StringTrimLeft($aOpt_args[$x], 1)
						$sOpt_argv1 = ""
					EndIf
				Else
					$sOpt_argv0 = StringTrimLeft($aOpt_args[$x], 1)
					;$sOpt_argv0 = $aOpt_args[$x]
					$sOpt_argv1 = ""
				EndIf
			EndIf
			If $sOpt_argv0 <> "" Then
				Local $bMatch = False
				For $y = 0 To $aValidOptions[0][0]
					;If $sOpt_argv0 == $aValidOptions[$y][$OPT_SHORT] Or $sOpt_argv0 = $aValidOptions[$y][$OPT_LONG] Then
					If $sOpt_argv0 == $aValidOptions[$y][$OPT_SHORT] Or $sOpt_argv0 == $aValidOptions[$y][$OPT_LONG] Then
						;;ConsoleWrite("Matched "&$sOpt_argv0& " to "& $aValidOptions[$y][$OPT_SHORT] & "," & $aValidOptions[$y][$OPT_LONG]& @crlf)
						$bMatch = True
						Select
							Case BitAnd($aValidOptions[$y][$OPT_TYPE],$OPT_ARG_REQ) = $OPT_ARG_REQ
								If $sOpt_argv1 = "" Then
									_OptParse_Display("Invalid argument: " & $sOpt_argv0 & " requires a value." & @LF)
									Return SetError(2, 0, 0)
								EndIf
							Case  BitAnd($aValidOptions[$y][$OPT_TYPE],$OPT_ARG_NONE) = $OPT_ARG_NONE
								If $sOpt_argv1 <> "" Then
									$aCmdLn[$aCmdLn[0] + 1] = $sOpt_argv1
									$aCmdLn[0] += 1
									$sOpt_argv1 = ""
								EndIf
							Case BitAnd($aValidOptions[$y][$OPT_TYPE],$OPT_ARG_OPTIONAL) = $OPT_ARG_OPTIONAL
								If $sOpt_argv1 <> "" Then
									If StringLeft($sOpt_argv1, 1) == "=" Then
										$sOpt_argv1 = StringTrimLeft($sOpt_argv1, 1)
									Else
										$aCmdLn[$aCmdLn[0] + 1] = $sOpt_argv1
										$aCmdLn[0] += 1
										$sOpt_argv1 = ""
									EndIf
								EndIf
							Case BitAND($aValidOptions[$y][$OPT_TYPE],$OPT_ARG_MULTI) = $OPT_ARG_MULTI
								Local $yy
								$sOpt_argv1 = ""
								For $yy = $x To $aOpt_args[0]
									If StringLeft($aOpt_args[$yy], 1) = "-" Or StringLeft($aOpt_args[$yy], 1) = "/" Then
										ExitLoop
									Else
										If $sOpt_argv1 <> "" Then
											$sOpt_argv1 &= "," & $aOpt_args[$yy]
										Else
											$sOpt_argv1 &= $aOpt_args[$yy]
										EndIf
									EndIf
								Next
								If $sOpt_argv1 = "" Then
									_OptParse_Display("Invalid argument: " & $sOpt_argv0 & " requires one or more values." & @LF)
									Return SetError(2, 0, 0)
								EndIf
								$x = $yy
						EndSelect
						If $aValidOptions[$y][$OPT_COUNT] > 0 Then
							_OptParse_Display("Duplicate argument: " & $sOpt_argv0 & @LF)
							Return SetError(3, 0, 0)
						EndIf
						$aValidOptions[$y][$OPT_COUNT] += 1
						$aOpts[$aOpts[0][0] + 1][0] = $sOpt_argv0
						$aOpts[$aOpts[0][0] + 1][1] = $sOpt_argv1
						$aOpts[0][0] += 1
						ExitLoop
					EndIf
				Next
				If $bMatch = False Then
					_OptParse_Display("Invalid Parameter: " & $aOpt_args[$x] & @LF)
					Return SetError(4, 0, 0)
				EndIf
			EndIf
		Else
			$aCmdLn[0] += 1
			$aCmdLn[$aCmdLn[0]] = $aOpt_args[$x]
		EndIf
	Next
	ReDim $aCmdLn[$aCmdLn[0] + 1]
	ReDim $aOpts[$aOpts[0][0] + 1][2]
	$aOpt_args = $aCmdLn
	Return $aOpts
EndFunc   ;==>_OptParse_GetOpts
