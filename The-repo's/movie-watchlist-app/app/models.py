from datetime import datetime

def validate_movie(data):
    """Simple validation for movie data"""
    errors = []
    
    if not data.get('title'):
        errors.append('Title is required')
    
    if 'year' in data:
        try:
            year = int(data['year'])
            if year < 1800 or year > 2100:
                errors.append('Year must be between 1800 and 2100')
        except (ValueError, TypeError):
            errors.append('Year must be a number')
    
    if 'rating' in data and data['rating'] is not None:
        try:
            rating = float(data['rating'])
            if rating < 0 or rating > 10:
                errors.append('Rating must be between 0 and 10')
        except (ValueError, TypeError):
            errors.append('Rating must be a number')
    
    return errors

def format_movie(movie):
    """Format movie document for JSON response"""
    if movie:
        movie['_id'] = str(movie['_id'])
    return movie