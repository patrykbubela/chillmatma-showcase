#!/bin/sh

set -e

git pull

mkdir -p import export
sudo chown -R 10001:10001 import export

sudo docker compose --profile prod pull

sudo docker compose --profile prod up -d --build

sudo docker image prune -f

echo "Deployed successfully"
