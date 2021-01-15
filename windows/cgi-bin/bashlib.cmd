@ECHO OFF
:: Brough from GPL http://sourceforge.net/projects/bashlib/

:: -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
:: Initialization stuff begins here. These things run immediately, and
:: do the parameter/cookie parsing.
::
:: Author: Edwin Betancourt <EdwinBetanc0urt@outlook.com>
:: -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

:: Global debug flag. Set to 0 to disable debugging throughout the lib
SET DEBUG=0

:: capture stdin for POST methods. POST requests don't always come in
:: with a newline attached, so we use cat to grab stdin and append a newline.
:: This is a wonderful hack, and thanks to paulb.
SET STDIN=$(cat)
IF DEFINED STDIN (
    SET QUERY_STRING="%STDIN%&%QUERY_STRING%"
)

:: Handle GET and POST requests... (the QUERY_STRING will be set)
IF DEFINED QUERY_STRING (
    :: name=value params, separated by either '&' or ';'
    IF ECHO %QUERY_STRING% | grep '=' >NUL (
        FOR %%Q IN $(ECHO %QUERY_STRING% | tr ";&" "\012") DO (
            :: Clear our local variables
            SET name=
            SET value=
            SET tmpvalue=

            :: get the name of the key, and decode it
            SET name=${Q%%=*}
            SET name=$(ECHO %name% | \
                sed -e 's/%\(\)/\\\x/g' | \
                tr "+" " ")
            SET name=$(ECHO %name% | \
                tr -d ".-")
            SET name=$(printf %name%)

            ::
            :: get the value and decode it. This is tricky... printf chokes on
            :: hex values in the form \xNN when there is another hex-ish value
            :: (i.e., a-fA-F) immediately after the first two. My (horrible)
            :: solution is to put a space aftet the \xNN, give the value to
            :: printf, and then remove it.
            ::
            SET tmpvalue=${Q#*=}
            SET tmpvalue=$(ECHO %tmpvalue% | \
                sed -e 's/%\(..\)/\\\x\1 /g')
            :: ECHO "Intermediate \$value: ${tmpvalue}" 1>&2

            :: Iterate through tmpvalue and printf each string, and append it to
            :: value
            FOR %%i IN (%tmpvalue%) DO (
                SET g=$(printf %%i)
                SET value="%value%%g%"
            )
          :: value=$(ECHO ${value})

          eval "export FORM_%name%='%value%'"
        )
    )
    :: keywords: foo.cgi?a+b+c
    ELSE (
        SET Q=$(ECHO %QUERY_STRING% | tr '+' ' ')
        eval "export KEYWORDS='%Q%'"
    )
)

:: this section works identically to the query string parsing code,
:: with the (obvious) exception that variables are stuck into the
:: environment with the prefix COOKIE_ rather than FORM_. This is to
:: help distinguish them from the other variables that get set
:: automatically.
IF DEFINED HTTP_COOKIE (
    FOR %%Q IN %HTTP_COOKIE% DO (
        :: Clear our local variables
        SET name=
        SET value=
        SET tmpvalue=

        :: Strip trailing ; off the value
        SET Q=${Q%;}

        :: get the name of the key, and decode it
        SET name=$(echo %name% | \
            sed -e 's/%\(\)/\\\x/g' | \
            tr "+" " ")
        SET name=$(echo %name% | \
              tr -d ".-")
        SET name=$(printf %name%)

        :: Decode the cookie value. See the parameter section above for
        :: an explanation of what this is doing.
        SET tmpvalue=${Q#*=}
        SET tmpvalue=$(echo %tmpvalue% | \
            sed -e 's/%\(..\)/\\\x\1 /g')
        :: echo "Intermediate \$value: ${tmpvalue}" 1>&2

        :: Iterate through tmpvalue and printf each string, and append it to
        :: value
        FOR %%i IN %tmpvalue% DO (
            SET g=$(printf %%i)
            SET value="%value%%g%"
        )
        :: value=$(echo ${value})

        :: Export COOKIE_${name} into the environment
        :: echo "exporting COOKIE_${name}=${value}" 1>&2
        eval "export COOKIE_%name%='%value%'"
    )
)

:: end snippet from bashlib