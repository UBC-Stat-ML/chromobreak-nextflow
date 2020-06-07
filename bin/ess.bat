@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  ess startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%..

@rem Add default JVM options here. You can also use JAVA_OPTS and ESS_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS=

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto init

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto init

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:init
@rem Get command-line arguments, handling Windows variants

if not "%OS%" == "Windows_NT" goto win9xME_args

:win9xME_args
@rem Slurp the command line arguments.
set CMD_LINE_ARGS=
set _SKIP=2

:win9xME_args_slurp
if "x%~1" == "x" goto execute

set CMD_LINE_ARGS=%*

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\lib\nedry.jar;%APP_HOME%\lib\inits-2.12.1.jar;%APP_HOME%\lib\bayonet-4.1.2.jar;%APP_HOME%\lib\briefj-2.5.0.jar;%APP_HOME%\lib\binc-2.0.4.jar;%APP_HOME%\lib\guava-28.2-jre.jar;%APP_HOME%\lib\junit-4.12.jar;%APP_HOME%\lib\commons-lang3-3.5.jar;%APP_HOME%\lib\gson-2.7.jar;%APP_HOME%\lib\ca.ubc.stat.blang-3.25.1.jar;%APP_HOME%\lib\org.eclipse.xtext.xbase-2.12.0.jar;%APP_HOME%\lib\org.eclipse.xtext.common.types-2.12.0.jar;%APP_HOME%\lib\org.eclipse.xtext-2.12.0.jar;%APP_HOME%\lib\org.eclipse.xtext.util-2.12.0.jar;%APP_HOME%\lib\org.eclipse.xtend.lib-2.12.0.jar;%APP_HOME%\lib\failureaccess-1.0.1.jar;%APP_HOME%\lib\listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar;%APP_HOME%\lib\jsr305-3.0.2.jar;%APP_HOME%\lib\checker-qual-2.10.0.jar;%APP_HOME%\lib\error_prone_annotations-2.3.4.jar;%APP_HOME%\lib\j2objc-annotations-1.3.jar;%APP_HOME%\lib\hamcrest-core-1.3.jar;%APP_HOME%\lib\opencsv-2.3.jar;%APP_HOME%\lib\commons-math3-3.4.1.jar;%APP_HOME%\lib\org.eclipse.jgit-3.7.0.201502260915-r.jar;%APP_HOME%\lib\sqlite-jdbc-3.8.7.jar;%APP_HOME%\lib\commons-io-2.4.jar;%APP_HOME%\lib\slf4j-simple-1.6.1.jar;%APP_HOME%\lib\ejml-0.24.jar;%APP_HOME%\lib\mvel2-2.1.8.Final.jar;%APP_HOME%\lib\jblas-1.2.3.jar;%APP_HOME%\lib\commons-csv-1.4.jar;%APP_HOME%\lib\servlet-api-2.5.jar;%APP_HOME%\lib\org.eclipse.jdt.core-3.10.0.jar;%APP_HOME%\lib\org.eclipse.core.resources-3.7.100.jar;%APP_HOME%\lib\org.eclipse.core.expressions-3.4.300.jar;%APP_HOME%\lib\org.eclipse.core.runtime-3.7.0.jar;%APP_HOME%\lib\org.eclipse.core.filesystem-1.3.100.jar;%APP_HOME%\lib\org.eclipse.text-3.5.101.jar;%APP_HOME%\lib\log4j-1.2.16.jar;%APP_HOME%\lib\org.eclipse.equinox.common-3.8.0.jar;%APP_HOME%\lib\org.eclipse.osgi-3.11.2.jar;%APP_HOME%\lib\org.eclipse.emf.ecore.xmi-2.16.0.jar;%APP_HOME%\lib\org.eclipse.emf.ecore-2.21.0.jar;%APP_HOME%\lib\org.eclipse.emf.common-2.18.0.jar;%APP_HOME%\lib\guice-3.0.jar;%APP_HOME%\lib\antlr-runtime-3.2.jar;%APP_HOME%\lib\org.eclipse.osgi-3.7.1.jar;%APP_HOME%\lib\org.eclipse.core.jobs-3.5.100.jar;%APP_HOME%\lib\org.eclipse.core.contenttype-3.4.100.jar;%APP_HOME%\lib\org.eclipse.equinox.registry-3.5.101.jar;%APP_HOME%\lib\org.eclipse.equinox.preferences-3.4.1.jar;%APP_HOME%\lib\org.eclipse.equinox.common-3.6.0.jar;%APP_HOME%\lib\org.eclipse.equinox.app-1.3.100.jar;%APP_HOME%\lib\org.eclipse.core.commands-3.6.0.jar;%APP_HOME%\lib\javax.inject-1.jar;%APP_HOME%\lib\aopalliance-1.0.jar;%APP_HOME%\lib\asm-commons-5.0.1.jar;%APP_HOME%\lib\asm-tree-5.0.1.jar;%APP_HOME%\lib\asm-5.0.1.jar;%APP_HOME%\lib\jsch-0.1.50.jar;%APP_HOME%\lib\JavaEWAH-0.7.9.jar;%APP_HOME%\lib\httpclient-4.1.3.jar;%APP_HOME%\lib\slf4j-api-1.7.2.jar;%APP_HOME%\lib\httpcore-4.1.4.jar;%APP_HOME%\lib\commons-logging-1.1.1.jar;%APP_HOME%\lib\commons-codec-1.4.jar;%APP_HOME%\lib\jgrapht-demo-0.9.0.jar;%APP_HOME%\lib\jgrapht-ext-0.9.0.jar;%APP_HOME%\lib\jgrapht-ext-0.9.0-uber.jar;%APP_HOME%\lib\jgrapht-core-0.9.0.jar;%APP_HOME%\lib\jgraphx-2.0.0.1.jar;%APP_HOME%\lib\jgraph-5.13.0.0.jar;%APP_HOME%\lib\org.eclipse.xtend.lib.macro-2.12.0.jar;%APP_HOME%\lib\org.eclipse.xtext.xbase.lib-2.12.0.jar

@rem Execute ess
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %ESS_OPTS%  -classpath "%CLASSPATH%" mcli.ComputeESS %CMD_LINE_ARGS%

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable ESS_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
if  not "" == "%ESS_EXIT_CONSOLE%" exit 1
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
