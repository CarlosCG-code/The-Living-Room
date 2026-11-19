@echo off
rem Abre el juego desde el proyecto en modo depuracion: con los trucos (F1). No es la version final.
rem Usa la variable GODOT si existe; si no, busca el Godot 4.7.2 que instalo winget.
set "EXE="
if defined GODOT set "EXE=%GODOT:_console=%"
if not defined EXE for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*") do (
	if exist "%%D\Godot_v4.7.2-stable_win64.exe" set "EXE=%%D\Godot_v4.7.2-stable_win64.exe"
)
if not defined EXE (echo No encuentro Godot 4.7.2. & pause & exit /b 1)
start "" "%EXE%" --path "%~dp0."
