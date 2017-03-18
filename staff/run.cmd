set TMP=%CLASSPATH%
set CLASSPATH=%TMP%;%cd%\controlsfx-8.40.12.jar;
rexx staff.rxj
set CLASSPATH=%TMP%