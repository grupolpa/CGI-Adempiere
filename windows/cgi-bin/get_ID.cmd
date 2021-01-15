@ECHO OFF

:: ID provider for Adempiere distributed development
:: this is intended to be a replacement of AD_Sequence table for Adempiere development
:: and/or custom project distributed development
::
:: Author: Edwin Betancourt <EdwinBetanc0urt@outlook.com>

. ./bashlib

:: Must be called with variables
:: USER (developer UserID)
:: PASSWORD (developer password)
:: PROJECT (to allow custom project ID management)
:: TABLE (table for the ID)
:: ALTKEY (Alternate key - still not used - to verify alternate key collisions)
:: COMMENT (Comment for the ID)

:: Files in ../data
:: Project/Tablename.log (i.e. Adempiere/AD_Column.log) -> Log of ID's assignments
:: Project/Tablename.seq -> current sequence
:: Project/Tablename.lock -> temporary lock
:: Project/RegisteredDevelopers.pwd -> Passwords for registered developers

ECHO Content-type: text/html
ECHO ""

IF "x%FORM_USER%" = "x"
IF "x%FORM_PASSWORD%" = "x"
IF "x%FORM_TABLE%" = "x"
IF "x%FORM_PROJECT%" = "x" (
    ECHO "ERROR: Required parameters user, password, table, project"
    EXIT 1
)

:: TODO: Verify identity (auth)
SET FILEPWD=../data/%FORM_PROJECT%/RegisteredDevelopers.pwd
SET FOUNDLINE=`fgrep "%FORM_USER%|%FORM_PASSWORD%" %FILEPWD% | wc -l`
IF %FOUNDLINE% -ne 1 (
    ECHO "ERROR: Not registered developer"
    EXIT 1
)

:: TODO: Verify collision of alt-key

:: Get Current ID from Table
SET FILE=../data/%FORM_PROJECT%/%FORM_TABLE%.seq
SET FILELOCK=../data/%FORM_PROJECT%/%FORM_TABLE%.lock
SET FILELOG=../data/%FORM_PROJECT%/%FORM_TABLE%.log
SET FILENOTIFY=../data/%FORM_PROJECT%/%FORM_PROJECT%.notify

GOTO :while

:while 
IF -r %FILELOCK% (
    sleep 1
    GOTO :while
)

> %FILELOCK%

IF "x%FORM_PROJECT%" = "xAdempiere" (
    SET INITIALID=50000
)
ELSE (
    SET INITIALID=1000000
)

IF -s %FILE% (
    SET ID=`cat %FILE%`
)
ELSE (
    SET ID=%INITIALID%
)
IF "x%ID%" == x (
    SET ID=%INITIALID%
)
IF "%ID%" -lt %INITIALID% (
    SET ID=%INITIALID%
)

SET CONDITION=0
GOTO :while_2
:while_2
IF %CONDITION% == 0 (
    :: Increment the ID and verify it against the log (to allow usage of holes on mistakes)
    SET NEXTID=`expr %ID% + 1`
    SET CNTINLOG=`grep "^%ID%|" %FILELOG% | wc -l`
    IF %CNTINLOG% -le 0 (
        SET CONDITION=1
    )
    GOTO :while_2
)

:date
SET H=%time:~0,2%
IF "%H:~0,1%" == " " (
    set H=0%H:~1,1%
)
SET M=%time:~3,2%
IF "%M:~0,1%" == " " (
    SET M=0%M:~1,1%
)
SET S=%time:~6,2%
IF "%S:~0,1%" == " " (
    SET S=0%S:~1,1%
)
SET m=%date:~3,2%
IF "%m:~0,1%" == " " (
    SET m=0%m:~1,1%
)
SET d=%date:~0,2%
IF "%d:~0,1%" == " " (
    SET d=0%d:~1,1%
)
SET Y=%date:~-4%

ECHO %NEXTID% > %FILE%
GOTO :date
SET DATE=`date +'%Y%/%m%/%d% %H%:%M%:%S%'`
ECHO "%ID%|%FORM_USER%|%DATE%|%FORM_ALTKEY%|%FORM_COMMENT%" >> %FILELOG%
ECHO "Reserved %FORM_TABLE%_ID %ID% from %FORM_USER% at %DATE% : %FORM_COMMENT%" >> %FILENOTIFY%
DEL %FILELOCK%

ECHO "%ID%"
EXIT 0
