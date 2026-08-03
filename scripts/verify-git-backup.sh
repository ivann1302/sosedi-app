#!/bin/sh
set -eu

backup_remote=${GIT_BACKUP_REMOTE:-backup}
backup_branch=${GIT_BACKUP_BRANCH:-main}

fail() {
  echo "$1" >&2
  exit 1
}

remote_host() {
  printf '%s\n' "$1" |
    sed -E 's#^[a-zA-Z][a-zA-Z0-9+.-]*://([^/@]+@)?([^/:]+).*#\2#; s#^([^@]+@)?([^:]+):.*#\2#'
}

require_network_remote() {
  name=$1
  url=$2
  case "$url" in
    file://* | /* | ./* | ../*)
      fail "Git $name remote must use an independent network host"
      ;;
    http://*@* | https://*@*)
      fail "Git $name remote URL must not contain embedded credentials"
      ;;
    *://* | *:*) ;;
    *) fail "Git $name remote must use an independent network host" ;;
  esac
}

verify_remote_ref() {
  kind=$1
  local_oid=$2
  ref=$3
  remote_oid=$(
    printf '%s\n' "$remote_refs" |
      awk -v wanted="$ref" '$2 == wanted { print $1; exit }'
  )
  if [ -z "$remote_oid" ] || [ "$remote_oid" != "$local_oid" ]; then
    fail "Backup remote is missing current $kind $ref"
  fi
}

if [ "${GIT_BACKUP_FUNCTIONS_ONLY:-false}" = "true" ]; then
  return 0 2>/dev/null || exit 0
fi

origin_url=$(git remote get-url origin 2>/dev/null) ||
  fail "Git origin remote is missing"
backup_url=$(git remote get-url "$backup_remote" 2>/dev/null) ||
  fail "Git backup remote '$backup_remote' is missing"
require_network_remote origin "$origin_url"
require_network_remote backup "$backup_url"

origin_host=$(remote_host "$origin_url")
backup_host=$(remote_host "$backup_url")
if [ -z "$origin_host" ] || [ -z "$backup_host" ] ||
  [ "$origin_host" = "$backup_host" ]; then
  fail "Backup remote must use a different host than origin"
fi

git diff --quiet || fail "Tracked worktree changes are not backed up"
git diff --cached --quiet || fail "Staged changes are not backed up"
if [ -n "$(git ls-files --others --exclude-standard)" ]; then
  fail "Untracked files are not backed up"
fi

git fetch "$backup_remote"
local_head=$(git rev-parse HEAD)
backup_head=$(git rev-parse "refs/remotes/$backup_remote/$backup_branch")
git merge-base --is-ancestor "$local_head" "$backup_head" ||
  fail "Backup branch does not contain local HEAD $local_head"

remote_refs=$(git ls-remote --heads --tags "$backup_remote")
git for-each-ref --format='%(objectname) %(refname)' refs/heads |
  while IFS=' ' read -r local_oid ref; do
    verify_remote_ref branch "$local_oid" "$ref"
  done
git for-each-ref --format='%(objectname) %(refname)' refs/tags |
  while IFS=' ' read -r local_oid ref; do
    verify_remote_ref tag "$local_oid" "$ref"
  done

echo "Backup verified: all local branches/tags and $backup_remote/$backup_branch contain $local_head on $backup_host"
