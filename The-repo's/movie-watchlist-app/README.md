# Movie Watchlist Application

A Flask-based movie tracking application with a modern web interface, deployed on Kubernetes using GitOps practices.

## 🎬 Overview

Track movies you've watched and want to watch with this simple, elegant web application. Built with Flask backend, vanilla JavaScript frontend, and MongoDB for data persistence.

## 📁 Project Structure

```
movie-watchlist-app/
├── app/                    # Flask application
│   ├── __init__.py        # App factory
│   ├── database.py        # MongoDB connection
│   ├── models.py          # Data validation
│   └── routes.py          # API endpoints
├── static/                 # Frontend files
│   ├── index.html         # Main UI
│   ├── style.css          # Styling
│   └── app.js             # Frontend logic
├── nginx/                  # Nginx configuration
│   ├── Dockerfile         # Nginx container
│   └── nginx.conf         # Reverse proxy config
├── tests/                  # Test suite
│   └── test_app.py        # Unit tests
├── Dockerfile             # Application container
├── docker-compose.yaml    # Local development
├── Jenkinsfile            # CI/CD pipeline
├── app.py                 # Application entry point
├── config.py              # Configuration
└── requirements.txt       # Python dependencies
```

## 🚀 Quick Start

### Local Development with Docker Compose

```bash
# Clone the repository
git clone https://github.com/jawna10/movie-watchlist-app.git
cd movie-watchlist-app

# Start the application
docker compose up

# Access the application
open http://localhost:8083
```

### Local Development without Docker

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Set environment variables
export MONGO_URI="mongodb://localhost:27017/"
export DB_NAME="movie_watchlist"
export PORT=5000

# Run MongoDB (separate terminal)
docker run -d -p 27017:27017 mongo:7.0

# Run the application
python app.py

# Access at http://localhost:5000
```

## 🧪 Running Tests

```bash
# Activate virtual environment
source venv/bin/activate

# Run unit tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=html

# Run integration tests (requires docker-compose)
docker compose up -d
bash tests/E2E.sh
docker compose down
```

## 🏗️ Architecture

### Backend (Flask)

**API Endpoints:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/app-metrics` | Application statistics |
| GET | `/metrics` | Prometheus metrics |
| POST | `/movie/<id>` | Create movie |
| GET | `/movie/<id>` | Get movie by ID |
| PUT | `/movie/<id>` | Update movie |
| DELETE | `/movie/<id>` | Delete movie |
| GET | `/movie` | Get all movie IDs |
| GET | `/movies` | Get all movies with details |

**Data Model:**

```python
{
    "id": "string",           # Unique movie identifier
    "title": "string",        # Movie title (required)
    "genre": "string",        # Genre (optional)
    "year": int,              # Release year (1800-2100)
    "rating": float,          # Rating (0-10)
    "watched": bool,          # Watched status
    "notes": "string",        # Personal notes
    "created_at": "ISO8601",  # Creation timestamp
    "updated_at": "ISO8601"   # Last update timestamp
}
```

### Frontend (Vanilla JS)

**Features:**
- Add/edit/delete movies
- Filter by watched/unwatched
- Real-time statistics
- Responsive design
- Form validation
- Notifications

### Database (MongoDB)

**Collections:**
- `movies` - Movie documents with metadata

**Indexes:**
- `id` - Unique index for fast lookups

## 🐳 Docker

### Multi-Stage Dockerfile

**Stage 1 - Builder:**
- Installs Python dependencies in virtual environment
- Optimized for caching

**Stage 2 - Runtime:**
- Minimal production image
- Non-root user for security
- Health checks included

**Build:**
```bash
docker build -t movie-watchlist:latest .
```

**Run:**
```bash
docker run -d \
  -p 5000:5000 \
  -e MONGO_URI="mongodb://host.docker.internal:27017/" \
  -e DB_NAME="movie_watchlist" \
  movie-watchlist:latest
```

## 🔄 CI/CD Pipeline

### Jenkins Pipeline Stages

1. **Checkout** - Clone repository and get commit info
2. **Build** - Compile Python bytecode
3. **Test** - Run pytest unit tests
4. **Docker Build** - Build with layer caching
5. **Integration Tests** - Full stack testing with docker-compose
6. **Push to ECR** - Push image to AWS registry (main branch only)
7. **Update GitOps** - Update image tag in GitOps repository

### Triggering Builds

**Automatic:**
- Push to `main` branch triggers full pipeline
- Feature branches run tests only

**Manual:**
- Trigger via Jenkins UI
- Use git tags for release versions

### Environment Variables (Jenkins)

```bash
ECR_REPO_URL=435073375959.dkr.ecr.ap-south-1.amazonaws.com/movie-watchlist
APP_TEST_URL=http://your-test-url:8083
GITOPS_REPO=jawna10/movie-watchlist-gitops
SLACK_CHANNEL=#jenkins
```

## 📊 Monitoring

### Prometheus Metrics

**Exported metrics:**
```
# HTTP request counter
flask_http_request_total{method, status, endpoint}

# Request duration histogram  
flask_http_request_duration_seconds{method, endpoint}

# Application metrics
app_movies_total
app_movies_watched
app_movies_unwatched
```

**Metrics endpoint:** `http://localhost:5000/metrics`

### Application Metrics

**Statistics endpoint:** `http://localhost:5000/app-metrics`

```json
{
  "total_movies": 42,
  "watched": 30,
  "unwatched": 12,
  "timestamp": "2025-10-14T12:00:00Z"
}
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MONGO_URI` | `mongodb://localhost:27017/` | MongoDB connection string |
| `DB_NAME` | `movie_watchlist` | Database name |
| `PORT` | `5000` | Application port |
| `FLASK_ENV` | `production` | Flask environment |

### Configuration File

**config.py:**
```python
class Config:
    MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
    DB_NAME = os.getenv('DB_NAME', 'movie_watchlist')
    PORT = int(os.getenv('PORT', 5000))
    DEBUG = os.getenv('FLASK_ENV', 'development') == 'development'
```

## 🚢 Deployment

### Kubernetes Deployment

This application is deployed via GitOps using ArgoCD. The Helm chart is maintained in the GitOps repository.

**Deployment repository:** `movie-watchlist-gitops`

**Container registry:** AWS ECR
```
435073375959.dkr.ecr.ap-south-1.amazonaws.com/movie-watchlist:TAG
```

### Manual Deployment

```bash
# Build and tag
docker build -t movie-watchlist:v1.0.0 .

# Tag for ECR
docker tag movie-watchlist:v1.0.0 \
  435073375959.dkr.ecr.ap-south-1.amazonaws.com/movie-watchlist:v1.0.0

# Login to ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  435073375959.dkr.ecr.ap-south-1.amazonaws.com

# Push
docker push 435073375959.dkr.ecr.ap-south-1.amazonaws.com/movie-watchlist:v1.0.0
```

## 🛡️ Security

**Container Security:**
- Non-root user (UID 1000)
- Read-only root filesystem where possible
- Minimal base image (python:3.12-slim)
- No unnecessary packages

**Application Security:**
- Input validation on all endpoints
- CORS enabled for frontend
- Environment-based secrets
- MongoDB connection with authentication

**Network Security:**
- Nginx reverse proxy
- Rate limiting (Nginx)
- Health check endpoints for K8s

## 🐛 Troubleshooting

### Application Won't Start

```bash
# Check logs
docker logs movie-watchlist-app

# Common issues:
# 1. MongoDB not accessible
docker run --rm mongo:7.0 mongosh --host YOUR_MONGO_HOST --eval "db.adminCommand('ping')"

# 2. Port already in use
lsof -i :5000
```

### Tests Failing

```bash
# Ensure MongoDB is running
docker ps | grep mongo

# Clean test database
docker compose down -v
docker compose up -d

# Run tests with verbose output
pytest tests/ -vv
```

### Database Issues

```bash
# Connect to MongoDB
docker exec -it movie-watchlist-db mongosh

# Check database
use movie_watchlist
db.movies.find()

# Check indexes
db.movies.getIndexes()
```

## 📚 API Examples

### Create a Movie

```bash
curl -X POST http://localhost:5000/movie/inception \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Inception",
    "genre": "Sci-Fi",
    "year": 2010,
    "rating": 8.8,
    "watched": true,
    "notes": "Mind-bending thriller"
  }'
```

### Get All Movies

```bash
curl http://localhost:5000/movies
```

### Update a Movie

```bash
curl -X PUT http://localhost:5000/movie/inception \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Inception",
    "genre": "Sci-Fi",
    "year": 2010,
    "rating": 9.0,
    "watched": true,
    "notes": "Amazing movie!"
  }'
```

### Delete a Movie

```bash
curl -X DELETE http://localhost:5000/movie/inception
```

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/amazing-feature`
2. Make changes and add tests
3. Run tests: `pytest tests/`
4. Commit: `git commit -m "Add amazing feature"`
5. Push: `git push origin feature/amazing-feature`
6. Create Pull Request

## 📝 License

This project is part of a portfolio demonstration.

## 👤 Author

**Jawna Khatib**
- Email: jawnakhatib@gmail.com
- GitHub: [@jawna10](https://github.com/jawna10)

## 🔗 Related Repositories

- **Infrastructure:** [movie-watchlist-infrastructure](https://github.com/jawna10/movie-watchlist-infrastructure)
- **GitOps:** [movie-watchlist-gitops](https://github.com/jawna10/movie-watchlist-gitops)
