#!/bin/sh
set -eu

image=${BACKEND_IMAGE:-}
env_file=${BACKEND_ENV_FILE:-}
network=${BACKEND_SMOKE_NETWORK:-}
database_url=${BACKEND_SMOKE_DATABASE_URL:-}
redis_url=${BACKEND_SMOKE_REDIS_URL:-}
cors_allowed_origins=${BACKEND_SMOKE_CORS_ALLOWED_ORIGINS:-}
metrics_token=${BACKEND_SMOKE_METRICS_TOKEN:-}
require_metrics=${BACKEND_SMOKE_REQUIRE_METRICS:-true}
container_name="sosedi-backend-smoke-$$"

case "$image" in
  sha256:???????????????????????????????????????????????????????????????? | *@sha256:????????????????????????????????????????????????????????????????)
    ;;
  *)
    echo "BACKEND_IMAGE must be an exact local image ID or registry digest" >&2
    exit 2
    ;;
esac

for required_value in "$env_file" "$network" "$database_url" "$redis_url" "$cors_allowed_origins" "$metrics_token"; do
  if [ -z "$required_value" ]; then
    echo "BACKEND_ENV_FILE, BACKEND_SMOKE_NETWORK, DATABASE, REDIS, CORS and METRICS values are required" >&2
    exit 2
  fi
done

case "$require_metrics" in
  true | false) ;;
  *)
    echo "BACKEND_SMOKE_REQUIRE_METRICS must be true or false" >&2
    exit 2
    ;;
esac

cleanup() {
  docker rm --force "$container_name" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

docker image inspect "$image" >/dev/null
docker run --detach \
  --name "$container_name" \
  --network "$network" \
  --env-file "$env_file" \
  --env NODE_ENV=production \
  --env DATABASE_URL="$database_url" \
  --env REDIS_URL="$redis_url" \
  --env CORS_ALLOWED_ORIGINS="$cors_allowed_origins" \
  --env METRICS_TOKEN="$metrics_token" \
  --env TRUSTED_PROXY_IPS=127.0.0.1 \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  "$image" >/dev/null

attempt=0
while [ "$attempt" -lt 40 ]; do
  status=$(docker inspect --format '{{.State.Health.Status}}' "$container_name")
  if [ "$status" = "healthy" ]; then
    break
  fi
  if [ "$status" = "unhealthy" ]; then
    docker logs "$container_name" >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep 1
done

if [ "${status:-}" != "healthy" ]; then
  docker logs "$container_name" >&2
  echo "Backend image did not become healthy" >&2
  exit 1
fi

docker exec "$container_name" node -e "
Promise.all([
  fetch('http://127.0.0.1:3000/api/v1/health/ready', {headers: {'x-forwarded-proto': 'https'}}).then(r => r.json()),
  fetch('http://127.0.0.1:3000/api/v1/categories', {headers: {'x-forwarded-proto': 'https'}}).then(r => r.json()),
  fetch('http://127.0.0.1:3000/api/v1/items?limit=1', {headers: {'x-forwarded-proto': 'https'}}).then(r => r.json()),
]).then(([health, categories, items]) => {
  const ready = health?.data;
  if (ready?.status !== 'ready') throw new Error('readiness smoke failed');
  if (!categories?.success || !Array.isArray(categories.data)) {
    throw new Error('categories smoke failed');
  }
  if (!items?.success || !Array.isArray(items.data)) {
    throw new Error('items smoke failed');
  }
  const privateKeys = ['address', 'latitude', 'longitude', 'ownerId'];
  if (items.data.some(item => privateKeys.some(key => key in item))) {
    throw new Error('public catalog leaked a private field');
  }
}).catch(error => {
  console.error(error.message);
  process.exit(1);
});
"

if [ "$require_metrics" = "true" ]; then
  docker exec "$container_name" node -e "
  fetch('http://127.0.0.1:3000/api/v1/internal/metrics', {
    headers: {
      authorization: 'Bearer ' + process.env.METRICS_TOKEN,
      'x-forwarded-proto': 'https',
    },
  }).then(async (response) => {
    const body = await response.text();
    if (!response.ok || !body.includes('sosedi_database_connections')) {
      process.exit(1);
    }
  }).catch(() => process.exit(1));
  "
fi

image_id=$(docker image inspect --format '{{.Id}}' "$image")
release=$(docker image inspect \
  --format '{{index .Config.Labels "org.opencontainers.image.version"}}' "$image")
echo "Backend image smoke passed: $image_id release=$release"
