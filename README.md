# SandboxService

## Run local
dotnet run --project src/SandboxService

## Docker
docker build -t sandboxservice:local .
docker run --rm -p 8080:8080 -e APP_VERSION="docker-1" sandboxservice:local

## Endpoints
- GET /health
- GET /version