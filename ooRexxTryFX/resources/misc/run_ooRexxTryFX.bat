@setlocal
@echo off
rem this batch file was converted to exe using the application "Bat To Exe Converter v2.4.3" by <www.f2ko.de>
rem change working directory to that of ooRexxTryFX
cd %~dp0
rem set the title of the cmd window
title ooRexxTryFX
rem call the concat function for all arguments 
for %%i in (%*) do (
  if not "%0"=="%%i" ( 
    call :concat %%i
  )
)
rem search properties file for showConsole property
rem show the console if the porperty is set to .true aka 1
%extd% /readpreferencevalue resources/config/preferences.conf showConsole
rem extd is a function provided by the bat to exe converter
if %result%==1 %extd% /showself

set dependencies=richtextfx-0.7-M5-custom ikonli-openiconic-pack-1.9.0 ikonli-octicons-pack-1.9.0 ikonli-javafx-1.9.0 ikonli-core-1.9.0 controlsfx-8.40.12.jar
rem add each dependency to the classpath via the addToPath function
for %%a in (%dependencies%) do call :addToPath %%a
rem start ooRexxTryFX with all of its arguments
@echo on
rexx ooRexxTryFX.rxj%args%
goto :eof

:addToPath
set CLASSPATH=%cd%\java\%1.jar;%CLASSPATH%
goto :eof

:concat
set args=%args% %1
goto :eof