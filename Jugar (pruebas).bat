@echo off
rem Abre el juego desde el proyecto en modo depuracion: con los trucos (F1). No es la version final.
rem Usa la variable GODOT (el ejecutable _console) y abre la version sin consola.
if "%GODOT%"=="" (echo Falta la variable GODOT. & pause & exit /b 1)
start "" "%GODOT:_console=%" --path "%~dp0."
