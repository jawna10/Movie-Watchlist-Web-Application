from flask import jsonify, request, send_from_directory
from app.database import get_db
from app.models import validate_movie, format_movie
from datetime import datetime

def register_routes(app):
    
    @app.route('/')
    def index():
        return send_from_directory('../static', 'index.html')
    
    @app.route('/health')
    def health():
        return jsonify({'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()}), 200
    
    @app.route('/app-metrics')
    def app_metrics():
        db = get_db()
        total_movies = db.movies.count_documents({})
        watched_movies = db.movies.count_documents({'watched': True})
        unwatched_movies = total_movies - watched_movies
        
        return jsonify({
            'total_movies': total_movies,
            'watched': watched_movies,
            'unwatched': unwatched_movies,
            'timestamp': datetime.utcnow().isoformat()
        }), 200
    
    @app.route('/movie/<movie_id>', methods=['POST'])
    def create_movie(movie_id):
        db = get_db()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Validate
        errors = validate_movie(data)
        if errors:
            return jsonify({'errors': errors}), 400
        
        # Check if movie with this ID already exists
        existing = db.movies.find_one({'id': movie_id})
        if existing:
            return jsonify({'error': 'Movie with this ID already exists'}), 409
        
        movie = {
            'id': movie_id,
            'title': data.get('title'),
            'genre': data.get('genre', ''),
            'year': int(data.get('year', 0)) if data.get('year') else None,
            'rating': float(data.get('rating', 0)) if data.get('rating') else None,
            'watched': data.get('watched', False),
            'notes': data.get('notes', ''),
            'created_at': datetime.utcnow().isoformat()
        }
        
        result = db.movies.insert_one(movie)
        movie['_id'] = str(result.inserted_id)
        
        return jsonify(format_movie(movie)), 201
    
    @app.route('/movie/<movie_id>', methods=['PUT'])
    def update_movie(movie_id):
        db = get_db()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Validate
        errors = validate_movie(data)
        if errors:
            return jsonify({'errors': errors}), 400
        
        update_data = {
            'title': data.get('title'),
            'genre': data.get('genre', ''),
            'year': int(data.get('year', 0)) if data.get('year') else None,
            'rating': float(data.get('rating', 0)) if data.get('rating') else None,
            'watched': data.get('watched', False),
            'notes': data.get('notes', ''),
            'updated_at': datetime.utcnow().isoformat()
        }
        
        result = db.movies.update_one(
            {'id': movie_id},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Movie not found'}), 404
        
        updated_movie = db.movies.find_one({'id': movie_id})
        return jsonify(format_movie(updated_movie)), 200
    
    @app.route('/movie/<movie_id>', methods=['DELETE'])
    def delete_movie(movie_id):
        db = get_db()
        result = db.movies.delete_one({'id': movie_id})
        
        if result.deleted_count == 0:
            return jsonify({'error': 'Movie not found'}), 404
        
        return jsonify({'message': 'Movie deleted successfully'}), 200
    
    @app.route('/movie/<movie_id>', methods=['GET'])
    def get_movie(movie_id):
        db = get_db()
        movie = db.movies.find_one({'id': movie_id})
        
        if not movie:
            return jsonify({'error': 'Movie not found'}), 404
        
        return jsonify(format_movie(movie)), 200
    
    @app.route('/movie', methods=['GET'])
    def get_all_movie_ids():
        db = get_db()
        movies = list(db.movies.find({}, {'_id': 0, 'id': 1}))
        movie_ids = [movie['id'] for movie in movies]
        
        return jsonify(movie_ids), 200
    
    @app.route('/movies', methods=['GET'])
    def get_all_movies():
        """Get all movies with full details for frontend"""
        db = get_db()
        movies = list(db.movies.find({}))
        
        formatted_movies = [format_movie(movie) for movie in movies]
        return jsonify(formatted_movies), 200