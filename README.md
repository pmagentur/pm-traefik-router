### Traefik Setup with Azure DNS Challenge

#### Overview
This setup uses Traefik as a reverse proxy and load balancer. It handles automated TLS certificate generation using Let's Encrypt via an Azure DNS challenge. The Traefik dashboard is exposed over HTTPS, and you can use Traefik to route other services behind HTTPS with automated certificate management.

#### Prerequisites
- Docker and Docker Compose installed.
- DNS records for `*.site.pm-projects.de` already configured.
- Azure DNS credentials set up for Let's Encrypt's DNS challenge.

#### Traefik Docker Compose Setup

This Docker Compose file sets up Traefik as the main reverse proxy, with the dashboard accessible at `https://traefik.site.pm-projects.de`. It uses Azure DNS challenge to automatically manage TLS certificates.

### Docker Compose

```yaml
services:
  traefik:
    image: pmdocker.azurecr.io/pm-traefik-router
    container_name: traefik
    restart: always
    command:
      - "--api.insecure=true"
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.azureresolver.acme.dnschallenge=true"
      - "--certificatesresolvers.azureresolver.acme.dnschallenge.provider=azure"
      - "--certificatesresolvers.azureresolver.acme.email=everything@pmagentur.com"
      - "--certificatesresolvers.azureresolver.acme.storage=/acme/acme.json"
      - "--certificatesresolvers.azureresolver.acme.caServer=https://acme-v02.api.letsencrypt.org/directory"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-ui.rule=Host(`traefik.site.pm-projects.de`)"  # Traefik web UI
      - "traefik.http.services.traefik-ui.loadbalancer.server.port=8080"
      - "traefik.http.routers.traefik-ui.entrypoints=websecure"
      - "traefik.http.routers.traefik-ui.tls.certresolver=azureresolver"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "traefik-acme:/acme"
    networks:
      - traefik-network 

volumes:
  traefik-acme:
    driver: local

networks:
  traefik-network:
    external: true
```

### Volumes
- **`/var/run/docker.sock:/var/run/docker.sock:ro`**: This allows Traefik to communicate with Docker and automatically discover new containers.
- **`traefik-acme`**: Stores ACME certificate data, allowing certificates to persist between container restarts.

### Networks
- **`traefik-network`**: An external Docker network that allows Traefik to route requests to containers attached to this network.

### TLS Certificate Management
Traefik uses Let's Encrypt with an Azure DNS challenge to automatically generate and renew SSL certificates for services, without needing to open ports for Let's Encrypt's HTTP-01 challenge. Make sure your Azure credentials are correctly configured for the DNS challenge.

### Accessing the Traefik Dashboard
You can access the Traefik dashboard at `https://traefik.site.pm-projects.de`. Be sure to secure it for production by removing `--api.insecure=true` or implementing authentication.

---

### Example: Exposing an NGINX Service via Traefik with HTTPS

Below is an example `docker-compose.yml` for an NGINX service that will be routed through Traefik and exposed at `https://demo.site.pm-projects.de` with automatic TLS using Let's Encrypt.

```yaml
version: "3.8"

services:
  nginx:
    image: nginx:latest
    container_name: nginx-demo
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nginx-demo.rule=Host(`demo.site.pm-projects.de`)"
      - "traefik.http.routers.nginx-demo.entrypoints=websecure"
      - "traefik.http.routers.nginx-demo.tls.certresolver=azureresolver"
    expose:
      - "80"  # NGINX exposes port 80 for HTTP traffic
    networks:
      - traefik-network  # Attach to the external traefik network

networks:
  traefik-network:
    external: true
```

### How This Works:
- **NGINX**: The NGINX container will be available at `https://demo.site.pm-projects.de`.
- **Routing**: Traefik automatically routes traffic for `demo.site.pm-projects.de` via HTTPS and applies an SSL certificate using Let's Encrypt.
- **TLS**: The certificate is automatically generated and managed by Traefik with the Azure DNS challenge.

---

### How to Deploy
1. **Check/Create External Network**:
   Ensure the `traefik-network` exists before running any Docker Compose files.
   ```bash
   docker network inspect traefik-network >/dev/null 2>&1 || docker network create traefik-network
   ```

2. **Start Traefik**:
   Run the Traefik setup first:
   ```bash
   docker-compose up -d
   ```

3. **Start NGINX Service**:
   Deploy the NGINX service (from its separate `docker-compose.yml` file):
   ```bash
   docker-compose -f nginx-compose.yml up -d
   ```

4. **Access NGINX**:
   Open `https://demo.site.pm-projects.de` in your browser, and the service should be accessible with a valid SSL certificate.

---

### Troubleshooting
- **Bad Gateway**: If you see a "Bad Gateway" error, make sure the container is running and correctly attached to the `traefik-network`.
- **ACME Issues**: Check the logs for certificate generation issues using:
  ```bash
  docker logs traefik
  ```