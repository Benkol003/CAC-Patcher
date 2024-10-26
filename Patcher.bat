@echo off
REM some idiots will complain that they cant just click to run
powershell.exe -ExecutionPolicy bypass %~dp0%Patcher.ps1
pause