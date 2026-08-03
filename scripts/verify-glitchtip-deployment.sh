#!/bin/sh
set -eu

registry_prefix=${OCI_REGISTRY_PREFIX:-}
image=${GLITCHTIP_IMAGE:-}
env_file=${GLITCHTIP_ENV_FILE:-}
expected_digest=sha256:ef28cc4b92c8c9e427b8ddd55682d6aa155129ddf1c5db5f6bbbd09155fd3b6e

fail() {
  echo "$1" >&2
  exit 2
}

[ -n "$registry_prefix" ] || fail "OCI_REGISTRY_PREFIX is required"
[ -n "$env_file" ] || fail "GLITCHTIP_ENV_FILE is required"
[ -f "$env_file" ] || fail "GLITCHTIP_ENV_FILE does not exist"

expected_image="$registry_prefix/glitchtip:6.2.2@$expected_digest"
[ "$image" = "$expected_image" ] ||
  fail "GLITCHTIP_IMAGE must be $expected_image"

for name in DATABASE_URL VALKEY_URL SECRET_KEY EMAIL_URL DEFAULT_FROM_EMAIL GLITCHTIP_DOMAIN ALLOWED_HOSTS CSRF_TRUSTED_ORIGINS; do
  grep -Eq "^${name}=\"?[^\"[:space:]][^\"]*\"?$" "$env_file" ||
    fail "$name must be non-empty in GLITCHTIP_ENV_FILE"
done

if grep -Eqi 'change_me|replace_me|app\\.glitchtip\\.com|sentry\\.io' "$env_file"; then
  fail "GLITCHTIP_ENV_FILE contains a placeholder or hosted observability endpoint"
fi

grep -Eq '^GLITCHTIP_DOMAIN="?https://' "$env_file" ||
  fail "GLITCHTIP_DOMAIN must use HTTPS"

echo "GlitchTip deployment contract is pinned and self-hosted"
