@echo off
rem Double-click to copy AP saves from before DRAP 1.2.0 into AP_Saves.
rem The work is done by Migrate-OldAPSaves.ps1 next to this file.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Migrate-OldAPSaves.ps1"
