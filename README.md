# npptolatex: from http://johnbruer.com/2013/05/21/latex-editing-using-notepad/

LaTeX is a powerful markup language used for typesetting documents. Its ability to professionally typeset mathematics in particular makes it a commonly used tool in academia. If you are reading this, you probably know all about LaTeX, so I don’t need to explain it in detail. Instead, I want to explain how I came to use Notepad++ as my LaTeX editor.


There are really two classes of LaTeX editors: source and WYSIWYM1. Newcomers to LaTeX may prefer WYSIWYM editors like LyX, but at some point you will run a situation where you really need to make changes directly to the markup code. Also, since many academics directly edit LaTeX source files, it is a good habit to learn how to do this from the onset if you work in this environment.

A good source editor will have features like syntax highlighting, bracket matching, auto-completion, code folding, etc. that differentiate it from a plain text editor like Notepad. These tools will be familiar to anyone who has programmed. They help improve your code's readability and can help you avoid making mistakes. A slew of tools exists that bring these features to LaTeX editing. Many of these integrate PDF viewers so that you can easily see the output of your code while you work. You can think of these as LaTeX IDE’s. In fact, Wikipedia has a large comparison table here that shows the various features offered by these editors.

Given the large number of tools available specifically for LaTeX editing, why use a “dumb” tool like Notepad++? In my experience, it’s just a better text editor than some of the more integrated tools. It gives you all the features of a good source editor that I mentioned above in a package that is lightweight, highly customizable, and most importantly won’t crash on you! It is built for Windows. If you’re looking for a cross-platform solution, this is not it. However, that it solely targets Windows brings with it added efficiency and stability. In fact, I’m writing this post in Notepad++ right now2. With four other documents open, it is using a total of 12.6MB of memory. Compare that to TeXworks, the cross-platform editor included with MiKTeX. This is really a great lightweight, extensible TeX editor, but with one document open, syntax highlighting and inline spell checking enabled, it is using 19.8MB of memory.3 Now, I’m not going to quibble over 7MB of memory in the age of web browsers using hundreds of megabytes, but I want to emphasize that Notepad++ gives you more for less. Notepad++ works with many other languages (and includes code folding) and can really serve as a general-purpose coding tool rather than one dedicated to LaTeX.

However, there is one important issue. Notepad++ does not come with a built-in method to view the PDF output of LaTeX documents or perform forward/inverse search.4 These, for me, are crucial features when working with LaTeX documents, and I certainly would not use Notepad++ without these features. The rest of this post will show you how to add them to Notepad++.

Prerequisites

The post assumes that you already have a working LaTeX distribution that is accessible on your path.5

For the following you will need:

Notepad++
NppExec, available through the plugin manager in Notepad++6
SumatraPDF, a lightweight PDF reader supporting forward and inverse search
CMCDDE, a utility to send DDE commands to SumatraPDF
(optional) Aspell and dictionary, for “smart” spell checking7
Syntax Highlighting

Notepad++ is built on the Scintilla text-editing library, which includes support for highlighting TeX files. I preferred to make some changes to the style, and unfortunately this requires you to create a user-defined language. The user interface to do this in Notepad++ is under Language > Define your language.... Here you can specify your own options and export them to a UDL (User Defined Language) XML file. If you wish, you can import my UDL file for TeX and modify it to suit your needs.8 To force Notepad++ to use your user-defined language when opening TeX files, disable the built-in TeX processor by going to Settings > Preferences... > Language Menu/Tab Settings and moving TeX from the Available items list to the Disabled items list.

Note that by default you will not have auto-complete available for a user-defined language. In order to correct this, you can copy the tex.xml file from your Notepad++ install (on my machine this is C:\Program Files (x86)\Notepad++\plugins\APIs\tex.xml) to a file named userDefineLang.xml in your settings folder (on my machine C:\Users\<username>\AppData\Roaming\Notepad++\plugins\APIs\userDefineLang.xml). This is somewhat inelegant as the same auto-completion list must be used for all user-defined languages. Notepad++ is not perfect.

NppExec

The NppExec plugin allows us to script Notepad++ to perform actions that interact with other programs on the system. It is the crucial piece to allow us to “integrate” PDF viewing into Notepad++. Make sure that it is installed properly by checking to see if the NppExec sub-menu appears under the Plugins menu.

The “build” batch file

We will use the plugin to call a Windows batch file that will then make the appropriate calls to our TeX distribution. Credit for the original version of these batch files goes to the blog http://blog.sophomatics.net/?p=7. I have made some modifications, and you should also consider modifications that better fit your needs.

pdflatex_build.bat:

@echo off
if "%~x1"==".tex" goto pdflatex
   echo "%~f1" is not a recognized type, extension is "%~x1"
   pause
   exit /b

:pdflatex
   cd /d "%~dp1"
   IF NOT EXIST "%~dp1\build" mkdir build

   start "inverseSearch" /min "%PROGRAMFILES(x86)%\SumatraPDF\SumatraPDF.exe" -inverse-search "\"%PROGRAMFILES(x86)%\Notepad++\notepad++.exe\" -n%%l \"%%f\"" -reuse-instance

   pdflatex.exe -draftmode -interaction=batchmode -aux-directory="%~pd1\build" -output-directory="%~pd1\build" "%~pdn1"
   echo. && echo.
   bibtex.exe "%~dp1\build\%~n1.aux"
   echo. && echo.
   pdflatex.exe -draftmode -interaction=batchmode -aux-directory="%~pd1\build" -output-directory="%~pd1\build" "%~pdn1"
   echo. && echo.
   pdflatex.exe -interaction=batchmode -synctex=-1 -aux-directory="%~pd1\build" -output-directory="%~pd1\build" -quiet "%~pdn1"
   echo. && echo.

   type "%~dp1\build\%~n1.log" | findstr Warning:

   start "openPDF" "%PROGRAMFILES(x86)%\SumatraPDF\SumatraPDF.exe"  "%~dp1\build\%~n1.pdf" -reuse-instance

   echo SUMATRA>"%~dp1\build\cmcdde.tmp"
   echo control>>"%~dp1\build\cmcdde.tmp"
   echo [ForwardSearch("%~dp1\build\%~n1.pdf", "%~f1", %2, 0, 0, 0)]>>"%~dp1\build\cmcdde.tmp"

   "%PROGRAMFILES(x86)%\cmcdde.exe" @"%~dp1\build\cmcdde.tmp"

   del "%~dp1\build\cmcdde.tmp"
   exit /b
Let’s quickly break this down so that it is clear exactly what the batch file does. First we check to make sure the file we are processing has a .tex extension. If you name your LaTeX files in some different way, you will want to add another if statement to account for this.

Provided that we have a file that is (presumably) written in (La)TeX, we jump to the :pdflatex label. I prefer to place the output of my TeX builds into a subdirectory called build. This removes clutter from the directory where I save my TeX file. If this directory does not exist, we create it.

Then we start SumatraPDF minimized with two command-line options. The -inverse-search option tells SumatraPDF to call Notepad++ whenever we double-click our PDF output and pass it the line number and filename corresponding to the LaTeX source code. The -reuse-instance option tells SumatraPDF not to create a new process. Check the paths of SumatraPDF and Notepad++ in case you have installed them in different locations.

Next we run pdflatex to generate the PDF file from our LaTeX source. You will notice that we end up running pdflatex multiple times. Due to the way the process works, multiple runs of pdflatex are needed for the bibliography and any internal references to figures, tables, etc. LaTeX-specific packages are smarter about how many times the process needs to be run. Sometimes one pass is enough, but we will perform three passes here all the time. At some point I may modify this behavior, but for now the extra runs really do not create a problem for modest-sized documents.

The options on the first run specify that we should produce no output (-draftmode), halt on errors while sending all messages to a log file (-interaction=batchmode), and save all files to the auxiliary build directory (-aux-directory=).9 We use echo. && echo. to output a new line in the console window for readability. Then we use bibtex to create the bibliography if necessary and then run pdflatex again to incorporate those changes.10 The final run of pdflatex removes the -draftmode option so that we will actually get a PDF output. In order to use forward/inverse search we set the -synctex=1 option. Finally -quiet will suppress all output to the console except for errors.

Now that we have run pdflatex to generate our document, we use type to check the log file for warnings and output them to the console. Remember that we already set pdflatex to output errors to the console. We will change some settings later in NppExec to make it easier for us to spot errors in the console window.

Finally, we open the output in SumatraPDF. The remaining commands use CMCDDE to communicate with SumatraPDF, and we will discuss their function when we talk about forward search.

Configuring NppExec

We will now use NppExec to call this batch file from within Notepad++. Navigate to Plugins > NppExec > Execute... or use the shortcut F6 to bring up the execute window.

Enter the following commands:

NPP_SAVE
C:\<path to batch file>\pdflatex_build.bat "$(FULL_CURRENT_PATH)" $(CURRENT_LINE)
The first command is part of a set of Notepad++-specific commands included in NppExec. Unsurprisingly, NPP_SAVE saves the current file. We then call the batch file described above and pass it the current file open in the editor and which line our cursor is on.11

Press Save... in the NppExec window and give this action a name like pdflatex_build. You can now run this script by pressing F6, selecting it from the menu, and pressing OK. This works well enough, but you probably want to create a keyboard shortcut so that you can easily invoke the script. In order to do that, go to Plugins > NppExec > Advanced Options.... Find the Item name: text box under the Menu item group. Enter something like Run pdflatex, and in the Associated script drop-down select the pdflatex_build script we just created. Click Add/Modify and your new menu item should appear in the list above. Make sure that Place to the Macros submenu is checked and press OK.

Now you can look under the Macro menu and see that Run pdflatex is there. We still need to assign it a keyboard shortcut to make it truly useful. To do this go to Settings > Shortcut Mapper..., select Plugin commands and find Run pdflatex (it’s probably near the bottom). Double-click it to assign a shortcut. For instance, I chose Alt+~.12 Press Close, and now you should see it in the Macro menu with the keyboard shortcut listed beside it.

Console Highlighting

I inevitably make errors when writing source code, and LaTeX documents are no exception for me. When one of these errors comes up, I would like it prominently displayed in the console output. The settings passed to pdflatex will cause errors to show in the console window, and we can take advantage of NppExec’s console filtering to bring these to our attention. In fact, we will set NppExec to highlight errors in bold, red text and warnings in bold, blue text.13 Bring up the Console Output Filters settings by going to Plugins > NppExec > Console Output Filters.... Alternatively, you can press Shift+F6. You do not need to make any changes to the Filter tab. Instead, make it so your Replace and HighLight tabs match the images below.

Set the replacement filter to change forward slashes into back slashes. This will make the paths to files in the console output appear in the correct Windows format. This is important as the first filter on the HighLight tab will require this path format.
Set the replacement filter to change forward slashes into back slashes. This will make the paths to files in the console output appear in the correct Windows format. This is important as the first filter on the HighLight tab will require this path format.

The first two highlight filters look for errors and display them in bold, red text. The last filter will display warnings in bold, blue text.
The first two highlight filters look for errors and display them in bold, red text. The last filter will display warnings in bold, blue text.

Forward and Inverse Search

The main work to compile LaTeX files into PDF using Notepad++ is done, but there are a couple more things you may want to incorporate into your setup. We have already taken care of inverse search by having our batch file load SumatraPDF with the correct command-line options. You can now double-click any part of your PDF file and Notepad++ will jump to the correct line of the source. Note, though, that this will not work when you use one main LaTeX file with \include{} statements to load the parts of your document. Unfortunately I have no way around this, and this is something that many dedicated LaTeX packages handle without issue.

As for forward search, I mentioned that the last few lines of the batch file above communicate with SumatraPDF. In fact they send a forward search command that will scroll the PDF document and highlight the corresponding output of the current line of LaTeX source code. Sometimes, though, you may want to execute a forward search without having to rebuild the entire document. In that case we can create a new batch file and follow the steps in the NppExec section above to create a new menu item and keyboard shortcut.

Batch File

We will pull the relevant sections from the pdflatex_build.bat file above to create our new batch file.

pdflatex_forward.bat:
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
We already know what the beginning part does, so let’s now start from line 9. The echo command literally echoes its input. By using the redirection >, we can send this echo to a file in our build directory called cmcdde.tmp. Note that a single chevron will create a new file, overwriting any existing cmcdde.tmp. On the following lines we use two chevrons to indicate that we want to append the content to the existing file. The result is that we have a text file containing three lines.

The first reads SUMATRA and simply gives the name of the application that will receive our DDE command. We next specify that we want to send a control command to the application. Finally we give the name of the command (ForwardSearch) along with its necessary options.

The ForwardSearch command takes six arguments:

Full path to the PDF file
Full path to the LaTeX source file
Line number of the source file
Column number of the source file (currently unused, so pass 0)
New window? Pass 1 to open the PDF file in a new window
Focus? Pass 1 to give SumatraPDF focus
This particular example will have SumatraPDF scroll to and highlight the portion of the PDF file corresponding to the current line of source code in Notepad++.14 It will only create a new window if the file is not open, and it will not steal focus from Notepad++.

We send the command by executing the program cmcdde.exe and specifying this text file with our instructions. I placed cmcdde.exe in my 32-bit Program Files folder, but you may place it anywhere. Just update the path in the batch file to match your location. Finally we clean up by deleting our temporary command file.

Additional Option

Note that sometimes you may want to execute a forward search and simultaneously give focus to SumatraPDF. If you want that you can create another batch file where you change the focus argument in the ForwardSearch command to 1. For example, I have set up the shortcut Alt+A to execute a forward search and Alt+Shift+A to execute a forward search while changing the focus to SumatraPDF.

Smart spell checking

Before version 6.3.3, Notepad++ did not include an inline spell checker, i.e., one that underlines your mistakes with a red squiggly as you type. This required us to run spell check manually. Now the included DSpellCheck plugin adds inline spell checking and largely renders this section obsolete. However, the inline spell checker is not very smart. While it tries to only check comments and strings, this functionality does not seem to work well for the built-in TeX language definition, and it certainly does not work for the user-defined TeX I provided above. I hope that this can be remedied in the future, but for now the result is LaTeX files with red squiggly lines that are not in fact spelling errors. If you are able to cope with that fact—and syntax highlighting certainly helps—then you do not need to bother with any of the following. Otherwise, these instructions will help you set up an external spell checker that will ignore LaTeX commands.

As stated in the prerequisites, you will need to download Aspell and the corresponding dictionary for your language.15 Then bring up the execute window with F6 and create a new script containing the following commands:

NPP_SAVE
NPP_RUN "C:\Program Files (x86)\Aspell\bin\aspell.exe" -t --add-tex-command="definecolor ppp,lstdefinestyle pp,color p,operatorname p" check "$(FULL_CURRENT_PATH)"
We simply save the file, and execute Aspell. The -t option specifies TeX mode which ignores spelling errors in commands. You may notice that some of your commands (particularly those belonging to add-on packages) are not recognized by default. Use the --add-tex-command option to include those. Simply give the command name followed by a space and specify its parameters and optional parameters. A lowercase p indicates a parameter that should not be checked for spelling, while a capital P indicates one that should be checked. Similarly o and O perform those functions for optional parameters. The check command puts Aspell in spell checking mode, and we pass the full path of the file we want spell checked. Add this command to your Macro menu and assign a keyboard shortcut for easy access.

Conclusion

This setup is somewhat involved, but it turns Notepad++ into a great platform for LaTeX editing. It is not perfect, and I have tried to point out some caveats along the way. If you have suggestions to improve any of these modifications, please let me know in the comments. I also welcome suggestions for different LaTeX editing environments (although I probably will not switch to Emacs or vim).
