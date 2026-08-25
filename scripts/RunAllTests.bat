@echo off
setlocal EnableDelayedExpansion

set "VIVADO=C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat"
set "SCRIPT=C:\Users\muram\fpga-signal-processing\scripts\RunOneTest.tcl"
set "RESULTS=C:\Users\muram\fpga-signal-processing\results\verification"

if not exist "%RESULTS%" mkdir "%RESULTS%"

set PASSED=0
set FAILED=0
set INFRA_FAILED=0

echo Running FPGA verification tests

for %%T in (
    FirFilterTestbench
    MagnitudeSquaredTestbench
    PeakDetectorTestbench
    FftCoreTestbench
    FrequencyAnalysisPipelineTestbench
    AxiLiteControlTestbench
    FullPipelineTestbench
) do (
    echo Running %%T

    set "LOG=%RESULTS%\%%T.log"
    set "JOURNAL=%RESULTS%\%%T.jou"

    "%VIVADO%" -mode batch -log "!LOG!" -journal "!JOURNAL!" -source "%SCRIPT%" -tclargs %%T

    set "RETURN_CODE=!ERRORLEVEL!"

    if not "!RETURN_CODE!"=="0" (
        echo %%T: INFRA ERROR
        set /a INFRA_FAILED+=1
    ) else (
        findstr /C:"FAIL:" "!LOG!" >nul 2>&1

        if !ERRORLEVEL! EQU 0 (
            echo %%T: FAIL
            set /a FAILED+=1
        ) else (
            findstr /C:"TEST_COMPLETED: %%T" "!LOG!" >nul 2>&1

            if !ERRORLEVEL! EQU 0 (
                echo %%T: PASS
                set /a PASSED+=1
            ) else (
                echo %%T: INFRA ERROR
                set /a INFRA_FAILED+=1
            )
        )
    )
)

set /a TOTAL=PASSED+FAILED+INFRA_FAILED

echo.
echo Test Summary

for %%T in (
    FirFilterTestbench
    MagnitudeSquaredTestbench
    PeakDetectorTestbench
    FftCoreTestbench
    FrequencyAnalysisPipelineTestbench
    AxiLiteControlTestbench
    FullPipelineTestbench
) do (
    set "LOG=%RESULTS%\%%T.log"

    findstr /C:"TEST_COMPLETED: %%T" "!LOG!" >nul 2>&1

    if !ERRORLEVEL! EQU 0 (
        findstr /C:"FAIL:" "!LOG!" >nul 2>&1

        if !ERRORLEVEL! EQU 0 (
            echo %%T: FAIL
        ) else (
            echo %%T: PASS
        )
    ) else (
        echo %%T: INFRA ERROR
    )
)

echo.
echo Passed: %PASSED%
echo Failed: %FAILED%
echo Infra errors: %INFRA_FAILED%
echo Total: %TOTAL%

if %FAILED% EQU 0 if %INFRA_FAILED% EQU 0 (
    echo All tests passed
) else (
    echo Some tests did not pass
)

echo.
echo Press any key to close this window.
pause >nul

endlocal
