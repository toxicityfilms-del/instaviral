@echo off
:: Is file par RIGHT-CLICK ^> Run as administrator
chcp 65001 >nul
netsh advfirewall firewall add rule name="ReelBoost API 3000" dir=in action=allow protocol=TCP localport=3000
echo.
if %errorlevel%==0 (echo Port 3000 allow ho gaya.) else (echo Fail — zaroor "Run as administrator" se chalao.)
pause
