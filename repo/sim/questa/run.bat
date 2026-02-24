@echo off
setlocal
cd /d "%~dp0"

echo === vsim as: ===
where vsim

REM go to folder where run.bat is located (project root)
cd /d "%~dp0"

set "MODE=%~1"
if "%MODE%"=="" set "MODE=batch"

if /I "%MODE%"=="gui" (
  echo === GUI ===
  vsim -do "do do/simulate_gui.do"
) else (
  echo === BATCH ===
  vsim -c -do "do do/simulate_batch.do"
)

exit /b %ERRORLEVEL%