@echo off

:: Load environment variables from .env file
IF EXIST %~dp0.env (
    for /f "delims=" %%x in (%~dp0.env) do (set "%%x")
) ELSE (
    echo .env file not found
    exit /b 1
)

:: Set variables from arguments
SET OUTPUT_DIRECTORY=%1
SET JOB_NAME=%3
SET CATEGORY=%5

:: Run filebot command
filebot -script fn:amc --output "E:\Media" --action hardlink -non-strict --def skipExtract=n --def deleteAfterExtract=n --def excludeList="E:\Media\amc.txt" --def extractFolder="E:\Torrents\Extracted" --def clean=y --def animeDB=TheTVDB movieDB=TheMovieDB seriesDB=TheTVDB musicDB=ID3 --log-file="E:\Media\AMC-log.txt" --conflict override --def seriesFormat="{anime ? 'Anime' : 'TV Shows'}/{~plex.id}" movieFormat="{anime ? 'Anime Movies' : 'Movies'}/{~plex.id}" --def "ut_dir=%NZB_OUTPUT_FOLDER%" "ut_kind=multi" "ut_title=%NZB_JOB_NAME%" "ut_label=%NZB_CATEGORY%" "plex=localhost:32400:%PLEX_TOKEN%"

:: Check filebot command exit status and delete output directory if it failed
IF %ERRORLEVEL% NEQ 0 (
    echo Deleting %OUTPUT_DIRECTORY% due to failure
    rd /s /q "%OUTPUT_DIRECTORY%"
)

