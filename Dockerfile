FROM alpine:3.20

RUN apk add --no-cache nginx nmap bind-tools jq bash curl tzdata

WORKDIR /var/www
RUN mkdir -p /var/www/site /run/nginx

COPY nginx.conf /etc/nginx/http.d/default.conf
COPY scan.sh /app/scan.sh
COPY run.sh /app/run.sh
COPY ports.map /app/ports.map
RUN chmod +x /app/scan.sh /app/run.sh

COPY site/ /var/www/site/

ENV SUBNETS=""
ENV PORTS="80,443,8006,8080,8443,32400,9090,9093,9000,3000,3001,32168,8123,5601,9200"
ENV DNS_SERVER=""
ENV SEARCH_DOMAINS=""
ENV HOSTNAMES=""
ENV INTERVAL="600"
ENV USE_TLS_MAP="true"

EXPOSE 8080
ENTRYPOINT ["/app/run.sh"]
