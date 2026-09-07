@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0tool\start_dev.ps1"

