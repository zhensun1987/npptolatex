@echo off
if "%~x1"==".tex" goto doit
   echo "%~f1" is not a .tex file, extension is "%~x1"
   pause
   exit /b
 
:doit

   echo SUMATRA>"%~dp1\build\cmcdde.tmp"
   echo control>>"%~dp1\build\cmcdde.tmp"
   echo [ForwardSearch("%~dp1\build\%~n1.pdf", "%~f1", %2, 0, 0, 0)]>>"%~dp1\build\cmcdde.tmp"
 
   "%PROGRAMFILES(x86)%\cmcdde.exe" @"%~dp1\build\cmcdde.tmp"
 
   del "%~dp1\build\cmcdde.tmp"
