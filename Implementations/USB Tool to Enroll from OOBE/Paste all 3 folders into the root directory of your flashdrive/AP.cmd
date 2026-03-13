@echo off
echo ==========================================
echo  Autopilot Enrollment Script Initializing
echo ==========================================
echo.
PowerShell.exe -ExecutionPolicy Bypass -File "%~dp0AutoEnroll-Autopilot.ps1"
echo.
echo ==========================================
echo  Script completed. Press any key to exit.
echo ==========================================
pause >nul