$ErrorActionPreference = "Stop"
Write-Host "Stopping SaaSify infra..."
docker compose --env-file docker/.env -f docker/docker-compose.yml down
Write-Host "Stopped."
