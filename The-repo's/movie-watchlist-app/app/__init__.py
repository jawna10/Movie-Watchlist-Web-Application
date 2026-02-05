from flask import Flask
from flask_cors import CORS
from app.database import init_db

def create_app():
    app = Flask(__name__, static_folder='../static')
    CORS(app)
    
    # Initialize database
    init_db()
    
    # Register routes FIRST
    from app.routes import register_routes
    register_routes(app)
    
    # Initialize Prometheus metrics AFTER routes
    from prometheus_flask_exporter import PrometheusMetrics
    metrics = PrometheusMetrics(app)
    
    return app