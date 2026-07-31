@echo off
cd /d "%~dp0"
title Jardim da Rotina - Servidor Local
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor-local.ps1"
if errorlevel 1 (
  echo.
  echo O servidor nao conseguiu iniciar.
  pause
)
