#Persistent
#NoEnv
#SingleInstance, force
#Include %A_ScriptDir%\data_client.ahk
#Include %A_ScriptDir%\radio_box.ahk
#Include %A_ScriptDir%\csv.ahk
#Include %A_ScriptDir%\Jxon_Load.ahk
#Include, %A_ScriptDir%\class.Spinner.ahk
#Include, %A_ScriptDir%\Native.ahk
#Include, %A_ScriptDir%\github.ahk
#Include, %A_ScriptDir%\auto_update.ahk

SetWorkingDir, %A_ScriptDir%

global FilePath := "events_reader\events.csv"
if(IsSet(FilePathCustom)){
    FilePath := FilePathCustom
}

global interval := 0.5 ; set the interval
global ConfigDone := false
global DeviceUniq := A_ComputerName
ImageFile = logo_tag_hunter_connect.png

Menu, Tray, Icon, logo_tag_hunter_connect_favicon.ico

;DeviceName := checkRegistered()

; if(DeviceName){

CSV_Load(FilePath, data, ";")

global LastCountRows := CSV_TotalRows(data)

IfWinNotExist, SPORTident.ReaderUI
    Run, C:\Program Files (x86)\SPORTident\ReaderUI\SPORTident.ReaderUI.exe

LaunchedGameId = 0
SearchGame = Sélectionnez le serveur

Gui, New,,Taghunter
Gui, Add, Picture, x350 y80 w80 h80, %ImageFile%
Gui, Font, s15
Gui, Margin, 10,30
Gui, Add, Text, w780 x20 hwndHDevice, Recherche du nom du poste
Gui, Add, Text, w780 x20, Serveur
Gui, Add, Radio, gChange,Dev
Gui, Add, Radio, gChange,App
Gui, Add, Radio, gChange,LocalClient
Gui, Add, Radio, gChange,LocalSimon
Gui, Add, Radio, gChange,Local
Gui, Add, Text, w780 hwndHText, %SearchGame%
Gui, Show, w800 h600, TAG HUNTER CONNECT

return

Change:

    ServerOrgigin = %A_GuiControl%
    DeviceName := checkRegistered(ServerOrgigin)

    ;Check connexion to server

    if(DeviceName){

        DeviceName:=SubStr(DeviceName,1,StrLen(DeviceName)-1)
        StringTrimLeft, DeviceName, DeviceName, 1
        ControlSetText, , %DeviceName%, ahk_id %HDevice% 

        ;Start search launch game
        SearchGame = Recherche de jeu en cours sur %A_GuiControl%
        ControlSetText, , %SearchGame%, ahk_id %HText% 
        SetTimer, checkLaunchedGame, 5000
    }
return

checkLaunchedGame:

    json_str = {"device_uniq":"%DeviceUniq%"}
    oWhr := SendTaghunterHttpRequest("GET", "checkDeviceUsedInLaunchedGame", json_str, ServerOrgigin)

    if(oWhr.Status == 201){
        responseText := StrReplace(oWhr.ResponseText, "\", "")
        responseText := SubStr(responseText,1,StrLen(responseText)-1)
        StringTrimLeft, responseText, responseText, 1
        Response :=StrSplit(responseText, "&")
        LaunchedGameId := Response[2]
        LaunchedGameName := Response[1]
        SearchGame = Connecté au jeu %LaunchedGameName%
        ControlSetText, , %SearchGame%, ahk_id %HText% ;uses the handle of the control
        SetTimer, checkLaunchedGame, Off
        SetTimer, LaunchGame, %interval%

        SetTimer, checkLaunchedGameEnded, 5000 ; Start timer, updating every 5000 milliseconds (5 seconds)
    }
    Else{
        TrayTip, "Taghunter" , Nope
    }

return 

checkLaunchedGameEnded:
    json_str = {"device_uniq":"%DeviceUniq%", "launched_game_id": "%LaunchedGameId%", "ended":"yes"}
    oWhr := SendTaghunterHttpRequest("GET", "checkLaunchedGameEnded", json_str, ServerOrgigin)

    if(oWhr.Status == 201){
        ControlSetText, , Jeu terminé. Appuyer sur relancer pour reinitialiser le logiciel, ahk_id %HText% ;uses the handle of the control
        SetTimer, checkLaunchedGameEnded, Off
    }else if(oWhr.Status == 401){

    }

return

LaunchGame:

    CSV_Load(FilePath, "data", ";")
    CountRows:=CSV_TotalRows("data")

    if(CountRows > LastCountRows){
        LastCountRows := CountRows
        Cols:=CSV_TotalCols("data")
        Last_Row := CSV_ReadRow("data", CountRows)

        json_str = {"LaunchedGameId":"%LaunchedGameId%","lastLine": "%Last_Row%", "licence_number": "%LicenceNumber%", "device_uniq":"%DeviceUniq%"}
        oWhr := SendTaghunterHttpRequest("POST", "api", json_str, ServerOrgigin)
    }
return

; }
; Label

Register(deviceName, ServerOrgigin) {

    json_str = {"licence_number": "%LicenceNumber%", "device_name":"%deviceName%", "device_uniq":"%DeviceUniq%"}

    oWhr := SendTaghunterHttpRequest("POST","registerDevice", json_str, ServerOrgigin)
MsgBox, % oWhr.ResponseText

    ArrayResponse := Jxon_Load(oWhr.ResponseText)
    if(oWhr.Status == 201){
        global IsRegistered := true 
        TrayTip, "Taghunter" , % StrReplace(oWhr.ResponseText, "\u00e9", Chr(0x00e9))
    }else{
        MsgBox, % oWhr.ResponseText
    }

}

checkRegistered(ServerOrgigin) {
    json_str = {"licence_number": "%LicenceNumber%", "device_uniq":"%DeviceUniq%"}
    oWhr := SendTaghunterHttpRequest("GET", "checkDeviceRegistration", json_str, ServerOrgigin)
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
                Register(UserInput, ServerOrgigin)
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

SendTaghunterHttpRequest(method, httpPath, json_str, ServerOrgigin){

    If(ServerOrgigin == "Dev"){
        originPath :="https://dev.taghunter.fr/"
    }else if(ServerOrgigin == "App"){
        originPath :="https://app.taghunter.fr/"
    }else if(ServerOrgigin == "LocalClient"){
        originPath :="http://192.168.128.250/"
    }else if(ServerOrgigin == "LocalSimon"){
        originPath :="http://192.168.129.250/"
    }else{
        originPath :="http://localhost/"
    }
    fullPath := originPath "taghunter/public/api/" httpPath
    ; fullPath :="http://localhost/taghunter/public/api/" httpPath
    ; fullPath :="https://app.taghunter.fr/taghunter/public/api/" httpPath
    try{ ; only way to properly protect from an error here
       
           oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    oWhr.Open(method, fullPath, false)
    oWhr.SetRequestHeader("Content-Type", "application/json")
    oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")
    oWhr.Option(6) := false   ; disable redirect
    oWhr.Send(json_str)

        ; you can get the response data either in raw or text format
        ; raw: hObject.responseBody
        ; text: hObject.responseText	
    }catch e{
          
        return e.message
    }

return oWhr
}

;;;;;;OLD
LaunchGame2(){

    CSV_Load(FilePath, "data", ";")

    CountRows:=CSV_TotalRows("data")

    if(CountRows > LastCountRows){

        LastCountRows := CountRows
        ; TrayTip, "Taghunter" , % "Envoi en cours"
        ; TrayTip, "Taghunter" , %LaunchedGameId%
        Cols:=CSV_TotalCols("data")
        Last_Row := CSV_ReadRow("data", CountRows)

        oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        oWhr.Open("POST", "https://app.taghunter.fr/taghunter/public/api/api", false)
        oWhr.SetRequestHeader("Content-Type", "application/json")
        oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")

        json_str = {"LaunchedGameId":"%LaunchedGameId%","lastLine": "%Last_Row%", "licence_number": "%LicenceNumber%", "device_uniq":"%DeviceUniq%"}

        oWhr.Send(json_str)
    }

}
