#!/bin/bash

# Check if the network exists
if ! docker network inspect traefik-network >/dev/null 2>&1; then
  echo "Network traefik-network does not exist. Creating it..."
  docker network create traefik-network
else
  echo "Network traefik-network already exists."
fi

# Start the Docker Compose stack
docker-compose up -d
