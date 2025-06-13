@echo off
echo Token Refresh Service - Setup Script

REM Create virtual environment if it doesn't exist
if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt

REM Create .env file if it doesn't exist
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
    echo Please update the JWT_SECRET in .env file with a secure value
)

REM Run the application
echo Starting the application...
uvicorn app.main:app --reload

pause
