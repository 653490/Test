@echo off
setlocal enabledelayedexpansion

goto start

REM Functions
REM Settings
:promptSettings
REM Prompt the user for paths to input and output directories
set /p input_dir="Enter the path to the input folder: "
set /p output_dir="Enter the path to the output folder: "

REM Prompt the user for path to .blur-config.cfg
set /p tekno_blur_config="Enter the path to .blur-config.cfg: "

REM Prompt the user for file format to blur
set /p fileformat="Enter the input file format you want to blur: "
exit /B 0

REM Displays existing profiles
:displayProfiles
REM Echo all profiles
if exist profiles.txt (
    set /a lineCounter=1
    for /f "delims=" %%a in (profiles.txt) do (
        echo !lineCounter!. %%a
        set /a lineCounter+=1
    )
) else (
    echo There are no profiles yet
    goto profile_settings
)
exit /B 0

:start
REM Checks if path to Tekno's Blur is saved
if exist tekno_blur_path.txt (
    REM Reads path to Tekno's Blur
    for /f "tokens=1,2 delims==" %%a in (tekno_blur_path.txt) do set %%a=%%b
) else (
    REM Prompt the user for path to Tekno's Blur executable and saves
    set /p tekno_blur="Enter the path to Tekno's Blur executable: "
    echo tekno_blur=!tekno_blur!> tekno_blur_path.txt
)

:profile_settings
REM Choose your profile settings
echo Do you want to:
echo 1. Make a new profile
echo 2. Use an existing profile
echo 3. Delete a profile
echo 4. Use single-time profile
set /p userInput_profile=
echo.

REM Make a new profile
if !userInput_profile!==1 (
    set /p profileName="Enter the name for the new profile: "

    call:promptSettings

    REM Saves variables to [profileName]-path_config.txt
    echo input_dir=!input_dir!> !profileName!-path_config.txt
    echo output_dir=!output_dir!>> !profileName!-path_config.txt
    echo tekno_blur_config=!tekno_blur_config!>> !profileName!-path_config.txt
    echo fileformat=!fileformat!>> !profileName!-path_config.txt

    REM Saves profile name
    echo !profileName!>> profiles.txt
)

REM Use an existing profile
if !userInput_profile!==2 (
    call:displayProfiles

    REM Chose a profile
    set /p profileChoice="Enter the profile you want to use: "

    REM Goes to correct line in profiles.txt
    set /a lineCounter=1
    for /f "delims=" %%a in (profiles.txt) do (
        if !profileChoice!==!lineCounter! (
            set profileName=%%a
            goto readProfile
        )
        set /a lineCounter+=1
    )

    :readProfile
    for /f "tokens=1,2 delims==" %%a in (!profileName!-path_config.txt) do set %%a=%%b
    echo !input_dir!
)

REM  Delete a profile
if !userInput_profile!==3 (
    call:displayProfiles

    REM Chose a profile
    set /p profileChoice="Enter the profile you want to remove: "
    
    REM Remove the profile
    set savedProfile=False
    set lineCounter=1
    for /f "delims=" %%a in (profiles.txt) do (
        if !lineCounter!==!profileChoice! (
            del "%%a"-path_config.txt
        ) else (
            echo %%a>> tempProfiles.txt
            set savedProfile=True
        )
        set /a lineCounter+=1
    )
    
    REM Replace profiles.txt with tempProfiles.txt
    move /y tempProfiles.txt profiles.txt

    REM Delete profiles.txt if empty/nothing has been saved
    if !savedProfile!==False (
        del profiles.txt
    )

    goto profile_settings
)

REM Use single-time profile
if !userInput_profile!==4 (
    call:promptSettings
)

REM Prompt the user for shutdown after videos have been processed
echo Do you want to shutdown your pc after all files have been processed?
echo 1. Yes
echo 2. No
set /p prompt_shutdown=

REM Create the output directory if it doesn't exist
if not exist "!output_dir!" mkdir "!output_dir!"

REM Start the input check in a separate command prompt window
start cmd /C call inputCheck

REM Loop through all video files in the input directory
for %%f in ("!input_dir!\*.!fileformat!") do (
    REM Get the file name without extension
    set "filename=%%~nf"

    REM Apply Tekno's Blur effect using Tekno's Blur executable
    "!tekno_blur!" -i "%%f" -o "!output_dir!\!filename!_blurred.mp4" -c "!tekno_blur_config!" -n -p -v

    REM Stops blurring if requested
    for /f "tokens=1,2 delims==" %%a in (userInput_stopBlur.txt) do set %%a=%%b
    if !userInput_stopBlur!==1 (
        REM Stops blurring and deletes temporary userInput_stopBlur.txt file
        echo Stopped the process as requested.
        timeout -t 5
        goto Del_temp_files
    ) 
)

echo All videos have been processed.

REM Close inputCheck.bat
:x
REM Check if the task is running
for /f "tokens=1,2 delims==" %%a in (inputCheck_Started.txt) do set %%a=%%b
if !inputCheck_Started!==1 (
    REM If the task is found, kill it and delete temporary inputCheck_Started.txt file
    taskkill /fi "WindowTitle eq inputCheck"
) else (
    REM If the task is not found, wait and check again
    timeout /t 1
    goto x
)

REM Delete all temporary files used
:Del_temp_files
del userInput_stopBlur.txt
del inputCheck_Started.txt

REM Checks if user wanted to shutdown or not
if !prompt_shutdown!==1 (
    REM Shut down the PC after rendering is complete
    shutdown /s /f /t 3600

    REM Preventing shutdown or not
    set /p userInput_shutdown="Press 1 to prevent shutdown: "

    REM Checks shutdown input
    if !userInput_shutdown!==1 (
        shutdown /a
        echo Shutdown cancelled
    )
) else (
    pause
)

exit