#!/bin/bash

#must be run from the project root directory
if [ -f ".env" ]; then
  echo "🌎 .env exists. Leaving alone"
else
  echo "🌎 .env does not exist. Copying .env-example to .env"
  cp env.example .env
fi

echo "🚢 Build docker images"
docker compose build

echo "📦 Installing Gems"
docker compose run --rm app bundle
