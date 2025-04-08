FROM wordpress:latest

# Set working directory
WORKDIR /var/www/html

# Copy all project files EXCEPT wp-content
COPY . /var/www/html/

# Don't overwrite wp-content — only sync custom files (if any)
COPY wp-content/ /var/www/html/wp-content/

# Fix permissions (optional and depends on your needs)
RUN chown -R www-data:www-data /var/www/html

# Expose default port
EXPOSE 80


