#Persistent
#NoEnv
#SingleInstance, force
#Include %A_ScriptDir%\data_client.ahk
#Include %A_ScriptDir%\radio_box.ahk
#Include %A_ScriptDir%\csv.ahk
#Include %A_ScriptDir%\Jxon_Load.ahk

SetWorkingDir, %A_ScriptDir%

global FilePath := "events_reader\events.csv"
if(IsSet(FilePathCustom)){
    FilePath := FilePathCustom
}

global interval := 0.5 ; set the interval
global ConfigDone := false
global DeviceUniq := A_ComputerName
; IconeFile := %A_ScriptDir%\logo_tag_hunter_favicon.ico
ImageFile = logo_tag_hunter.png

Menu, Tray, Icon, logo_tag_hunter_favicon.ico

DeviceName := checkRegistered()

; MsgBox, % FilePath
if(DeviceName){

    DeviceName:=SubStr(DeviceName,1,StrLen(DeviceName)-1)
    StringTrimLeft, DeviceName, DeviceName, 1

    CSV_Load(FilePath, data, ";")

    global LastCountRows := CSV_TotalRows(data)

    IfWinNotExist, SPORTident.ReaderUI
        Run, C:\Program Files (x86)\SPORTident\ReaderUI\SPORTident.ReaderUI.exe

    json_str = {"licence_number": "%LicenceNumber%"}

    oWhr := SendTaghunterHttpRequest("GET", "checkLaunchedGame", json_str)
    responseText := StrReplace(oWhr.ResponseText, "\", "")
    responseText:=SubStr(responseText,1,StrLen(responseText)-1)
    StringTrimLeft, responseText, responseText, 1

    Response :=StrSplit(responseText, "&")

    ; if(oWhr.Status == 201){
    ;     ResponseSent = % oWhr.ResponseText
    ;     ArrayResponse := Jxon_Load(ResponseSent)
    ;     ; setGui(DeviceName, ArrayResponse)
    ; }else{
    ;     ;  setGui(DeviceName, false)
    ; }

    Gui, New,,Taghunter
    Gui, Add, Picture,w80 h80, %ImageFile%
    Gui, Font, s10
    Gui, Add, Text,, Nom du poste: %DeviceName%

    Gui, Add, Text,, Configuration
    Gui, Add, Radio, vConfig, Ajout de puce
    Gui, Add, Radio, , Ajout de balise
    Gui, Add, Button,default, Connecter pour Configuration
    Gui, Add, Text,, Mes jeux en cours
    Gui, Add, Radio, vGame checked, % Response[1]
    Arraycount := 2
    Loop ;number of items in array - 1
    {
        Gui, Add, Radio,, % Response[Arraycount]
        Arraycount := ++Arraycount
    }	until Response[Arraycount] = ""
    ; Gui, Add, Button,default, Chercher les jeux en cours ; The label ButtonOK (if it exists) will be run when the button is pressed.
    Gui, Add, Button,default, Lancer le Jeu
    Gui, Show, w640 h480 Center, TAG HUNTER
    return

    ; ButtonChercherLesJeuxEnCours:
    ;     reload
    ;     return
    ButtonConnecterPourConfiguration:
            Gui, Submit, NoHide
      
      If(config = 1){
        Run, chrome.exe "https://dev.taghunter.fr/taghunter/public/puces?from_device=%DeviceUniq%" " --new-window "
        SetTimer, LaunchGame, %interval%
      }else if(config = 2 ){
        Run, chrome.exe "https://dev.taghunter.fr/taghunter/public/balises?from_device=%DeviceUniq%" " --new-window "
        SetTimer, LaunchGame, %interval%
      }
        ;  Gui, Submit, NoHide


    return 
    ButtonLancerLeJeu:
        Gui, Submit, NoHide
        Entry := StrSplit(Response[game], "#")
        gameName := Entry[1]
        gameId := Entry[2]
    ;    MsgBox, % game
        Msgbox 4, Confirm, Vous allez lancer le jeu %gameName%? Voulez-vous ouvrir la page sur votre navigateur?

        IfMsgBox NO
        {

        }
        Else{
            ; Run, chrome.exe "https://dev.taghunter.fr/taghunter/public/jeux/tagquest/launched/%gameId%?from_device=%DeviceUniq%&launched_game_id=%gameId%" " --new-window "
            ; SetTimer, LaunchGame, %interval%
        }
    return 
    ;    Substr(response[batt], 1, Instr(response[batt], " ")-1)

    ;     Gui, Submit
    ;     WinActivate, Untitled - Notepad

    ; Send % radio[batt]

    ;InitGame(DeviceName)
    ; SetTimer, InitGame, %interval%
    ; SetGui(DeviceName)

    ; SetTimer, LaunchGame, %interval%
    ; return
    ; GuiClose:
    ; ExitApp
}

setGui(DeviceName, games){
    ; Gui, New,+AlwaysOnTop,Taghunter
    ; Gui, Font, s10
    ; Gui, Add, Text,, Nom du poste: %DeviceName%
    ; Gui, Add, Text,, Mes jeux en cours

    ; list = Buy milk|Buy Coffee|Write a Book

    ; Gui, Add, ListView, r10 -ReadOnly Checked, TagQuest
    ; Loop, Parse, list, |
    ;     LV_Add("",A_LoopField)
    ; if(games){
    ;     indexLoop = 0
    ;     for index, value in games{

    ;             Gui, Add, Text,, %value% (%index%) 
    ;             Gui, Add, Button,default, Lancer le Jeu %index%

    ;         ; if(indexLoop == 0){
    ;         ; Gui, Add, Radio, Group, % k
    ;         ; }else{

    ;         ; }
    ;         ; ; Gui, Add, Radio,  gCheck v, K

    ;         indexLoop := indexLoop + 1

    ;          ButtonLancerLeJeu%index%:
    ;            MsgBox, % StrReplace("Blop", "\u00e9", Chr(0x00e9))

    ;     }
    ; }else{ ; else display "No games available"
    ;     Gui, Add, Text,, Aucun jeu en cours
    ; }
    ; Gui, Add, Button,default, Chercher les jeux en cours ; The label ButtonOK (if it exists) will be run when the button is pressed.
    ; Gui, Add, Button,default, Lancer le Jeu ;
    ; Gui, Show, AutoSize Center

    ; GuiClose:
    ; ExitApp

    ; ButtonLancerLeJeu:
    ;     Gui, Submit
    ;     WinActivate, Untitled - Notepad
    ;     Send % radio[batt]
    ; TrayTip, , % vradio_border
}

InitGame(DeviceName)
{

    json_str = {"licence_number": "%LicenceNumber%"}

    oWhr := SendTaghunterHttpRequest("GET", "checkLaunchedGame", json_str)
    MsgBox, % StrReplace(oWhr.ResponseText, "\u00e9", Chr(0x00e9))

    if(oWhr.Status == 201){
        ResponseSent = % oWhr.ResponseText
        ArrayResponse := Jxon_Load(ResponseSent)
        setGui(DeviceName, ArrayResponse)
    }else{
        setGui(DeviceName, false)
    }

    ; ButtonChercherLesJeuxEnCours:
    ;     Gui, Submit, NoHide
    ;first get launched foreach

    ; TrayTip, "Taghunter" , %json_str%
    ; oWhr := SendTaghunterHttpRequest("GET", "checkLaunchedGame", json_str)

    ; if(oWhr.Status == 201){ ; if some games ->display RadioBox

    ; }else{ ; else display "No games available"
    ;     Gui, Add, Text,, Aucun jeu en cours
    ; }

    ;     Gui, Add, Text,, Aucun jeu en cours
    ;     Gui, Add, Button, gNew, Chercher les jeux en cours ; The label ButtonOK (if it exists) will be run when the button is pressed.
    ;     Gui, Show

    ; ButtonChercherLesJeuxEnCours:
    ;     Gui, Add, Text, xs, New Field
    ;     Gui, Show, AutoSize, Test
    ; return
    ; Gui, Add, Text,, bop
    ;           Gui, Show
    ; json_str = {"licence_number": "%LicenceNumber%", "DeviceUniq": "%DeviceUniq%"}
    ; oWhr := SendTaghunterHttpRequest("GET", "checkLaunchedGame", json_str)

    ; if(oWhr.Status == 201){

    ;     FoundPos := InStr(oWhr.ResponseText, "en cours")
    ;     if(FoundPos){
    ;         global ConfigDone := true
    ;         SetTimer, Init, OFF
    ;         TrayTip, % "Taghunter" , % oWhr.ResponseText, 1

    ;     }else{

    ;         ArrayResponse := Jxon_Load(oWhr.ResponseText)
    ;         thelist := ""
    ;         indexLoop = 0
    ;         for k, v in ArrayResponse{

    ;             if(indexLoop == 0){
    ;                 thelist := k ", id" v
    ;             }else{
    ;                 thelist := thelist " |" k ", id" v
    ;             }
    ;             ; Gui, Add, Radio,  gCheck v, K

    ;             indexLoop := indexLoop + 1
    ;         }

    ;         ; Result := RadioBox("Configuration","Choisissez le jeu en cours", thelist ,false )

    ;         ; StringSplit, string, Result, id
    ;         ; string := string%string0%
    ;         ; TrayTip, , % string

    ;         ; Run, chrome.exe "https://dev.taghunter.fr/taghunter/public/jeux/tagquest/launched/%string%?from_device=%device%&launched_game_id=%string%" " --new-window "
    ;         ; global ConfigDone := true
    ;     }

    ; }

    ; TrayTip, "Taghunter" , % StrReplace(oWhr.ResponseText, "\u00e9", Chr(0x00e9))
    return 
}

Register(deviceName) {

    json_str = {"licence_number": "%LicenceNumber%", "device_name":"%deviceName%", "device_uniq":"%DeviceUniq%"}

    oWhr := SendTaghunterHttpRequest("POST","registerDevice", json_str)

    ArrayResponse := Jxon_Load(oWhr.ResponseText)
    if(oWhr.Status == 201){
        global IsRegistered := true 
        TrayTip, "Taghunter" , % StrReplace(oWhr.ResponseText, "\u00e9", Chr(0x00e9))
    }else{
        MsgBox, % oWhr.ResponseText
    }

}

checkRegistered() {
    json_str = {"licence_number": "%LicenceNumber%", "device_uniq":"%DeviceUniq%"}
    oWhr := SendTaghunterHttpRequest("GET", "checkDeviceRegistration", json_str)

    if(oWhr.Status == 401){
        Msgbox 4, Confirm, Ce poste n'est pas enregistré. Voulez-vous ajouter ce poste à votre compte?

        IfMsgBox NO
        {
            ExitApp
        }
        Else{
            InputBox, UserInput, Nom du poste, Donnez un nom à ce poste.
            if ErrorLevel
                ExitApp
            else
                Register(UserInput)
            return UserInput
        }
    }
    else if(oWhr.Status == 301) {
        MsgBox, % StrReplace(oWhr.ResponseText, "\u00e9", Chr(0x00e9))
    }
    else {
    return oWhr.ResponseText ; return the device name
}
}
; if(!IsSet(IsRegistered)){
;     Register()
; }

;

; IfWinNotExist, SPORTident.ReaderUI
;     Run, C:\Program Files (x86)\SPORTident\ReaderUI\SPORTident.ReaderUI.exe

; a := 12

; fn := Func("Init").Bind(ConfigDone)

; SetFileMonitoring(FolderPath, interval)

LaunchGame(){

    CSV_Load(FilePath, "data", ";")

    CountRows:=CSV_TotalRows("data")

;    TrayTip, "Taghunter" , % CountRows
    if(CountRows > LastCountRows){

        LastCountRows := CountRows
        ;    TrayTip, "Taghunter" , % LastCountRows
        TrayTip, "Taghunter" , % "Envoi en cours"
        Cols:=CSV_TotalCols("data")
        Last_Row := CSV_ReadRow("data", 3)
      MsgBox, % CountRows
      MsgBox, % Last_Row

        oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        oWhr.Open("POST", "https://dev.taghunter.fr/taghunter/public/api/api", false)
        oWhr.SetRequestHeader("Content-Type", "application/json")
        oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")
        ;TODO set variable number of rows=>if new number > old number =>send

        json_str = {"lastLine": "%Last_Row%", "licence_number": "%LicenceNumber%", "device_uniq":"%DeviceUniq%"}

        oWhr.Send(json_str)
    }else{

    }
    ;                MsgBox % "LastCountRows msg" LastCountRows
    ;                MsgBox % "CountRows msg" LastCountRows
    ; TrayTip, "Taghunter" , % "CountRows" CountRows
    ; TrayTip, "Taghunter" , % "LastCountRows" LastCountRows
    ; if(CountRows > LastCountRows){

    ;     LastCountRows = CountRows
    ; }

}
CheckDevice() {
    json_str = {"licence_number": "%LicenceNumber%", "device_uniq":"%DeviceUniq%"}
    ; oWhr := sendHttpRequest("checkDevice", json_str)
    ; oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    ; oWhr.Open("GET", "https://dev.taghunter.fr/taghunter/public/api/checkDevice", false)
    ; oWhr.SetRequestHeader("Content-Type", "application/json")
    ; oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")
    ; ;TODO set variable number of rows=>if new number > old number =>send

    ; json_str = {"licence_number": "%LicenceNumber%", "device_uniq":"%DeviceUniq%"}

    ; oWhr.Send(json_str)

    if(oWhr.Status == 201){
        ArrayResponse := Jxon_Load(oWhr.ResponseText)
        global DeviceName := ArrayResponse

        TrayTip, , "Vous lancez le jeu sur le poste: " %DeviceName%
    }else{
        Response :=oWhr.ResponseText
        ; TrayTip, , %Response%
        MsgBox % Response
    }
}

SendTaghunterHttpRequest(method, httpPath, json_str){

    fullPath :="https://dev.taghunter.fr/taghunter/public/api/" httpPath
    oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    oWhr.Open(method, fullPath, false)
    oWhr.SetRequestHeader("Content-Type", "application/json")
    oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")
    oWhr.Send(json_str)

    return oWhr
}

SetFileMonitoring(FolderPath, interval) {

    static winmgmts := ComObjGet("winmgmts:"), createSink

    SplitPath, FolderPath,,,,, Drive
    Folder := RegExReplace(FolderPath, "[A-Z]:\\|((?<!\\)\\(?!\\)|(?<!\\)$)", "\\")

    ComObjConnect(createSink := ComObjCreate("WbemScripting.SWbemSink"), "FileEvent_")

    winmgmts.ExecNotificationQueryAsync(createSink
    , "Select * From __InstanceOperationEvent"
    . " within " interval
    . " Where Targetinstance Isa 'CIM_DataFile'"
    . " And TargetInstance.Drive='" Drive "'"
    . " And TargetInstance.Path='" Folder "'")

}

FileEvent_OnObjectReady(objEvent)
{

    TrayTip, "Taghunter" , % "Envoi en cours"
    if (objEvent.Path_.Class = "__InstanceModificationEvent")
        CSV_Load(FilePath,"data", ";")

    Rows:=CSV_TotalRows("data")
    Cols:=CSV_TotalCols("data")
    Last_Row := CSV_ReadRow("data", Rows)

    oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    oWhr.Open("POST", "https://dev.taghunter.fr/taghunter/public/api/api", false)
    oWhr.SetRequestHeader("Content-Type", "application/json")
    oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")
    ;TODO set variable number of rows=>if new number > old number =>send

    json_str = {"lastLine": "%Last_Row%", "licence_number": "%LicenceNumber%", "device":"%Device%"}

    oWhr.Send(json_str)

    ;TODO if game ended ExitApp
    ;TrayTip, % StrReplace(oWhr.ResponseText, "\u00e9", Chr(0x00e9))

}

Init()
{
    if(!ConfigDone){

        oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        oWhr.Open("GET", "https://dev.taghunter.fr/taghunter/public/api/checkLaunchedGame", false)
        oWhr.SetRequestHeader("Content-Type", "application/json")
        oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")
        ;TODO set variable number of rows=>if new number > old number =>send

        ; json_str = {"licence_number": "825005c33898011bc494a6e46ace4a16", "device":"2"}
        json_str = {"licence_number": "%LicenceNumber%", "device": "%Device%"}

        oWhr.Send(json_str)

        if(oWhr.Status == 201){

            FoundPos := InStr(oWhr.ResponseText, "en cours")
            if(FoundPos){
                global ConfigDone := true
                SetTimer, Init, OFF
                TrayTip, % "Taghunter" , % oWhr.ResponseText, 1

            }else{
                ; ArrayResponse := Jxon_Load(oWhr.ResponseText)
                thelist := ""
                indexLoop = 0
                for k, v in ArrayResponse{

                    if(indexLoop == 0){
                        thelist := k ", id" v
                    }else{
                        thelist := thelist " |" k ", id" v
                    }
                    indexLoop := indexLoop + 1
                }

                Result := RadioBox("Configuration","Choisissez le jeu en cours", thelist ,false )

                StringSplit, string, Result, id
                string := string%string0%
                TrayTip, , % string

                Run, chrome.exe "https://dev.taghunter.fr/taghunter/public/jeux/tagquest/launched/%string%?from_device=%device%&launched_game_id=%string%" " --new-window "
                global ConfigDone := true
            }

        }else{

            ; ResultNoGame := RadioBox("Configuration","Choisissez le jeu en cours", thelist ,false )
            Msgbox 4, Confirm, Aucun jeu en cours. Voulez-vous être rédirigé vers votre compte Taghunter?
            IfMsgBox No
            ExitApp
            ; MsgBox % ArrayResponse
            Run, chrome.exe "https://dev.taghunter.fr/taghunter/public/jeux" " --new-window "
            MsgBox % StrReplace(oWhr.ResponseText, "\u00e9", Chr(0x00e9))
        }

    }
    else{

        SetTimer, Init, OFF
    return true
}
}
