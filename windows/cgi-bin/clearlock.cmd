@ECHO OFF

:: Author: Edwin Betancourt <EdwinBetanc0urt@outlook.com>

. ./bashlib.cmd

SET CAT=/bin/cat

ECHO Content-type: text/plain
ECHO ""

IF "x%FORM_PROJECT%" == "x"
IF "x%FORM_TABLE%" == "x" (
    ECHO "ERROR: Required parameters table, project"
    EXIT 1
)

SET FILELOCK=../data/%FORM_PROJECT%/%FORM_TABLE%.lock
IF -r %FILELOCK% (
    DEL /f %FILELOCK%
)
ECHO DEL /f %FILELOCK%
