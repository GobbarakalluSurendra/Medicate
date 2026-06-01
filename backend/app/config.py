import os
from dotenv import load_dotenv

# Load .env file if it exists
load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'super-secret-telemedicine-key')
    
    # Database configuration
    DB_HOST = os.environ.get('DB_HOST', 'localhost')
    DB_USER = os.environ.get('DB_USER', 'root')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', '')
    DB_NAME = os.environ.get('DB_NAME', 'telemedicine_db')
    DB_PORT = int(os.environ.get('DB_PORT', 3306))
    DB_SSL = os.environ.get('DB_SSL', 'false').lower() in ('true', '1', 't')
    
    # Gemini API Key
    GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', '')

