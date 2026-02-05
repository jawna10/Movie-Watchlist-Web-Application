const API_URL = '';

// Load movies on page load
document.addEventListener('DOMContentLoaded', () => {
    loadMovies();
    loadMetrics();
});

// Form submission
document.getElementById('movieForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    await addMovie();
});

// Filter buttons
document.querySelectorAll('.filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        filterMovies(btn.dataset.filter);
    });
});

// Add movie
async function addMovie() {
    const movieId = document.getElementById('movieId').value.trim();
    const title = document.getElementById('title').value.trim();
    const genre = document.getElementById('genre').value.trim();
    const year = document.getElementById('year').value;
    const rating = document.getElementById('rating').value;
    const watched = document.getElementById('watched').checked;
    const notes = document.getElementById('notes').value.trim();

    const movieData = {
        title,
        genre,
        year: year ? parseInt(year) : null,
        rating: rating ? parseFloat(rating) : null,
        watched,
        notes
    };

    try {
        const response = await fetch(`${API_URL}/movie/${movieId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(movieData)
        });

        if (response.ok) {
            showNotification('Movie added successfully!', 'success');
            document.getElementById('movieForm').reset();
            loadMovies();
            loadMetrics();
        } else {
            const error = await response.json();
            showNotification(error.error || 'Failed to add movie', 'error');
        }
    } catch (error) {
        showNotification('Error adding movie', 'error');
    }
}

// Load all movies
async function loadMovies() {
    try {
        const response = await fetch(`${API_URL}/movies`);
        const movies = await response.json();
        
        displayMovies(movies);
    } catch (error) {
        console.error('Error loading movies:', error);
        showNotification('Error loading movies', 'error');
    }
}

// Display movies
function displayMovies(movies) {
    const moviesList = document.getElementById('moviesList');
    const emptyState = document.getElementById('emptyState');
    
    if (movies.length === 0) {
        moviesList.innerHTML = '';
        emptyState.classList.add('show');
        return;
    }
    
    emptyState.classList.remove('show');
    
    moviesList.innerHTML = movies.map(movie => `
        <div class="movie-card ${movie.watched ? 'watched' : 'unwatched'}" data-id="${movie.id}">
            <div class="movie-header">
                <div>
                    <div class="movie-title">${movie.title}</div>
                    <div class="movie-id">${movie.id}</div>
                </div>
                <span class="movie-status ${movie.watched ? 'status-watched' : 'status-unwatched'}">
                    ${movie.watched ? '✓ Watched' : '○ To Watch'}
                </span>
            </div>
            
            <div class="movie-details">
                <div class="movie-info">
                    ${movie.genre ? `<span class="info-item"><strong>Genre:</strong> ${movie.genre}</span>` : ''}
                    ${movie.year ? `<span class="info-item"><strong>Year:</strong> ${movie.year}</span>` : ''}
                    ${movie.rating ? `<span class="info-item"><strong>Rating:</strong> ${movie.rating}/10 ⭐</span>` : ''}
                </div>
                ${movie.notes ? `<div class="movie-notes">"${movie.notes}"</div>` : ''}
            </div>
            
            <div class="movie-actions">
                <button class="btn-edit" onclick="editMovie('${movie.id}')">Edit</button>
                <button class="btn-delete" onclick="deleteMovie('${movie.id}')">Delete</button>
            </div>
        </div>
    `).join('');
}

// Filter movies
function filterMovies(filter) {
    const cards = document.querySelectorAll('.movie-card');
    
    cards.forEach(card => {
        if (filter === 'all') {
            card.style.display = 'block';
        } else if (filter === 'watched') {
            card.style.display = card.classList.contains('watched') ? 'block' : 'none';
        } else if (filter === 'unwatched') {
            card.style.display = card.classList.contains('unwatched') ? 'block' : 'none';
        }
    });
}

// Edit movie
async function editMovie(movieId) {
    try {
        const response = await fetch(`${API_URL}/movie/${movieId}`);
        const movie = await response.json();
        
        document.getElementById('movieId').value = movie.id;
        document.getElementById('title').value = movie.title;
        document.getElementById('genre').value = movie.genre || '';
        document.getElementById('year').value = movie.year || '';
        document.getElementById('rating').value = movie.rating || '';
        document.getElementById('watched').checked = movie.watched;
        document.getElementById('notes').value = movie.notes || '';
        
        // Change form to update mode
        const form = document.getElementById('movieForm');
        form.onsubmit = async (e) => {
            e.preventDefault();
            await updateMovie(movieId);
        };
        
        // Scroll to form
        document.querySelector('.add-movie-section').scrollIntoView({ behavior: 'smooth' });
        
        showNotification('Edit the movie and submit', 'success');
    } catch (error) {
        showNotification('Error loading movie', 'error');
    }
}

// Update movie
async function updateMovie(movieId) {
    const title = document.getElementById('title').value.trim();
    const genre = document.getElementById('genre').value.trim();
    const year = document.getElementById('year').value;
    const rating = document.getElementById('rating').value;
    const watched = document.getElementById('watched').checked;
    const notes = document.getElementById('notes').value.trim();

    const movieData = {
        title,
        genre,
        year: year ? parseInt(year) : null,
        rating: rating ? parseFloat(rating) : null,
        watched,
        notes
    };

    try {
        const response = await fetch(`${API_URL}/movie/${movieId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(movieData)
        });

        if (response.ok) {
            showNotification('Movie updated successfully!', 'success');
            document.getElementById('movieForm').reset();
            
            // Reset form to add mode
            document.getElementById('movieForm').onsubmit = async (e) => {
                e.preventDefault();
                await addMovie();
            };
            
            loadMovies();
            loadMetrics();
        } else {
            const error = await response.json();
            showNotification(error.error || 'Failed to update movie', 'error');
        }
    } catch (error) {
        showNotification('Error updating movie', 'error');
    }
}

// Delete movie
async function deleteMovie(movieId) {
    if (!confirm('Are you sure you want to delete this movie?')) {
        return;
    }

    try {
        const response = await fetch(`${API_URL}/movie/${movieId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            showNotification('Movie deleted successfully!', 'success');
            loadMovies();
            loadMetrics();
        } else {
            showNotification('Failed to delete movie', 'error');
        }
    } catch (error) {
        showNotification('Error deleting movie', 'error');
    }
}

// Load metrics
async function loadMetrics() {
    try {
        const response = await fetch(`${API_URL}/app-metrics`);
        const metrics = await response.json();
        
        document.getElementById('totalMovies').textContent = metrics.total_movies;
        document.getElementById('watchedMovies').textContent = metrics.watched;
        document.getElementById('unwatchedMovies').textContent = metrics.unwatched;
    } catch (error) {
        console.error('Error loading metrics:', error);
    }
}

// Show notification
function showNotification(message, type) {
    const notification = document.getElementById('notification');
    notification.textContent = message;
    notification.className = `notification ${type} show`;
    
    setTimeout(() => {
        notification.classList.remove('show');
    }, 3000);
}