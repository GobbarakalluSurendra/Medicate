import jwt
import datetime
from functools import wraps
from flask import request, jsonify
from app.config import Config

def generate_token(user_id, role, name, expires_in=24):
    """Generates a JWT token signed with Config.SECRET_KEY containing sub, role, name, and expiration time."""
    payload = {
        'sub': str(user_id),
        'role': role,
        'name': name,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=expires_in),
        'iat': datetime.datetime.utcnow()
    }
    return jwt.encode(payload, Config.SECRET_KEY, algorithm='HS256')

def token_required(allowed_roles=None):
    """
    Decorator to protect routes and verify JWT.
    
    Usage:
    @app.route('/something')
    @token_required(allowed_roles=['admin', 'doctor'])
    def endpoint(current_user):
        ...
    """
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            token = None
            
            if 'Authorization' in request.headers:
                auth_header = request.headers['Authorization']
                if auth_header.startswith('Bearer '):
                    token = auth_header.split(' ')[1]
            
            if not token:
                return jsonify({'message': 'Token is missing!'}), 401
            
            try:
                # Decode the token using our secret key
                data = jwt.decode(token, Config.SECRET_KEY, algorithms=['HS256'])
                current_user = {
                    'id': data['sub'],
                    'role': data['role'],
                    'name': data['name']
                }
                
                # Check for role permission if restrictions exist
                if allowed_roles and current_user['role'] not in allowed_roles:
                    return jsonify({'message': f'Access forbidden: {allowed_roles} role required.'}), 403
                    
            except jwt.ExpiredSignatureError:
                return jsonify({'message': 'Token has expired!'}), 401
            except jwt.InvalidTokenError:
                return jsonify({'message': 'Invalid token!'}), 401
            
            return f(current_user, *args, **kwargs)
        return decorated
    return decorator
