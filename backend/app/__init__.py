from flask import Flask
from flask_cors import CORS
from app.config import Config
from app.models.database import init_db

def create_app(config_class=Config):
    """
    App Factory constructor for initializing the Flask REST API.
    Handles CORS config, blueprint mapping, and DB table creations.
    """
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Enable CORS globally for all routes
    CORS(app)

    # Run Database table initialization on startup
    with app.app_context():
        try:
            init_db()
        except Exception as e:
            print(f"[BOOT WARNING] Failed to initialize database on startup. Make sure MySQL is running: {e}")

    # Register the main API router blueprint
    from app.routes import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')

    # Global error handler to format exceptions as JSON with CORS headers
    from werkzeug.exceptions import HTTPException
    from flask import jsonify

    @app.errorhandler(Exception)
    def handle_exception(e):
        if isinstance(e, HTTPException):
            return jsonify({
                'message': e.description,
                'error': e.name
            }), e.code
            
        response = {
            'message': 'Server Error. Ensure your database is active.',
            'error': str(e)
        }
        return jsonify(response), 500

    @app.route('/')
    def root():
        return {
            'service': 'Telemedicine & Hospital Appointment Management System API',
            'status': 'online',
            'version': '1.0.0'
        }, 200

    return app
