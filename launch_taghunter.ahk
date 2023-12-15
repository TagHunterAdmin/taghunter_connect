; #Persistent
; #NoEnv
; #SingleInstance, force
#Include %A_ScriptDir%\data_client.ahk
#Include %A_ScriptDir%\objectToString.ahk
#Include %A_ScriptDir%\csvtoDict.ahk
#Include %A_ScriptDir%\_JXON.ahk
#Include %A_ScriptDir%\debug.ahk
#Include %A_ScriptDir%\64bit\Native.ahk
#Include %A_ScriptDir%\64bit\github.ahk
#Include %A_ScriptDir%\64bit\auto_update.ahk

#Requires AutoHotkey v2.0

SetWorkingDir A_ScriptDir

Application := { Name: "TagHunter Connect", Version: "1.0" }

myApp := defineApp("TagHunterAdmin","taghunter_connect")
; this example refers to my repo http://github.com/samfisherirl/github.ahk

path_of_app := A_ScriptDir
; set where my application is stored on the local computer

myApp.setPath(path_of_app)

myApp.connectGithubAPI()

new_update := myApp.checkforUpdate()
; updates := checkforUpdate()
; new_update := Jxon_dump(update, 0)

; ; new_update_version := update.version 
; MsgBox new_update

global FilePath := "events_reader\events.csv"

if(IsSet(FilePathCustom)){
    FilePath := FilePathCustom
}

global interval := 500 ; set the interval
global ConfigDone := false
global DeviceUniq := A_ComputerName
global DeviceName := ""
ImageFile := "logo_tag_hunter_connect.png"

#SingleInstance Force ; Replace with new instance if script is running

;get csv data on events file and convert it to array
accountArray := CSVtoDict(FilePath)
;count the number of rows in the csv file (by getting the lentgh of the array)
global LastCountRows := accountArray.Count
global LaunchedGameId := false
global ServeurName := "local"

; Tray definition =================================================================
Tray := A_TrayMenu
Application := { Name: "TagHunter Connect", Version: "1.0" }
TraySetIcon("logo_tag_hunter_connect_favicon.ico")
; TrayTip(Application.Name)
; Tray.Delete()
Tray.Add("Exit", (*) => ExitApp())


SettingsGui()

SettingsGui(){
    ; Define parameters of Gui
    Window := {Width: 800, Height: 500, Title: Application.Name}
    MenuWidth := 100
    Navigation := {Label: ["Jeux", "Configuration", "Aide"]}

    myGui := Gui()
    myGui.OnEvent("Close", Gui_Escape)
    myGui.OnEvent("Escape", Gui_Escape)
    MyGui.OnEvent("Size", Gui_Size)
    myGui.Opt("+LastFound +Resize MinSize400x300")
    myGui.BackColor := "FFFFFF"

    Tab := myGui.Add("Tab2", "x-999 y-999 w0 h0 -Wrap +Theme vTabControl")
    myGui.Tabs := Tab
    Tab.UseTab() ; Exclude future controls from any tab control

    myGui.TabPicSelect := myGui.AddText("x0 y0 w4 h32 vpMenuSelect Background0x0078D7") ; Using a text control to create a colored rectangle
    ; myGui.TabPicHover := myGui.AddText("x0 y0 w4 h32 vpMenuHover Background0xCCE8FF Hidden") ; Using a text control to create a colored rectangle

    myGui.TabTitle := myGui.Add("Text", "x" MenuWidth+10 " y" 0 " w" (Window.Width-MenuWidth)-10 " h" 30 " +0x200 vPageTitle", "")
    myGui.TabTitle.SetFont("s14 ", "Segoe UI") ; Set Font Options

    Loop Navigation.Label.Length { 
        Tab.Add([Navigation.Label[A_Index]])
        If (Navigation.Label[A_Index] = "---") {
            Continue
        }
        ogcTextMenuItem := myGui.Add("Text", "x0 y" (32*A_Index)-32 " h32 w" MenuWidth " +0x200 BackgroundTrans vMenuItem" . A_Index, " " Navigation.Label[A_Index])
        ogcTextMenuItem.SetFont("s9 c808080", "Segoe UI") ; Set Font Options
        ogcTextMenuItem.OnEvent("Click", Gui_Menu)
        ogcTextMenuItem.Index := A_Index
        if (A_Index = 1) {
            ogcTextMenuItem.SetFont("c000000")
            myGui.ActiceTab := ogcTextMenuItem
            myGui.TabTitle.Value := trim(ogcTextMenuItem.text)
        }
    }

    ogchDividerLine := myGui.AddText("x" MenuWidth+10 " y32 w" Window.Width-MenuWidth-10*2 " h1 Section BackgroundD8D8D8") ; Using a text control to create a colored rectangle
    ogchDividerLine.LeftMargin := 10

    ; Start of defining the custom controls

    Tab.UseTab(1) ; Future controls are owned by the specified tab

    myGui.Add("Text", "xs ys+10 BackgroundWhite", "Sélectionner le serveur")
    radioServeurTGLoc := myGui.Add("Radio", "yp+40", "Serveur Local (http://192.168.128.250/)"), radioServeurTGLoc.OnEvent('Click', ServeurChange)
    radioServeurTGAppfr := myGui.Add("Radio", "yp+40", "Serveur Cloud (app.taghunter.fr)"), radioServeurTGAppfr.OnEvent('Click', ServeurChange)
    if(IsAdmin){
        radioServeurTGDevfr := myGui.Add("Radio", "yp+40", "Serveur Cloud (dev.taghunter.fr)"), radioServeurTGDevfr.OnEvent('Click', ServeurChange)
        radioServeurTGLocSimon := myGui.Add("Radio", "yp+40", "Serveur Local Simon (http://192.168.129.250/)"), radioServeurTGLocSimon.OnEvent('Click', ServeurChange)
        radioServeurTGLocLara := myGui.Add("Radio", "yp+40", "Serveur Local Simon Laragon (http://localhost/)"), radioServeurTGLocLara.OnEvent('Click', ServeurChange)
    }

    myGui.Add("Text", "yp+80 vDeviceNameDiv w256", "") 
    myGui.Add("Text", "vSearchGameDiv w256", "") 

    Tab.UseTab(2) ; Future controls are owned by the specified tab
    myGui.Add("Text", "xs ys+10 BackgroundWhite", "Identifiant de votre ordinateur " DeviceUniq)

    myGui.Add("Text", "yp+40", "Version de TagHunter Connect " Application.Version)
    if(new_update){
         myGui.Add("Text", "w256", "La version " new_update " de TagHunter Connect est disponible.") 
    ogcButtonUpdateApp := myGui.Add("Button", "vUpdate", "Mettre à jour")
    ogcButtonUpdateApp.OnEvent("Click", Update_App)

    }

    ogcButtonReloadScript := myGui.Add("Button", "yp+40 vReloadScript", "Relancer TagHunter Connect")
    ogcButtonReloadScript.OnEvent("Click", Reload_Script)

    Tab.UseTab(3) ; Future controls are owned by the specified tab
    myGui.Add("Text", "xs ys+10 BackgroundWhite vPathConfigDiv", "Chemin d'accès au dossier TagHunter Connect " A_ScriptDir) 
    myGui.Add("Text", "vPathEventConfigDiv", "Chemin d'accès au fichier events.csv " A_ScriptDir "\" FilePath) 

    ogcButtonOpenAppFolder := myGui.Add("Button", "vOpenAppFolder", "Ouvrir le dossier TagHunter Connect")
    ogcButtonOpenAppFolder.OnEvent("Click", Open_App_Folder)
    myGui.Add("Text", "yp+40", "Le chemin de fichier à écrire dans Sportident Reader doit pointer sur le fichier events.csv de TagHunter Connect")
    MyGui.Add("Picture", "w500 h300", A_ScriptDir "\help_sportident_reader.png")

    Tab.UseTab("")

    ogcButtonOK := myGui.Add("Button", "x" (Window.Width - 170) - 10 " y" (Window.Height - 24) - 10 " w80 h24 vButtonOK", "OK")
    ogcButtonOK.OnEvent("Click", ButtonOK)
    ogcButtonOK.LeftDistance := "10"
    ogcButtonOK.BottomDistance := "10"
    ogcButtonCancel := myGui.Add("Button", "x" (Window.Width - 80) - 10 " y" (Window.Height - 24) - 10 " w80 h24 vButtonCancel", "Cancel")
    ogcButtonCancel.OnEvent("Click", Gui_Escape)
    ogcButtonCancel.LeftDistance := "100"
    ogcButtonCancel.BottomDistance := "10"

    myGui.Title := Window.Title
    myGui.Show(" w" Window.Width " h" Window.Height)

    return

    ; Nested Functions ==============================================================================
    ServeurChange(Radio, Info){
        global ServeurName
        global DeviceName
        ServeurName := Radio.Text
        DeviceName := checkRegistered(ServeurName)

        myGui['SearchGameDiv'].Text := "Recherche de jeu en cours sur " ServeurName
        myGui['DeviceNameDiv'].Text := "Vous êtes connecté au poste " DeviceName
        ; myGui['DeviceNameConfigDiv'].Text := "Le nom donné à ce poste " DeviceName

        SetTimer checkLaunchedGame, 5000
        ; checkLaunchedGame(ServeurName)

    }

    checkRegistered(ServeurName) {

        json_string_map := Map("licenceNumber", LicenceNumber, "DateTime", A_now, "device_uniq", DeviceUniq)
        json_string := Jxon_dump(json_string_map, 0)
        oWhr := SendTaghunterHttpRequest("GET", "checkDeviceRegistration", json_string)

        if(oWhr.Status == 401){
            Result := MsgBox("Ce poste n'est pas enregistré. Voulez-vous ajouter ce poste à votre compte?",, "YesNo")

            if(Result = "Yes"){
                deviceNameInput := InputBox("Donnez un nom à ce poste", "UserInput", "w100 h100")
                if deviceNameInput.Result = "Cancel"
                    MsgBox "You entered '" deviceNameInput.Value "' but then cancelled."
                else
                    MsgBox deviceNameInput.Value 
                return Register(deviceNameInput.Value, ServeurName)
            }
            else{
                ExitApp
            }

        }
        else if(oWhr.Status == 301) {
            MsgBox StrReplace(oWhr.ResponseText, "\u00e9", Chr(0x00e9))
        }
        else {
            return oWhr.ResponseText ; return the device name
        }
    }

    checkLaunchedGame(){

        global LaunchedGameId
        global ServeurName

        json_string_map := Map("device_uniq", DeviceUniq)
        json_string := Jxon_dump(json_string_map, 0)
        oWhr := SendTaghunterHttpRequest("GET", "checkDeviceUsedInLaunchedGame", json_string)

        if(oWhr.Status == 201){
            responseText := StrReplace(oWhr.ResponseText, "\", "")
            responseText := SubStr(responseText,1,StrLen(responseText)-1)
            ; StringTrimLeft responseText , responseText , 1
            Response := StrSplit(responseText, "&")
            LaunchedGameId := Response[2]
            LaunchedGameName := Response[1]

            myGui['SearchGameDiv'].Text := "Connecté au jeu" LaunchedGameName
            ; ControlSetText, , %SearchGame%, ahk_id %HText% ;uses the handle of the control
            ; SetTimer, checkLaunchedGame, Off
            ; LaunchGame(LaunchedGameId, ServeurName)
            SetTimer checkLaunchedGame, 0
            SetTimer checkLaunchedGameEnded, 5000
            SetTimer LaunchGame, interval

            ; SetTimer, checkLaunchedGameEnded, 5000 ; Start timer, updating every 5000 milliseconds (5 seconds)
        }
        Else{
            ; TrayTip, "Taghunter" , % oWhr.ResponseText
        }

        return 
    }

    checkLaunchedGameEnded(){

        global ServeurName
        ; json_str = {"device_uniq":"%DeviceUniq%", "launched_game_id": "%LaunchedGameId%", "ended":"yes"}
        json_string_map := Map("device_uniq", DeviceUniq, "launched_game_id", LaunchedGameId, "ended", "yes" )
        json_string := Jxon_dump(json_string_map, 0)
        oWhr := SendTaghunterHttpRequest("GET", "checkLaunchedGameEnded", json_string)

        if(oWhr.Status == 201){
            myGui['SearchGameDiv'].Text := "Jeu terminé. Sélectionnez à nouveau le serveur pour se connecter à un nouveau jeu"
            SetTimer checkLaunchedGameEnded, 0
            SetTimer LaunchGame, 0
        }else if(oWhr.Status == 401){

        }

        return
    }

    SendTaghunterHttpRequest(method, httpPath, json_string){
        global SerbeurName
        If(ServeurName == "Serveur Cloud (dev.taghunter.fr)"){
            originPath :="https://dev.taghunter.fr/"
        }else if(ServeurName == "Serveur Cloud (app.taghunter.fr)"){
            originPath :="https://app.taghunter.fr/"
        }else if(ServeurName == "Serveur Local (http://192.168.128.250/)"){
            originPath :="http://192.168.128.250/"
        }else if(ServeurName == "Serveur Local Simon (http://192.168.129.250/)"){
            originPath :="http://192.168.129.250/"
        }else if ( ServeurName == "Serveur Local Simon Laragon (http://localhost/)"){
            originPath :="http://localhost/"
        }

        fullPath := originPath "taghunter/public/api/" httpPath
        ; fullPath :="http://localhost/taghunter/public/api/" httpPath
        ; fullPath :="https://app.taghunter.fr/taghunter/public/api/" httpPath

        oWhr := ComObject("WinHttp.WinHttpRequest.5.1")

        try{ ; only way to properly protect from an error here
            oWhr.Open(method, fullPath, false)
            oWhr.SetRequestHeader("Content-Type", "application/json")
            oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")
            ; oWhr.Option(6) := false ; disable redirect
            if(json_string){
                oWhr.Send(json_string)
            }else{
                oWhr.Send()
            }

            ; oWhr.Send(json_str)

        }catch as e{

            return e.message
        }

        return oWhr
    }

    LaunchGame(){
        global LaunchedGameId
        global ServeurName
        global LastCountRows 
        accountArray := CSVtoDict(FilePath)
        CountRows := accountArray.Count

        if(CountRows > LastCountRows){
            LastCountRows := CountRows
            Last_Row := Jxon_dump(accountArray[CountRows - 1], 0)
            json_string_map := Map("LaunchedGameId", LaunchedGameId, "lastLine", Last_Row, "device_uniq", DeviceUniq)
            json_string := Jxon_dump(json_string_map, 0)

            oWhr := SendTaghunterHttpRequest("POST", "postLaunchedGameLastRow", json_string)
        }
        return
    }

    Register(deviceName, ServeurName) {

        json_string_map := Map("licenceNumber", LicenceNumber, "deviceName", deviceName, "device_uniq", DeviceUniq)
        json_string := Jxon_dump(json_string_map, 0)
        oWhr := SendTaghunterHttpRequest("GET", "registerDevice", json_string)

        if(oWhr.Status == 201){
            global IsRegistered := true 
            return oWhr.ResponseText
        }else{
            MsgBox oWhr.ResponseText
        }
    }

    Open_App_Folder(*){ 
        run "explorer.exe " A_ScriptDir
    }
    Update_App(*){ 
        myApp.Update()
    }
    Reload_Script(*){ 
        Reload
    }
    ButtonOK(*){
        Saved := MyGui.Submit(0)
        MsgBox("CheckboxExample`t[" Saved.CheckboxExample "]`n")
        ExitApp()
    }

    Gui_Escape(*){ 
        ExitApp() ; Terminate the script unconditionally
    }

    Gui_Menu(guiCtrlObj, info, *){
        ; Called when clicking the menu
        thisGui := guiCtrlObj.Gui
        thisGui.ActiceTab.SetFont("c808080")
        thisGui.Tabs.Choose(trim(guiCtrlObj.text))
        thisGui.TabTitle.Value := trim(GuiCtrlObj.text)
        thisGui.ActiceTab := GuiCtrlObj
        guiCtrlObj.SetFont("c000000")
        thisGui.TabPicSelect.Move(0, (32*GuiCtrlObj.Index) - 32)
        return
    }

    Gui_Size(thisGui, MinMax, Width, Height) {
        if MinMax = -1	; The window has been minimized. No action needed.
            return
        DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
        For Hwnd, GuiCtrlObj in thisGui{
            if GuiCtrlObj.HasProp("LeftMargin"){
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, , Width-cX-GuiCtrlObj.LeftMargin,)
            }
            if GuiCtrlObj.HasProp("LeftDistance") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(Width -cWidth - GuiCtrlObj.LeftDistance, , , )
            }
            if GuiCtrlObj.HasProp("BottomDistance") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, Height - cHeight - GuiCtrlObj.BottomDistance, , )
            }
            if GuiCtrlObj.HasProp("BottomMargin") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, , , Height -cY - GuiCtrlObj.BottomMargin)
            } 
        }
        DllCall("LockWindowUpdate", "Uint", 0)
    }
    CSVprs(str)								;creates an array of the elements of a CSV string
    {
        arr := []
        Loop Parse, str, "CSV"
            arr.Push(A_LoopField)
        return arr
    }

    CSVtoDict(file)
    {
        array := Map()
        data 	:= StrSplit(FileRead(file), "`n", "`r")
        ; hdr 	:= CSVprs(data.RemoveAt(1))				;reads the 1st line into an array and deletes it from the data array. Remove this line if your data does not have Headers.

        for x,y in data
        {
            array[x] := Map()
            for k,v in CSVprs(y)
                array[x][k] := v				;change [hdr[k]] to just [k] if no headers
            ; array[x][hdr[k]] := v				;change [hdr[k]] to just [k] if no headers
        }
        Return array
    }
}
