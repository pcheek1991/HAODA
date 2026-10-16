@echo off
setlocal
if "%~1"=="" (
  echo Drag a .cer, .crt, .der, .pem or .p7b file onto this .cmd launcher.
  pause
  exit /b 2
)
set "RESULT=%~dpn1-hex.txt"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -File "%~dp0companion.ps1" -CertificatePath "%~1" -OutputPath "%RESULT%"
if errorlevel 1 (
  echo Conversion did not succeed. Existing files were not overwritten.
) else (
  echo Hex text: "%RESULT%"
)
pause
