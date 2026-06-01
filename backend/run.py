import os
from app import create_app

app = create_app()

if __name__ == '__main__':
    # Retrieve port from env, default to 5000
    port = int(os.environ.get('PORT', 5000))
    
    print(f"\n[SERVER] Launching Telemedicine Rest API on port {port}...")
    app.run(host='0.0.0.0', port=port, debug=True)
