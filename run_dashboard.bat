@echo off
:: ============================================================
::  run_dashboard.bat
::  Project  : Credit Card Fraud & Sales Analytics
::  Author   : Janakivarshasree
::  Dataset  : credit_card_fraud_2026.csv
::  Course   : Data Analytics with AI – IBM × BharathCares
:: ============================================================

title Credit Card Fraud ^& Sales Analytics - Janakivarshasree

echo.
echo  ============================================================
echo   Credit Card Fraud ^& Sales Analytics Dashboard
echo   Author   : Janakivarshasree
echo   Dataset  : credit_card_fraud_2026.csv  ^(20,000 records^)
echo   Python   : Anaconda  ^(C:\Users\janak\anaconda3^)
echo  ============================================================
echo.

:: ── Move to the folder where this .bat lives ────────────────────────────────
cd /d "%~dp0"

:: ── Detect Python (prefer Anaconda, fallback to system python) ───────────────
echo [1/4] Detecting Python...

set "PYTHON_EXE="

:: Check Anaconda (primary)
if exist "C:\Users\janak\anaconda3\python.exe" (
    set "PYTHON_EXE=C:\Users\janak\anaconda3\python.exe"
    set "STREAMLIT_EXE=C:\Users\janak\anaconda3\Scripts\streamlit.exe"
    echo       Found: Anaconda Python  ^(C:\Users\janak\anaconda3^)
    goto :python_found
)

:: Check miniconda
if exist "C:\Users\janak\miniconda3\python.exe" (
    set "PYTHON_EXE=C:\Users\janak\miniconda3\python.exe"
    set "STREAMLIT_EXE=C:\Users\janak\miniconda3\Scripts\streamlit.exe"
    echo       Found: Miniconda Python
    goto :python_found
)

:: Check system python
where python >nul 2>&1
if %errorlevel% equ 0 (
    set "PYTHON_EXE=python"
    set "STREAMLIT_EXE=streamlit"
    echo       Found: System Python
    goto :python_found
)

:: No Python found
echo.
echo  ERROR: Python not found!
echo  Please install Anaconda from https://www.anaconda.com/download
echo  or Python 3.9+ from https://www.python.org/downloads/
echo.
pause
exit /b 1

:python_found
"%PYTHON_EXE%" --version
echo.

:: ── Install / verify required packages ──────────────────────────────────────
echo [2/4] Checking required packages...
"%PYTHON_EXE%" -m pip install streamlit plotly pandas numpy seaborn matplotlib --quiet
if %errorlevel% neq 0 (
    echo  WARNING: Package install encountered issues. Trying to continue...
    echo.
)
echo       All packages ready. OK
echo.

:: ── Check dataset exists ────────────────────────────────────────────────────
echo [3/4] Checking dataset...
if not exist "..\credit_card_fraud_2026.csv" (
    echo.
    echo  ERROR: Dataset not found!
    echo.
    echo  Expected location:
    echo    %~dp0..\credit_card_fraud_2026.csv
    echo.
    echo  Please place  credit_card_fraud_2026.csv  one folder above:
    echo    master class5\credit_card_fraud_2026.csv
    echo.
    pause
    exit /b 1
)
echo       Dataset found: credit_card_fraud_2026.csv  OK
echo.

:: ── Launch Dashboard ─────────────────────────────────────────────────────────
echo [4/4] Starting Streamlit dashboard...
echo.
echo  ============================================================
echo   Dashboard URL  :  http://localhost:8501
echo   Stop dashboard :  Press Ctrl+C in this window
echo  ============================================================
echo.

:: Open browser after 3 seconds
start "" cmd /c "timeout /t 3 /nobreak >nul && start http://localhost:8501"

:: Run Streamlit using the detected Python
"%PYTHON_EXE%" -m streamlit run app.py ^
    --server.port 8501 ^
    --server.headless false ^
    --browser.gatherUsageStats false

:: ── After Streamlit exits ────────────────────────────────────────────────────
echo.
echo  Dashboard stopped.
echo  Press any key to close this window...
pause >nul
