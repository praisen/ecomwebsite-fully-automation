FROM wordpress:latest
COPY . /var/www/html/
# Expose the port your container app
EXPOSE 3000    


