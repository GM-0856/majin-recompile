@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-1080p-probe.ps1"
if errorlevel 1 pause
