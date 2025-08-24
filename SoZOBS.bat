@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo ==================================================
echo ============ DEBUT DU SCRIPT ======================
echo ==================================================

:: Chemins par defaut
set "defaultObsPath=C:\Program Files\obs-studio\bin\64bit\obs64.exe"
set "defaultSozPath=%USERPROFILE%\AppData\Local\Programs\SOZ Launcher\sozlauncher.exe"

:: Fichier ini
set "configFile=%~dp0soz_launcher_config.ini"

:: Variables de chemin
set "obsPath="
set "sozPath="

:: Lire .ini si present
if exist "%configFile%" (
    for /f "tokens=1,* delims==" %%a in ('type "%configFile%"') do (
        if /i "%%a"=="obs" set "obsPath=%%b"
        if /i "%%a"=="soz" set "sozPath=%%b"
    )
)

:: Si le .ini n'existe pas, utiliser chemins par defaut
if not defined obsPath (
    set "obsPath=%defaultObsPath%"
)
if not defined sozPath (
    set "sozPath=%defaultSozPath%"
)

echo [OK] Chemin OBS : !obsPath!
echo [OK] Chemin SOZ : !sozPath!

:: Verif OBS
if not exist "!obsPath!" (
    echo.
    echo ==================================================
    echo [ERREUR] OBS non trouve au chemin : !obsPath!
    echo Vous allez devoir le selectionner manuellement.
    echo ==================================================
    for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command ^
    "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object Windows.Forms.OpenFileDialog; $f.Title = 'Selectionnez OBS (obs64.exe)'; $f.Filter = 'Executable OBS|obs64.exe'; if ($f.ShowDialog() -eq 'OK') { $f.FileName }"`) do (
        set "obsPath=%%p"
    )
    echo [INFO] Nouveau chemin OBS choisi : !obsPath!
    set "saveIni=1"
)

:: Verif SOZ
if not exist "!sozPath!" (
    echo.
    echo ==================================================
    echo [ERREUR] SOZ Launcher non trouve au chemin : !sozPath!
    echo Vous allez devoir le selectionner manuellement.
    echo ==================================================
    for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command ^
    "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object Windows.Forms.OpenFileDialog; $f.Title = 'Selectionnez SOZ Launcher'; $f.Filter = 'Executable SOZ|*.exe'; if ($f.ShowDialog() -eq 'OK') { $f.FileName }"`) do (
        set "sozPath=%%p"
    )
    echo [INFO] Nouveau chemin SOZ choisi : !sozPath!
    set "saveIni=1"
)

:: Sauvegarde du .ini si necessaire
if defined saveIni (
    echo [INFO] Sauvegarde des chemins dans le fichier .ini
    (
        echo obs=!obsPath!
        echo soz=!sozPath!
    ) > "%configFile%"
)

echo.
echo [ACTION] Vérification d'OBS en cours...

tasklist /FI "IMAGENAME eq obs64.exe" | find /I "obs64.exe" >nul
if errorlevel 1 (
    echo [INFO] OBS non en cours, lancement avec replay buffer...
    for %%d in ("!obsPath!") do set "obsDir=%%~dpd"
    start "" /d "!obsDir!" obs64.exe --startreplaybuffer --disable-shutdown-check
) else (
    echo [INFO] OBS déjà en cours, redémarrage pour réactiver le replay buffer...
    :: Fermeture OBS
    taskkill /IM obs64.exe /F >nul 2>&1
    timeout /t 5 >nul
    :: Relancement OBS avec replay buffer
    for %%d in ("!obsPath!") do set "obsDir=%%~dpd"
    start "" /d "!obsDir!" obs64.exe --startreplaybuffer --disable-shutdown-check
)

echo.
echo [ACTION] Lancement de SOZ...
start "" cmd /c start "" "!sozPath!"

echo.
echo ==================================================
echo ================ FIN DU SCRIPT ===================
echo ==================================================
echo.
:: pause >nul
exit /b
