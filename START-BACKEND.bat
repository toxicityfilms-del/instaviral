@echo off
chcp 65001 >nul
title ReelBoost — server (band = is window band karo)
cd /d "%~dp0backend"
echo.
echo  ========================================
echo    ReelBoost backend chal raha hai...
echo    Phone app tab kaam karegi jab yeh ON ho.
echo    Band karne ke liye: is black window ko band karo.
echo  ========================================
echo.
npm start
echo.
echo  Server band ho gaya. Koi error upar dekho.
pause
