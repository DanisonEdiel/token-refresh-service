#!/bin/bash

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please update the JWT_SECRET in .env file with a secure value"
fi

# Run the application
echo "Starting the application..."
uvicorn app.main:app --reload

# Note: This script is meant to be run on Linux/Mac
# For Windows, create a similar batch file
