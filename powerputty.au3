#include <GUIConstantsEx.au3>
#include <Date.au3>

dim $PowerPutty                = "PowerPutty"
;==============================================================================
; CHANGE MEs
;==============================================================================
dim $global_working_directory  = "/home/<user>"
dim $global_powerputty_home    = $global_working_directory & "/powerputty"

dim $global_secBetweenCmds     = 4000
dim $configfile                = "config.txt"
dim $global_locallistofnewcheckoutfiles_dot_txt     = "newcheckout.txt"
dim $global_previously_check_out_files_dot_txt      = "oc.txt"
dim $global_previously_check_out_files_dot_zip      = "oc.zip"
dim $global_new_check_out_files_dot_txt             = "nc.txt"
dim $global_new_check_out_files_dot_zip             = "nc.zip"

dim $global_temp_directory                          = $global_powerputty_home & "/tmp" 
dim $global_temp_zip_directory                      = $global_powerputty_home & "/tmp-zip" 
dim $global_directory_arc_checkedout_files_dot_zip  = $global_powerputty_home & "/archived/previous-checkedout-files"
dim $global_directory_new_checkedout_files_dot_zip  = $global_powerputty_home & "/modify/new-checkedout-files"

;==============================================================================
; CONFIGURATION VARIABLES
;==============================================================================
dim $cfg_puttySavedSessionName 
dim $cfg_ctDEVStreams
dim $cfg_puttyUsr
dim $cfg_ftp_servers
dim $cfg_puttyPwd
dim $cfg_product_versions
dim $cfg_ftp_user
dim $cfg_ftp_pwd

;==============================================================================
; OS TEMPS
;==============================================================================
dim $temp_directory = ""
dim $file

;==============================================================================
; START - READ MAIN CONFIGURATIONS
;==============================================================================
$file = FileOpen($configfile, 0)
While 1        
    $line = FileReadLine($file)        
    If @error = -1 then ExitLoop        
        
    $TemporaryArray = StringSplit ( $line , "=");        
    
    ; HOST NAMES COME FIRST IN CONFIG.TXT
    If $TemporaryArray[1] = "ct-hosts" Then 
        $cfg_puttySavedSessionName = $TemporaryArray[2]
    EndIf
    
    ; DEV STREAMS
    If $TemporaryArray[1] = "dev-streams" Then 
        $cfg_ctDEVStreams = $TemporaryArray[2]
    EndIf
    
    ; CT USER NAME
    If $TemporaryArray[1] = "ct-uname" Then 
        $cfg_puttyUsr = $TemporaryArray[2]
    EndIf
    
    ; CT USER PWD
    If $TemporaryArray[1] = "ct-pwd" Then
        $cfg_puttyPwd = $TemporaryArray[2]
    EndIf
    
    ; PRORUCT VERSIONS 
    If $TemporaryArray[1] = "product-versions" Then 
        $cfg_product_versions= $TemporaryArray[2]
    EndIf
    
    ; FTP Servers
    If $TemporaryArray[1] = "ftp-servers" Then ; Desktop FTP
        $cfg_ftp_servers= $TemporaryArray[2] 
    EndIf

    If $TemporaryArray[1] = "ftp-user" Then ; remote ftp
        $cfg_ftp_user= $TemporaryArray[2] 
    EndIf
    
    If $TemporaryArray[1] = "ftp-pwd" Then ; remote ftp
        $cfg_ftp_pwd= $TemporaryArray[2] 
    EndIf    
Wend
FileClose($file)
;==============================================================================
; END - READ MAIN CONFIGURATIONS
;==============================================================================


;==============================================================================
; START - GRAPHICAL USER INTERFACE STUFF
;==============================================================================

; CHANGE TO ONEVENT MODE
Opt("GUIOnEventMode", 1)  
$mainwindow = GuiCreate($PowerPutty , 300, 300)
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEClicked")

; COMMON COMBO BOX - SERVERS
$ComboBoxServer= GuiCtrlCreatecombo("", 5, 10, 200, 100)
GuiCtrlSetData(-1,$cfg_puttySavedSessionName, "")

; CREATES TABS - DEV, VER, AND MAKE PATCH

; DEV TAB
GuiCtrlCreateTab(5, 40, 290, 250)
GuiCtrlCreateTabItem("DEV")
$ComboBoxDev = GuiCtrlCreatecombo("", 10, 70, 200, 100)
GuiCtrlSetData(-1,$cfg_ctDEVStreams, "")
$okbuttonDev = GUICtrlCreateButton("Okay, launch!", 10, 256, 100)
GUICtrlSetOnEvent($okbuttonDev, "OKButtonDev")

; TF TAB
GuiCtrlCreateTabItem("VER")
$ComboBoxVer = GuiCtrlCreatecombo("", 10, 70, 200, 100)
GuiCtrlSetData(-1, $cfg_product_versions, "")
$OKButtonVer = GUICtrlCreateButton("Okay, launch!", 10, 256, 100)
GUICtrlSetOnEvent($OKButtonVer, "OKButtonVer")

; TF - MAKE PATCH TAB
GuiCtrlCreateTabItem("Make Patch")
$ComboBoxVerType = GuiCtrlCreatecombo("", 10, 70, 200, 100)
GuiCtrlSetData(-1, $cfg_product_versions, "")

; FTP SERVERS
$ComboBoxDesktopIP = GuiCtrlCreatecombo("", 10, 100, 200, 100)
GuiCtrlSetData(-1, $cfg_ftp_servers, "")

; PMRs and APARs TO BE SPECIFIED BY USER
$PMRS= GuiCtrlCreateInput("-PMRS-", 10, 130, 200, 20)
$APARS=GuiCtrlCreateInput("-APARS-", 10, 160, 200, 20)

$prepPatchBuild = GUICtrlCreateButton("Prep Patch build", 10, 220, 100)
GUICtrlSetOnEvent($prepPatchBuild, "OKButtonprepPatchBuild")

$buildPatch = GUICtrlCreateButton("Build Patch", 10, 256, 100)
GUICtrlSetOnEvent($buildPatch, "OKButtonBuildPatch")

GuiCtrlCreateTabItem("")
GUISetState(@SW_SHOW)

While 1
  Sleep(1000)  ; Idle around
WEnd
;==============================================================================
; END - GRAPHICAL USER INTERFACE STUFF
;==============================================================================


;==============================================================================
; START - GRAPHICAL USER INTERFACE FUNCTIONS
;==============================================================================

; GET SELECTED DEV STREAM AND TELNET SERVER
Func OKButtonDev()
    $sVar = GUICtrlRead($ComboBoxDev) 
    $sVarServer = GUICtrlRead($ComboBoxServer)    
    FuncForButtonDevAndPatch($sVarServer, $sVar)
EndFunc

; GET SELECTED TF STREAM AND TELNET SERVER
Func OKButtonVer()
    $sVar = GUICtrlRead($ComboBoxVer) 
    $sVarServer = GUICtrlRead($ComboBoxServer)
    FuncForButtonDevAndPatch($sVarServer, $sVar)    
EndFunc

Func FuncForButtonDevAndPatch($server, $streamView)
    
    If $server = "" OR $streamView = "" Then
        MsgBox(0, $PowerPutty , "Server and/or View not defined.")
        return
    EndIf
    
    $answer = MsgBox(4, $PowerPutty, _ 
                        "This will run PuTTY for ***" & _ 
                        $server & "*** and use ***" & _ 
                        $streamView & "***. Do you want to run it?")
    If $answer = 7 Then
        return
    EndIf
    
    ; LOG IN TO SELECTED TELNET SERVER
    LoginTelnet($server, $cfg_puttyUsr, $cfg_puttyPwd, $global_secBetweenCmds) 
    SetCurrentCleartoolStream($streamView, $global_secBetweenCmds)    
EndFunc    


; *** 
Func OKButtonprepPatchBuild()
    $tyType     = GUICtrlRead($ComboBoxVerType) 
    $sVarServer = GUICtrlRead($ComboBoxServer)
    $remoteftp  = GUICtrlRead($ComboBoxDesktopIP)
    
    MsgBox(7, $PowerPutty , "Server and/or Version Type not defined.")
    If $sVarServer = "" OR $tyType = "" Then
        MsgBox(0, $PowerPutty , "Server and/or Version Type not defined.")
        return
    EndIf

    $local_timestamp = GetCustomTimeStamp()    
    PreparePatch($remoteftp, $cfg_ftp_user, $cfg_ftp_pwd, _ 
                 $sVarServer, $cfg_puttyUsr, $cfg_puttyPwd, _ 
                   $tyType, _ 
                   $local_timestamp & $global_previously_check_out_files_dot_txt, _ 
                   $local_timestamp & $global_previously_check_out_files_dot_zip, _ 
                   $local_timestamp & $global_new_check_out_files_dot_txt, _ 
                   $local_timestamp & $global_new_check_out_files_dot_zip, _ 
                   $global_temp_directory, $global_temp_zip_directory, _ 
                   $global_directory_arc_checkedout_files_dot_zip, _ 
                   $global_directory_new_checkedout_files_dot_zip, _ 
                   $global_locallistofnewcheckoutfiles_dot_txt, _
                   $global_secBetweenCmds)    
EndFunc

Func OKButtonBuildPatch()
    $tyType     = GUICtrlRead($ComboBoxVerType) 
    $sVarServer = GUICtrlRead($ComboBoxServer)
    $remoteftp  = GUICtrlRead($ComboBoxDesktopIP)
    
    MsgBox(7, $PowerPutty , "Server and/or Version Type not defined.")
    If $sVarServer = "" OR $tyType = "" Then
        MsgBox(0, $PowerPutty , "Server and/or Version Type not defined.")
        return
    EndIf

    $local_timestamp = GetCustomTimeStamp()    
    PreparePatch($remoteftp, $cfg_ftp_user, $cfg_ftp_pwd, _ 
                 $sVarServer, $cfg_puttyUsr, $cfg_puttyPwd, _ 
                   $tyType, _ 
                   $local_timestamp & $global_previously_check_out_files_dot_txt, _ 
                   $local_timestamp & $global_previously_check_out_files_dot_zip, _ 
                   $local_timestamp & $global_new_check_out_files_dot_txt, _ 
                   $local_timestamp & $global_new_check_out_files_dot_zip, _ 
                   $global_temp_directory, $global_temp_zip_directory, _ 
                   $global_directory_arc_checkedout_files_dot_zip, _ 
                   $global_directory_new_checkedout_files_dot_zip, _ 
                   $global_locallistofnewcheckoutfiles_dot_txt, _
                   $global_secBetweenCmds)    
EndFunc

; *** 
Func CLOSEClicked()
    Exit
EndFunc

;==============================================================================
; END - GRAPHICAL USER INTERFACE FUNCTIONS
;==============================================================================


;==============================================================================
; START - FUNCTIONS
;==============================================================================
 
Func PreparePatch($ftp_remote_server, _ 
                  $ftp_remote_user, _ 
                  $ftp_remote_pwd, _ 
                  $telnetserver, _  
                  $telnetuser, _ 
                  $telnetpwd, _ 
                  $cleartoolstream, _ 
                  $listofcheckedoutfiles_dot_txt, _ 
                  $listofcheckedoutfiles_dot_zip,  _ 
                  $listofnewcheckoutfiles_dot_txt,  _ 
                  $listofnewcheckoutfiles_dot_zip, _ 
                  $tmp_directory, $tmp_zip_directory, $oc_zip_arc_dir, $nc_zip_arc_dir, _
                  $list_of_new_files_to_co_dot_txt, _
                  $delayBetweenCmds)

    $list_of_files_to_co = GetListOfFilesToCheckOut($list_of_new_files_to_co_dot_txt)
    if $list_of_files_to_co[0] = 2 then
        MsgBox(0, $PowerPutty , "It looks like you forgot to specify the list of files to check out.")
        return
    EndIf    
                  
    LoginTelnet($telnetserver, $telnetuser, $telnetpwd, $delayBetweenCmds)
    SetCurrentCleartoolStream($cleartoolstream, $delayBetweenCmds)
    PreparePatch_BackUpChanges($tmp_directory & "/" & $listofcheckedoutfiles_dot_txt, _ 
        $tmp_zip_directory & "/" & $listofcheckedoutfiles_dot_zip, $delayBetweenCmds)
    UnixCopy($tmp_zip_directory & "/" & $listofcheckedoutfiles_dot_zip, _ 
        $oc_zip_arc_dir, 1, $delayBetweenCmds)        
        
    PreparePatch_CheckOutNewFiles( _ 
        $list_of_files_to_co, _ 
        $tmp_directory  & "/" & $listofnewcheckoutfiles_dot_txt, _ 
        $tmp_zip_directory & "/" & $listofnewcheckoutfiles_dot_zip, _ 
        $delayBetweenCmds)
        
    UnixCopy($tmp_zip_directory & "/" & $listofnewcheckoutfiles_dot_zip, _ 
        $nc_zip_arc_dir, 1, $delayBetweenCmds)
        
    PreparePatch_FTPFileToRemote($ftp_remote_server, _
                            $ftp_remote_user, _ 
                            $ftp_remote_pwd, _ 
                            $nc_zip_arc_dir , _ 
                            $listofnewcheckoutfiles_dot_zip, _ 
                            "/", "put", $delayBetweenCmds)
EndFunc

Func PreparePatch_CheckOutNewFiles(ByRef $ar_list_of_files_to_check_out, _
        $list_of_new_checkedout_files, _ 
        $list_of_new_checkedout_files_zipped, _ 
        $delayBetweenCmds) 
    $filecount = 0      
    $tmp = ""    
    ; RENEW THE LIST OF NEW FILES TO BE CHECKED OUT
    $tmp = $tmp & "rm " & $list_of_new_checkedout_files & "; touch " & $list_of_new_checkedout_files & ";"
    Send($tmp & "{ENTER}")
    Sleep($delayBetweenCmds * 2)
    
    $tmp = ""
    for $i=1 to UBound($ar_list_of_files_to_check_out) - 2
        if $ar_list_of_files_to_check_out[$i] <> "" then
            $tmp = $tmp  & "find . -name " & $ar_list_of_files_to_check_out[$i] & " >> " & $list_of_new_checkedout_files & ";" 
            $filecount = $filecount + 1;
        EndIf
    Next 
    Send($tmp & "{ENTER}")
    Sleep($delayBetweenCmds * 2 * $filecount)
    
    $tmp = ""
    $tmp = $tmp & "cat " & $list_of_new_checkedout_files & " | xargs zip " & $list_of_new_checkedout_files_zipped & ";"
    Send($tmp & "{ENTER}")
    Sleep($delayBetweenCmds * 2)
    
    $tmp = ""
    ; CHECK OUT NEW FILES
    $tmp = $tmp & "ct co -nc `tr -s '\n\' ' ' < " & $list_of_new_checkedout_files & "`;"   
    Send($tmp & "{ENTER}")
    Sleep($delayBetweenCmds * $filecount)
EndFunc

Func GetListOfFilesToCheckOut($listofnewcheckoutfiles_dot_txt)
    dim $list_of_new_files_to_checkout = ""
    $file = FileOpen($listofnewcheckoutfiles_dot_txt, 0)

    While 1
        $list_of_new_files_to_checkout = $list_of_new_files_to_checkout & _ 
        FileReadLine($file) & "|"        
        If @error = -1 then ExitLoop
    Wend
        
    FileClose($file)

    dim $arr_list_of_new_files_to_checkout = StringSplit( _ 
        $list_of_new_files_to_checkout, "|")    
    
    return $arr_list_of_new_files_to_checkout
EndFunc

Func LoginTelnet($server, $username, $password, $delayBetweenCmds) 
    Run("putty " & $username & "@" & $server & " -pw " & $password)
    WinWaitActive($server & " - PuTTY")
    Sleep($delayBetweenCmds)
EndFunc

Func SetCurrentCleartoolStream($cleartoolstream, $delayBetweenCmds) 
    Sleep($delayBetweenCmds) 
    Send("bash{ENTER}")
    Sleep($delayBetweenCmds) 
    Send("ct setview "& $cleartoolstream &"{ENTER}")
    Sleep($delayBetweenCmds) 
    Send("bash{ENTER}")
    Sleep($delayBetweenCmds) 
    Send("ncwsrc; cd ..; cd ..; source profile; cd src; {ENTER}")
    Sleep($delayBetweenCmds) 
EndFunc

Func PreparePatch_BackUpChanges($list_of_prev_checkedout_files, _ 
        $list_of_prev_checkedout_files_zipped, _ 
        $delayBetweenCmds) 

    $tmp = "ct co -nc build.xml;" ; whatever file. just make sure one file is checked out
    
    ; GET THE LIST OF CHECKED OUT FILES
    $tmp = $tmp & "ct lsact -l | grep CHECKEDOUT > "   & $list_of_prev_checkedout_files & ";"    
    $tmp = $tmp & "perl -p -i -e 's/.xml.*/.xml/g' "   & $list_of_prev_checkedout_files & ";"
    $tmp = $tmp & "perl -p -i -e 's/.java.*/.java/g' " & $list_of_prev_checkedout_files & ";"
    $tmp = $tmp & "perl -p -i -e 's/.jsp.*/.jsp/g' "   & $list_of_prev_checkedout_files & ";"    
    ; How about for .js files?
    
    ; ZIP ALL PREVIOUSLY CHECKED OUT FILES
    $tmp = $tmp & "cat " & $list_of_prev_checkedout_files & " | xargs zip " & $list_of_prev_checkedout_files_zipped & ";"
    
    ; UNDO CHECK OUTS
    $tmp = $tmp & "ct unco -rm `tr -s '\n\' ' ' < " & $list_of_prev_checkedout_files & "`;"
    Send($tmp & "{ENTER}")
    Sleep($delayBetweenCmds * 2);
EndFunc

Func PreparePatch_FTPFileToRemote($ftpserver, _
                            $ftpuser, _ 
                            $ftppassword, _ 
                            $arch_dir, _ 
                            $ftpfile, _ 
                            $ftpremotedir, $ftpmode, $delayBetweenCmds)
     Send("cd " & $arch_dir &"{ENTER}")
     Sleep($delayBetweenCmds) 
     Send("ftp -gn " & $ftpserver & "{ENTER}")
     Sleep($delayBetweenCmds * 2)
     send("user " & $ftpuser & "{ENTER}")
     Sleep($delayBetweenCmds) 
     send($ftppassword & "{ENTER}")
     Sleep($delayBetweenCmds) 
     send("binary{ENTER}")
     Sleep($delayBetweenCmds) 
     send("cd " & $ftpremotedir &"{ENTER}")
     Sleep($delayBetweenCmds) 
     send($ftpmode & " " & $ftpfile & "{ENTER}")     
     Sleep($delayBetweenCmds * 10) 
     send("quit{ENTER}")
     Sleep($delayBetweenCmds) 
EndFunc

Func UnixCopy($zipFile, $zipDest, $copyOrMove, $delayBetweenCmds)     
    $tmp = "cp"
    If $copyOrMove = 1 Then  ; MOVE
        $tmp = "mv"
    EndIf    
    $tmp = $tmp & " " & $zipFile & " " & $zipDest
    Send($tmp &"{ENTER}")
    Sleep($delayBetweenCmds) 
EndFunc

Func GetCustomTimeStamp()     
    return  stringReplace(StringReplace(StringReplace(_NowCalc(),"/",""),":","")," ","")
EndFunc

;==============================================================================
; END - FUNCTIONS
;==============================================================================


