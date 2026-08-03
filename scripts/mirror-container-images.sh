#!/bin/sh
set -eu

registry_prefix=${OCI_REGISTRY_PREFIX:-}
if [ -z "$registry_prefix" ]; then
  echo "OCI_REGISTRY_PREFIX is required (for example: registry.example/sosedi)" >&2
  exit 2
fi

case "$registry_prefix" in
  *://* | */ | *" "* | *@* | *:sha256:*)
    echo "OCI_REGISTRY_PREFIX must be a registry/repository prefix without scheme, digest, spaces or trailing slash" >&2
    exit 2
    ;;
esac

mirror_image() {
  source_image=$1
  repository_and_tag=${source_image%@*}
  digest=${source_image##*@}
  image_name=${repository_and_tag##*/}
  target_tag=$registry_prefix/$image_name

  source_digest=$(docker buildx imagetools inspect "$source_image" \
    --format '{{json .Manifest.Digest}}' | tr -d '"')
  if [ "$source_digest" != "$digest" ]; then
    echo "Source digest mismatch for $source_image" >&2
    exit 1
  fi

  docker buildx imagetools create --tag "$target_tag" "$source_image"
  target_digest=$(docker buildx imagetools inspect "$target_tag" \
    --format '{{json .Manifest.Digest}}' | tr -d '"')
  if [ "$target_digest" != "$digest" ]; then
    echo "Target digest mismatch for $target_tag: expected $digest, got $target_digest" >&2
    exit 1
  fi

  echo "Mirrored $source_image -> $target_tag@$target_digest"
}

mirror_image "postgis/postgis:15-3.5@sha256:54f7933d972e107fda9b696745c21e3fcc643c4263b43f7dc43ba4bdb312fc2c"
mirror_image "redis:7.4.9-bookworm@sha256:a8f08480e1f88f2647fed492d1178c06abb0d0c1fbf02c682a61e2f483fb3954"
mirror_image "glitchtip/glitchtip:6.2.2@sha256:ef28cc4b92c8c9e427b8ddd55682d6aa155129ddf1c5db5f6bbbd09155fd3b6e"
mirror_image "node:22-bookworm-slim@sha256:6c74791e557ce11fc957704f6d4fe134a7bc8d6f5ca4403205b2966bd488f6b3"
