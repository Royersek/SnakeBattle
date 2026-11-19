@echo off
cd /d "%~dp0"
java -cp "lib/*" SnakeBattle
if errorlevel 1 (
  echo.
  echo No se pudo iniciar. Verifica que Java 21 o superior este instalado.
  pause
)
