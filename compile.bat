@echo off
echo ========================================
echo    TempCleaner Pro - Compilacion
echo ========================================
echo.

REM Verificar si AutoIt3 esta instalado
if exist "C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe" (
    set AUT2EXE="C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe"
) else if exist "C:\Program Files\AutoIt3\Aut2Exe\Aut2exe.exe" (
    set AUT2EXE="C:\Program Files\AutoIt3\Aut2Exe\Aut2exe.exe"
) else (
    echo [ERROR] AutoIt3 no esta instalado.
    echo Por favor instala AutoIt3 desde: https://www.autoitscript.com/
    pause
    exit /b 1
)

echo [INFO] Compilando TempCleaner.au3...
%AUT2EXE% /in "TempCleaner.au3" /out "TempCleaner.exe" /x86

if exist "TempCleaner.exe" (
    echo.
    echo [OK] Compilacion exitosa!
    echo [OK] Archivo creado: TempCleaner.exe
) else (
    echo.
    echo [ERROR] Error en la compilacion.
)

echo.
pause
