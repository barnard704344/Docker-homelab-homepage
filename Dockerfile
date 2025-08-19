# ---- base image with nginx + nmap + php ----
FROM alpine:3.20

# Install nginx, nmap, bash, curl, php-fpm, jq
RUN apk add --no-cache nginx nmap bash curl php82-fpm php82-json php82-session jq

# Create web root and app dir
RUN mkdir -p /var/www/site /app /run/nginx /run/php

# Copy website
# Assumes your repo has site/index.html etc.
COPY site/ /var/www/site/

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy scripts into image
COPY scan.sh /usr/local/bin/scan.sh
COPY parse-scan.sh /usr/local/bin/parse-scan.sh
COPY start.sh /usr/local/bin/start.sh
COPY run-scan.php /var/www/site/run-scan.php
COPY debug.php /var/www/site/debug.php

# Make scripts executable and create symlinks for easier access
RUN chmod +x /usr/local/bin/scan.sh /usr/local/bin/parse-scan.sh /usr/local/bin/start.sh && \
    ln -sf /usr/local/bin/scan.sh /opt/scan.sh && \
    chmod +x /var/www/site/run-scan.php /var/www/site/debug.php || true

# Configure PHP-FPM
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's/;listen.owner = nobody/listen.owner = nginx/' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's/;listen.group = nobody/listen.group = nginx/' /etc/php82/php-fpm.d/www.conf

# Expose HTTP (informational; not used when --network host)
EXPOSE 80

# Healthcheck: try to hit localhost
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -fsS http://127.0.0.1/ || exit 1

# Start script will optionally run scans and then start nginx in foreground
CMD ["/usr/local/bin/start.sh"]
