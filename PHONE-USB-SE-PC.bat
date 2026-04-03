@echo off
chcp 65001 >nul
title ReelBoost — phone USB se PC (Wi-Fi ki zaroorat nahi)
echo.
echo  === TARIKA 1: USB cable (sabse aasaan) ===
echo  1) Phone mein Developer options ON ^> USB debugging ON
echo  2) USB se PC se jodo ^> phone par "Allow USB debugging" Allow
echo  3) Pehle REELBOOST-START-SERVER.bat chalao (backend ON)
echo  4) Neeche wala command chalega...
echo.
where adb >nul 2>&1
if errorlevel 1 (
  echo  ERROR: adb nahi mila. Android Studio ^> SDK Platform Tools install karo,
  echo  ya PATH mein adb add karo. Ya TARIKA 2 dekho (ngrok).
  pause
  exit /b 1
)
adb devices
echo.
adb reverse tcp:3000 tcp:3000
if errorlevel 1 (
  echo  Reverse fail — USB debugging check karo, cable try karo.
  pause
  exit /b 1
)
echo.
echo  DONE. Ab phone par app kholo:
echo  - PC server address mein likho:  http://127.0.0.1:3000
echo  - Save ^& connect
echo.
echo  NOTE: Har baar USB lagane ke baad yeh .bat dubara chala lena.
echo.
pause
