#NoTrayIcon
#RequireAdmin

#Region AutoIt3Wrapper directives section
#AutoIt3Wrapper_Icon=cleaner.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=Y
#AutoIt3Wrapper_Res_Comment=TempCleaner Pro - Optimizador de Sistema
#AutoIt3Wrapper_Res_Description=Limpiador de archivos temporales
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductName=TempCleaner Pro
#AutoIt3Wrapper_Res_CompanyName=Enoc Colomer
#AutoIt3Wrapper_Res_LegalCopyright=© 2026 Enoc Colomer - MIT License
#EndRegion AutoIt3Wrapper directives section

#Region Includes
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ProgressConstants.au3>
#include <ButtonConstants.au3>
#include <Misc.au3>
#include <File.au3>
#include <Array.au3>
#EndRegion Includes

; Evitar múltiples instancias
_Singleton(@ScriptName)

#Region Options
Opt('MustDeclareVars', 1)
Opt('GUICloseOnESC', 0)
Opt('TrayMenuMode', 1)
#EndRegion Options

; ============================================
; CONSTANTES Y VARIABLES GLOBALES
; ============================================
Global Const $APP_NAME = "TempCleaner Pro"
Global Const $APP_VERSION = "1.0.0"

; Colores
Global Const $COLOR_BG = 0x1E1E2E           ; Fondo oscuro
Global Const $COLOR_BG_LIGHT = 0x2D2D3D     ; Fondo claro
Global Const $COLOR_ACCENT = 0x7C3AED       ; Violeta
Global Const $COLOR_SUCCESS = 0x10B981      ; Verde
Global Const $COLOR_WARNING = 0xF59E0B      ; Amarillo
Global Const $COLOR_DANGER = 0xEF4444       ; Rojo
Global Const $COLOR_TEXT = 0xFFFFFF         ; Texto blanco
Global Const $COLOR_TEXT_DIM = 0x9CA3AF     ; Texto gris

; Variables de estado
Global $totalFilesFound = 0
Global $totalSizeFound = 0
Global $isScanning = False
Global $isCleaning = False

; Rutas a limpiar
Global $pathsToClean[8]
$pathsToClean[0] = @TempDir                                    ; %TEMP%
$pathsToClean[1] = @WindowsDir & "\Temp"                       ; Windows\Temp
$pathsToClean[2] = @LocalAppDataDir & "\Temp"                  ; Local Temp
$pathsToClean[3] = @UserProfileDir & "\AppData\Local\Microsoft\Windows\INetCache"  ; IE Cache
$pathsToClean[4] = @LocalAppDataDir & "\Google\Chrome\User Data\Default\Cache"     ; Chrome Cache
$pathsToClean[5] = @LocalAppDataDir & "\Mozilla\Firefox\Profiles"                   ; Firefox Cache
$pathsToClean[6] = @WindowsDir & "\Prefetch"                   ; Prefetch
$pathsToClean[7] = @UserProfileDir & "\Recent"                 ; Archivos recientes

; Iniciar GUI
Main()

; ============================================
; FUNCIÓN PRINCIPAL - GUI
; ============================================
Func Main()
    ; Crear ventana principal
    Local $hGUI = GUICreate($APP_NAME & " v" & $APP_VERSION, 500, 550, -1, -1, $WS_POPUP + $WS_BORDER)
    GUISetBkColor($COLOR_BG)

    ; ========== HEADER ==========
    ; Barra de título personalizada
    Local $lblTitle = GUICtrlCreateLabel($APP_NAME, 20, 15, 350, 30)
    GUICtrlSetFont(-1, 16, 700, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Local $lblVersion = GUICtrlCreateLabel("v" & $APP_VERSION, 380, 20, 50, 20)
    GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT_DIM)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; Botón cerrar
    Local $btnClose = GUICtrlCreateLabel("✕", 460, 10, 30, 30, $SS_CENTER)
    GUICtrlSetFont(-1, 14, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetCursor(-1, 0)

    ; Línea separadora
    GUICtrlCreateLabel("", 0, 50, 500, 2)
    GUICtrlSetBkColor(-1, $COLOR_BG_LIGHT)

    ; ========== ESTADÍSTICAS ==========
    Local $grpStats = GUICtrlCreateGroup("", 20, 60, 460, 100)
    GUICtrlSetBkColor(-1, $COLOR_BG_LIGHT)

    Local $lblFilesTitle = GUICtrlCreateLabel("Archivos encontrados:", 40, 80, 150, 20)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT_DIM)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Global $lblFilesCount = GUICtrlCreateLabel("0", 40, 100, 150, 30)
    GUICtrlSetFont(-1, 20, 700, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_ACCENT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Local $lblSizeTitle = GUICtrlCreateLabel("Espacio a liberar:", 280, 80, 150, 20)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT_DIM)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Global $lblSizeCount = GUICtrlCreateLabel("0 MB", 280, 100, 180, 30)
    GUICtrlSetFont(-1, 20, 700, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_SUCCESS)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; ========== OPCIONES DE LIMPIEZA ==========
    Local $lblOptions = GUICtrlCreateLabel("¿Qué deseas limpiar?", 20, 175, 200, 25)
    GUICtrlSetFont(-1, 12, 600, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; Checkboxes
    Global $chkTemp = GUICtrlCreateCheckbox(" Archivos temporales (%TEMP%)", 30, 205, 220, 25)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetState(-1, $GUI_CHECKED)

    Global $chkWinTemp = GUICtrlCreateCheckbox(" Windows Temp", 30, 235, 220, 25)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetState(-1, $GUI_CHECKED)

    Global $chkPrefetch = GUICtrlCreateCheckbox(" Prefetch (acelera Windows)", 30, 265, 220, 25)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetState(-1, $GUI_CHECKED)

    Global $chkRecent = GUICtrlCreateCheckbox(" Archivos recientes", 30, 295, 220, 25)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Global $chkChrome = GUICtrlCreateCheckbox(" Caché de Chrome", 270, 205, 200, 25)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Global $chkFirefox = GUICtrlCreateCheckbox(" Caché de Firefox", 270, 235, 200, 25)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Global $chkIE = GUICtrlCreateCheckbox(" Caché de Internet Explorer", 270, 265, 200, 25)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Global $chkRecycle = GUICtrlCreateCheckbox(" Vaciar papelera", 270, 295, 200, 25)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; ========== BARRA DE PROGRESO ==========
    GUICtrlCreateLabel("", 20, 340, 460, 2)
    GUICtrlSetBkColor(-1, $COLOR_BG_LIGHT)

    Global $lblStatus = GUICtrlCreateLabel("Listo para escanear", 20, 355, 460, 20)
    GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT_DIM)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Global $progressBar = GUICtrlCreateProgress(20, 380, 460, 20, $PBS_SMOOTH)
    GUICtrlSetBkColor(-1, $COLOR_BG_LIGHT)

    ; ========== BOTONES ==========
    Global $btnScan = GUICtrlCreateButton("🔍 ESCANEAR", 20, 420, 220, 50)
    GUICtrlSetFont(-1, 12, 700, 0, "Segoe UI")
    GUICtrlSetBkColor(-1, $COLOR_ACCENT)
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetCursor(-1, 0)

    Global $btnClean = GUICtrlCreateButton("🧹 LIMPIAR", 260, 420, 220, 50)
    GUICtrlSetFont(-1, 12, 700, 0, "Segoe UI")
    GUICtrlSetBkColor(-1, $COLOR_SUCCESS)
    GUICtrlSetColor(-1, $COLOR_TEXT)
    GUICtrlSetCursor(-1, 0)
    GUICtrlSetState(-1, $GUI_DISABLE)

    ; ========== FOOTER ==========
    GUICtrlCreateLabel("", 0, 490, 500, 2)
    GUICtrlSetBkColor(-1, $COLOR_BG_LIGHT)

    Local $lblFooter = GUICtrlCreateLabel("💡 Ejecutar como administrador para mejores resultados", 20, 505, 460, 20, $SS_CENTER)
    GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT_DIM)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    Local $lblCopyright = GUICtrlCreateLabel("</> Developed by Enoc Colomer", 20, 525, 460, 20, $SS_CENTER)
    GUICtrlSetFont(-1, 8, 400, 0, "Segoe UI")
    GUICtrlSetColor(-1, $COLOR_TEXT_DIM)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; Mostrar ventana
    GUISetState(@SW_SHOW, $hGUI)

    ; Variable para arrastrar ventana
    Local $dragging = False
    Local $dragOffsetX, $dragOffsetY

    ; ========== LOOP PRINCIPAL ==========
    While 1
        Local $nMsg = GUIGetMsg()
        Switch $nMsg
            Case $GUI_EVENT_CLOSE, $btnClose
                ExitLoop

            Case $GUI_EVENT_PRIMARYDOWN
                ; Permitir arrastrar la ventana
                Local $cursorInfo = GUIGetCursorInfo($hGUI)
                If $cursorInfo[1] < 50 Then ; Solo en la barra de título
                    $dragging = True
                    Local $mousePos = MouseGetPos()
                    Local $winPos = WinGetPos($hGUI)
                    $dragOffsetX = $mousePos[0] - $winPos[0]
                    $dragOffsetY = $mousePos[1] - $winPos[1]
                EndIf

            Case $GUI_EVENT_PRIMARYUP
                $dragging = False

            Case $btnScan
                ScanFiles()

            Case $btnClean
                CleanFiles()

        EndSwitch

        ; Arrastrar ventana
        If $dragging Then
            Local $mousePos = MouseGetPos()
            WinMove($hGUI, "", $mousePos[0] - $dragOffsetX, $mousePos[1] - $dragOffsetY)
        EndIf
    WEnd

    GUIDelete($hGUI)
EndFunc

; ============================================
; FUNCIÓN DE ESCANEO
; ============================================
Func ScanFiles()
    $totalFilesFound = 0
    $totalSizeFound = 0
    $isScanning = True

    GUICtrlSetData($btnScan, "Escaneando...")
    GUICtrlSetState($btnScan, $GUI_DISABLE)
    GUICtrlSetState($btnClean, $GUI_DISABLE)
    GUICtrlSetData($progressBar, 0)

    Local $pathsToScan[1] = [0]

    ; Construir lista de paths según opciones
    If GUICtrlRead($chkTemp) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @TempDir)
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkWinTemp) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @WindowsDir & "\Temp")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkPrefetch) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @WindowsDir & "\Prefetch")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkRecent) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @UserProfileDir & "\Recent")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkChrome) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @LocalAppDataDir & "\Google\Chrome\User Data\Default\Cache")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkFirefox) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @LocalAppDataDir & "\Mozilla\Firefox\Profiles")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkIE) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @UserProfileDir & "\AppData\Local\Microsoft\Windows\INetCache")
        $pathsToScan[0] += 1
    EndIf

    If $pathsToScan[0] = 0 Then
        GUICtrlSetData($lblStatus, "⚠️ Selecciona al menos una opción")
        GUICtrlSetData($btnScan, "🔍 ESCANEAR")
        GUICtrlSetState($btnScan, $GUI_ENABLE)
        Return
    EndIf

    ; Escanear cada path
    For $i = 1 To $pathsToScan[0]
        Local $progress = Int(($i / $pathsToScan[0]) * 100)
        GUICtrlSetData($progressBar, $progress)
        GUICtrlSetData($lblStatus, "Escaneando: " & $pathsToScan[$i])

        If FileExists($pathsToScan[$i]) Then
            ScanDirectory($pathsToScan[$i])
        EndIf
    Next

    ; Actualizar UI
    GUICtrlSetData($lblFilesCount, $totalFilesFound)
    GUICtrlSetData($lblSizeCount, FormatSize($totalSizeFound))
    GUICtrlSetData($progressBar, 100)
    GUICtrlSetData($lblStatus, "✅ Escaneo completado - " & $totalFilesFound & " archivos encontrados")
    GUICtrlSetData($btnScan, "🔍 ESCANEAR")
    GUICtrlSetState($btnScan, $GUI_ENABLE)

    If $totalFilesFound > 0 Then
        GUICtrlSetState($btnClean, $GUI_ENABLE)
    EndIf

    $isScanning = False
EndFunc

; ============================================
; ESCANEAR DIRECTORIO RECURSIVAMENTE
; ============================================
Func ScanDirectory($path)
    Local $search = FileFindFirstFile($path & "\*.*")
    If $search = -1 Then Return

    While 1
        Local $file = FileFindNextFile($search)
        If @error Then ExitLoop

        Local $fullPath = $path & "\" & $file

        If @extended Then ; Es directorio
            ScanDirectory($fullPath)
        Else ; Es archivo
            $totalFilesFound += 1
            $totalSizeFound += FileGetSize($fullPath)
        EndIf
    WEnd

    FileClose($search)
EndFunc

; ============================================
; FUNCIÓN DE LIMPIEZA
; ============================================
Func CleanFiles()
    Local $confirm = MsgBox(4 + 32, $APP_NAME, "¿Estás seguro de que deseas eliminar " & $totalFilesFound & " archivos?" & @CRLF & @CRLF & "Esto liberará aproximadamente " & FormatSize($totalSizeFound) & " de espacio.")

    If $confirm <> 6 Then Return

    $isCleaning = True
    Local $deletedCount = 0
    Local $deletedSize = 0

    GUICtrlSetData($btnClean, "Limpiando...")
    GUICtrlSetState($btnClean, $GUI_DISABLE)
    GUICtrlSetState($btnScan, $GUI_DISABLE)
    GUICtrlSetData($progressBar, 0)

    Local $pathsToScan[1] = [0]

    ; Construir lista de paths según opciones
    If GUICtrlRead($chkTemp) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @TempDir)
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkWinTemp) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @WindowsDir & "\Temp")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkPrefetch) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @WindowsDir & "\Prefetch")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkRecent) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @UserProfileDir & "\Recent")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkChrome) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @LocalAppDataDir & "\Google\Chrome\User Data\Default\Cache")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkFirefox) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @LocalAppDataDir & "\Mozilla\Firefox\Profiles")
        $pathsToScan[0] += 1
    EndIf
    If GUICtrlRead($chkIE) = $GUI_CHECKED Then
        _ArrayAdd($pathsToScan, @UserProfileDir & "\AppData\Local\Microsoft\Windows\INetCache")
        $pathsToScan[0] += 1
    EndIf

    ; Limpiar cada path
    For $i = 1 To $pathsToScan[0]
        Local $progress = Int(($i / $pathsToScan[0]) * 100)
        GUICtrlSetData($progressBar, $progress)
        GUICtrlSetData($lblStatus, "Limpiando: " & $pathsToScan[$i])

        If FileExists($pathsToScan[$i]) Then
            Local $result = CleanDirectory($pathsToScan[$i])
            $deletedCount += $result[0]
            $deletedSize += $result[1]
        EndIf
    Next

    ; Vaciar papelera si está seleccionado
    If GUICtrlRead($chkRecycle) = $GUI_CHECKED Then
        GUICtrlSetData($lblStatus, "Vaciando papelera de reciclaje...")
        FileRecycle("")
        DllCall("shell32.dll", "int", "SHEmptyRecycleBinW", "hwnd", 0, "wstr", "", "dword", 7)
    EndIf

    ; Actualizar UI
    GUICtrlSetData($lblFilesCount, "0")
    GUICtrlSetData($lblSizeCount, "0 MB")
    GUICtrlSetData($progressBar, 100)
    GUICtrlSetData($lblStatus, "🎉 ¡Limpieza completada! Se liberaron " & FormatSize($deletedSize))
    GUICtrlSetData($btnClean, "🧹 LIMPIAR")
    GUICtrlSetState($btnScan, $GUI_ENABLE)

    $isCleaning = False
    $totalFilesFound = 0
    $totalSizeFound = 0

    MsgBox(64, $APP_NAME, "¡Limpieza completada!" & @CRLF & @CRLF & "Archivos eliminados: " & $deletedCount & @CRLF & "Espacio liberado: " & FormatSize($deletedSize))
EndFunc

; ============================================
; LIMPIAR DIRECTORIO RECURSIVAMENTE
; ============================================
Func CleanDirectory($path)
    Local $deletedCount = 0
    Local $deletedSize = 0

    Local $search = FileFindFirstFile($path & "\*.*")
    If $search = -1 Then
        Local $result[2] = [0, 0]
        Return $result
    EndIf

    While 1
        Local $file = FileFindNextFile($search)
        If @error Then ExitLoop

        Local $fullPath = $path & "\" & $file

        If @extended Then ; Es directorio
            Local $subResult = CleanDirectory($fullPath)
            $deletedCount += $subResult[0]
            $deletedSize += $subResult[1]
            DirRemove($fullPath, 0) ; Intentar eliminar directorio vacío
        Else ; Es archivo
            Local $fileSize = FileGetSize($fullPath)
            If FileDelete($fullPath) Then
                $deletedCount += 1
                $deletedSize += $fileSize
            EndIf
        EndIf
    WEnd

    FileClose($search)

    Local $result[2] = [$deletedCount, $deletedSize]
    Return $result
EndFunc

; ============================================
; FORMATEAR TAMAÑO
; ============================================
Func FormatSize($bytes)
    If $bytes < 1024 Then
        Return $bytes & " B"
    ElseIf $bytes < 1048576 Then
        Return Round($bytes / 1024, 2) & " KB"
    ElseIf $bytes < 1073741824 Then
        Return Round($bytes / 1048576, 2) & " MB"
    Else
        Return Round($bytes / 1073741824, 2) & " GB"
    EndIf
EndFunc
