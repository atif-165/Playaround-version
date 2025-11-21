@echo off
echo ╔════════════════════════════════════════════════════════════╗
echo ║   PlayAround Database Population (Python)                 ║
echo ║   Generating realistic dummy data...                       ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Python is not installed!
    echo.
    echo Please install Python from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Check if firebase-admin is installed
python -c "import firebase_admin" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 📦 Installing dependencies...
    pip install -r scripts/requirements.txt
    echo.
)

REM Check if service account key exists
if not exist "firebase-service-account.json" (
    echo ⚠️  WARNING: firebase-service-account.json not found!
    echo.
    echo Please follow these steps:
    echo 1. Go to Firebase Console ^> Project Settings ^> Service Accounts
    echo 2. Click "Generate New Private Key"
    echo 3. Save as: firebase-service-account.json
    echo.
    echo See PYTHON_DATABASE_SETUP.md for detailed instructions.
    pause
    exit /b 1
)

echo ⚠️  WARNING: This will clean all existing dummy data!
echo.
set /p confirm="Are you sure you want to continue? (Y/N): "

if /i "%confirm%" NEQ "Y" (
    echo.
    echo Operation cancelled.
    pause
    exit /b
)

echo.
echo 🚀 Starting database population...
echo.

python scripts/populate_firestore.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Database population completed successfully!
) else (
    echo.
    echo ❌ Error occurred during population.
    echo Please check the error messages above.
)

echo.
pause

