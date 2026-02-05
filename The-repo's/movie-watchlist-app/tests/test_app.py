
import unittest
import json
from app import create_app
from app.database import get_db
from unittest.mock import patch, MagicMock

class MovieWatchlistTestCase(unittest.TestCase):
    
    @classmethod
    def setUpClass(cls):
        """Set up test app once for all tests"""
        cls.app = create_app()
        cls.app.config['TESTING'] = True
        cls.client = cls.app.test_client()
    
    def setUp(self):
        """Set up before each test"""
        # Mock database for tests
        self.mock_db = MagicMock()
        self.patcher = patch('app.routes.get_db', return_value=self.mock_db)
        self.patcher.start()
    
    def tearDown(self):
        """Clean up after each test"""
        self.patcher.stop()
    
    # === Health & Metrics Tests ===
    
    def test_health_endpoint(self):
        """Test /health endpoint returns healthy status"""
        response = self.client.get('/health')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(data['status'], 'healthy')
        self.assertIn('timestamp', data)
    
    def test_metrics_endpoint(self):
        """Test /app-metrics endpoint returns movie statistics"""
        # Mock database responses
        self.mock_db.movies.count_documents.side_effect = [10, 6]  # total, watched
        
        response = self.client.get('/app-metrics')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(data['total_movies'], 10)
        self.assertEqual(data['watched'], 6)
        self.assertEqual(data['unwatched'], 4)
        self.assertIn('timestamp', data)
    
    # === Create Movie Tests ===
    
    def test_create_movie_success(self):
        """Test creating a new movie successfully"""
        self.mock_db.movies.find_one.return_value = None  # No existing movie
        self.mock_db.movies.insert_one.return_value.inserted_id = 'mock_id_123'
        
        movie_data = {
            'title': 'Inception',
            'genre': 'Sci-Fi',
            'year': 2010,
            'rating': 8.8,
            'watched': True,
            'notes': 'Amazing movie'
        }
        
        response = self.client.post('/movie/movie-1',
                                   data=json.dumps(movie_data),
                                   content_type='application/json')
        
        self.assertEqual(response.status_code, 201)
        data = json.loads(response.data)
        self.assertEqual(data['title'], 'Inception')
        self.assertEqual(data['id'], 'movie-1')
    
    def test_create_movie_duplicate_id(self):
        """Test creating movie with existing ID fails"""
        self.mock_db.movies.find_one.return_value = {'id': 'movie-1', 'title': 'Existing'}
        
        movie_data = {
            'title': 'New Movie',
            'genre': 'Action',
            'year': 2024
        }
        
        response = self.client.post('/movie/movie-1',
                                   data=json.dumps(movie_data),
                                   content_type='application/json')
        
        self.assertEqual(response.status_code, 409)
        data = json.loads(response.data)
        self.assertIn('error', data)
    
    def test_create_movie_no_data(self):
        """Test creating movie without data fails"""
        response = self.client.post('/movie/movie-1',
                                   data='',
                                   content_type='application/json')
        
        self.assertEqual(response.status_code, 400)
    
    def test_create_movie_missing_title(self):
        """Test creating movie without title fails validation"""
        movie_data = {
            'genre': 'Action',
            'year': 2024
        }
        
        response = self.client.post('/movie/movie-1',
                                   data=json.dumps(movie_data),
                                   content_type='application/json')
        
        self.assertEqual(response.status_code, 400)
        data = json.loads(response.data)
        self.assertIn('errors', data)
    
    # === Get Movie Tests ===
    
    def test_get_movie_success(self):
        """Test getting a specific movie by ID"""
        mock_movie = {
            '_id': 'mock_id',
            'id': 'movie-1',
            'title': 'Inception',
            'genre': 'Sci-Fi',
            'year': 2010,
            'rating': 8.8,
            'watched': True
        }
        self.mock_db.movies.find_one.return_value = mock_movie
        
        response = self.client.get('/movie/movie-1')
        
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['title'], 'Inception')
    
    def test_get_movie_not_found(self):
        """Test getting non-existent movie returns 404"""
        self.mock_db.movies.find_one.return_value = None
        
        response = self.client.get('/movie/nonexistent')
        
        self.assertEqual(response.status_code, 404)
    
    def test_get_all_movie_ids(self):
        """Test getting list of all movie IDs"""
        mock_movies = [
            {'id': 'movie-1'},
            {'id': 'movie-2'},
            {'id': 'movie-3'}
        ]
        self.mock_db.movies.find.return_value = mock_movies
        
        response = self.client.get('/movie')
        
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(len(data), 3)
        self.assertIn('movie-1', data)
    
    # === Update Movie Tests ===
    
    def test_update_movie_success(self):
        """Test updating an existing movie"""
        mock_result = MagicMock()
        mock_result.matched_count = 1
        self.mock_db.movies.update_one.return_value = mock_result
        
        updated_movie = {
            '_id': 'mock_id',
            'id': 'movie-1',
            'title': 'Inception Updated',
            'genre': 'Sci-Fi',
            'year': 2010,
            'rating': 9.0,
            'watched': True
        }
        self.mock_db.movies.find_one.return_value = updated_movie
        
        update_data = {
            'title': 'Inception Updated',
            'genre': 'Sci-Fi',
            'year': 2010,
            'rating': 9.0,
            'watched': True
        }
        
        response = self.client.put('/movie/movie-1',
                                  data=json.dumps(update_data),
                                  content_type='application/json')
        
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['title'], 'Inception Updated')
    
    def test_update_movie_not_found(self):
        """Test updating non-existent movie returns 404"""
        mock_result = MagicMock()
        mock_result.matched_count = 0
        self.mock_db.movies.update_one.return_value = mock_result
        
        update_data = {
            'title': 'Some Movie',
            'genre': 'Action'
        }
        
        response = self.client.put('/movie/nonexistent',
                                  data=json.dumps(update_data),
                                  content_type='application/json')
        
        self.assertEqual(response.status_code, 404)
    
    # === Delete Movie Tests ===
    
    def test_delete_movie_success(self):
        """Test deleting a movie successfully"""
        mock_result = MagicMock()
        mock_result.deleted_count = 1
        self.mock_db.movies.delete_one.return_value = mock_result
        
        response = self.client.delete('/movie/movie-1')
        
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn('message', data)
    
    def test_delete_movie_not_found(self):
        """Test deleting non-existent movie returns 404"""
        mock_result = MagicMock()
        mock_result.deleted_count = 0
        self.mock_db.movies.delete_one.return_value = mock_result
        
        response = self.client.delete('/movie/nonexistent')
        
        self.assertEqual(response.status_code, 404)
    
    # === Validation Tests ===
    
    def test_invalid_year(self):
        """Test movie with invalid year fails validation"""
        movie_data = {
            'title': 'Test Movie',
            'year': 2200  # Invalid year
        }
        
        response = self.client.post('/movie/test-1',
                                   data=json.dumps(movie_data),
                                   content_type='application/json')
        
        self.assertEqual(response.status_code, 400)
    
    def test_invalid_rating(self):
        """Test movie with invalid rating fails validation"""
        movie_data = {
            'title': 'Test Movie',
            'rating': 15  # Invalid rating (must be 0-10)
        }
        
        response = self.client.post('/movie/test-1',
                                   data=json.dumps(movie_data),
                                   content_type='application/json')
        
        self.assertEqual(response.status_code, 400)


if __name__ == '__main__':
    unittest.main()