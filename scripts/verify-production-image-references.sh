#!/bin/sh
set -eu

registry_prefix=${OCI_REGISTRY_PREFIX:-}
current_image=${BACKEND_IMAGE:-}
previous_image=${PREVIOUS_BACKEND_IMAGE:-}

if [ -z "$registry_prefix" ]; then
  echo "OCI_REGISTRY_PREFIX is required" >&2
  exit 2
fi

case "$registry_prefix" in
  *://* | */ | *" "* | *@* | *:sha256:*)
    echo "OCI_REGISTRY_PREFIX must be a registry/repository prefix" >&2
    exit 2
    ;;
esac

validate_image() {
  name=$1
  value=$2

  case "$value" in
    "$registry_prefix"/*@sha256:*) ;;
    *)
      echo "$name must use OCI_REGISTRY_PREFIX and an exact sha256 digest" >&2
      exit 2
      ;;
  esac

  image_name=${value%@sha256:*}
  digest=${value##*@sha256:}

  if [ "$image_name@sha256:$digest" != "$value" ] ||
    [ "$image_name" = "$registry_prefix/" ] ||
    ! printf '%s\n' "$image_name" | grep -Eq '^[^[:space:]@]+$' ||
    ! printf '%s\n' "$digest" | grep -Eq '^[0-9a-f]{64}$'; then
    echo "$name must use OCI_REGISTRY_PREFIX and an exact sha256 digest" >&2
    exit 2
  fi
}

validate_image BACKEND_IMAGE "$current_image"
validate_image PREVIOUS_BACKEND_IMAGE "$previous_image"

if [ "$current_image" = "$previous_image" ]; then
  echo "BACKEND_IMAGE and PREVIOUS_BACKEND_IMAGE must differ" >&2
  exit 2
fi

echo "Production backend image references are immutable and rollback-ready"
