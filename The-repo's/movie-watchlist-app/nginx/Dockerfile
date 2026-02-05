FROM nginx:1.21-alpine
COPY nginx/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /usr/share/nginx/html/static
COPY static/index.html /usr/share/nginx/html/index.html
COPY static/style.css /usr/share/nginx/html/static/style.css
COPY static/app.js /usr/share/nginx/html/static/app.js
EXPOSE 80