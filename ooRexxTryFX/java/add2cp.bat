	@echo off
	rem ---rgf, 2006-11-28
	rem "add2cp.bat" ... adds file as fully quailfied file to CLASSPATH;
	rem                  if no file given, adds the directory to CLASSPATH
	
	   rem add a semi-colon?
	if "%CLASSPATH%"=="" goto continue
	SET CLASSPATH=%CLASSPATH%;
	
	:continue
	   rem need to add a file ?     rgf, 2011-09-19: handle also blank delimited names
	if "%1"=="" goto noArg
	set CLASSPATH=%CLASSPATH%%cd%\%*
	goto end
	
	:noArg
	   rem need to add a directory only
	set CLASSPATH=%CLASSPATH%%cd%
	
	:end
	echo CLASSPATH=%CLASSPATH%
