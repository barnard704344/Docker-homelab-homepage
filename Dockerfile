# ---- base image with nginx + nmap ----
FROM alpine:3.20

# Install nginx, nmap, bash, curl (useful for debugging)
RUN apk add --no-cache nginx nmap bash curl

# Create web root and app dir
RUN mkdir -p /var/www/site /app /run/nginx

# Copy website
# Assumes your repo has site/index.html etc.
COPY site/ /var/www/site/

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy scripts into image
COPY scan.sh /app/scan.sh
COPY start.sh /app/start.sh

# Make scripts executable
RUN chmod +x /app/scan.sh /app/start.sh

# Expose HTTP (informational; not used when --network host)
EXPOSE 80

# Healthcheck: try to hit localhost
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -fsS http://127.0.0.1/ || exit 1

# Start script will optionally run scans and then start nginx in foreground
CMD ["/app/start.sh"]
