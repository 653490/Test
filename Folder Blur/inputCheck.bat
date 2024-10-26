@echo off
setlocal enabledelayedexpansion
title inputCheck

REM Checks if inputCheck.bat has started
set inputCheck_Started=1
echo inputCheck_Started=!inputCheck_Started!> inputCheck_Started.txt

REM Function to check for user input for stopping blurring
:checkInput
set /p userInput_stopBlur="Press 1 to stop blurring after processing current file: "
if !userInput_stopBlur!==1 (
    REM Passes userInput_stopBlur to main file
    echo userInput_stopBlur=!userInput_stopBlur!> userInput_stopBlur.txt

    echo Stopping the process as requested.
    timeout -t 5
    exit
)
