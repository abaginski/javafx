@ECHO OFF
REM BFCPEOPTIONSTART
REM Advanced BAT to EXE Converter www.BatToExeConverter.com
REM BFCPEEXE=C:\Users\abagi\OneDrive\Dokumente\WU\javafx\ooRexxTryFX\run_ooRexxTryFX.exe
REM BFCPEICON=C:\Users\abagi\OneDrive\Dokumente\WU\javafx\ooRexxTryFX\resources\images\bsf4oorexx_032.ico
REM BFCPEICONINDEX=-1
REM BFCPEEMBEDDISPLAY=0
REM BFCPEEMBEDDELETE=1
REM BFCPEADMINEXE=0
REM BFCPEINVISEXE=0
REM BFCPEVERINCLUDE=0
REM BFCPEVERVERSION=1.0.0.0
REM BFCPEVERPRODUCT=Product Name
REM BFCPEVERDESC=Product Description
REM BFCPEVERCOMPANY=Your Company
REM BFCPEVERCOPYRIGHT=Copyright Info
REM BFCPEOPTIONEND
@ECHO ON
@setlocal
@echo off
if "%1"=="20170706_uniqueString_doNotForgetToOpenTheConsole" call :showConsole
cd %~dp0
set dependencies=richtextfx-0.7-M5-custom ikonli-openiconic-pack-1.9.0 ikonli-octicons-pack-1.9.0 ikonli-javafx-1.9.0 ikonli-core-1.9.0
for %%a in (%dependencies%) do call :addToPath %%a
for %%i in (%*) do call :concat %%i
rexx %cd%\ooRexxTryFX.rxj%args%
goto :eof

:showConsole
rem SHOWSELF
goto :eof

:addToPath
set CLASSPATH=%cd%\%1.jar;%CLASSPATH%
goto :eof

:concat
set args=%args% %1
goto :eof