#!/bin/sh
set -eu

GIT_BACKUP_FUNCTIONS_ONLY=true
export GIT_BACKUP_FUNCTIONS_ONLY
. ./scripts/verify-git-backup.sh

expect_failure() {
  if ("$@") >/dev/null 2>&1; then
    echo "Expected command to fail: $*" >&2
    exit 1
  fi
}

require_network_remote origin git@github.com:owner/repository.git
require_network_remote backup ssh://git@backup.example/repository.git
expect_failure require_network_remote backup /srv/repository.git
expect_failure require_network_remote backup file:///srv/repository.git
expect_failure require_network_remote backup https://token@backup.example/repository.git

remote_refs='aaaaaaaa refs/heads/main
bbbbbbbb refs/tags/v1.0.0'
verify_remote_ref branch aaaaaaaa refs/heads/main
verify_remote_ref tag bbbbbbbb refs/tags/v1.0.0
expect_failure verify_remote_ref branch cccccccc refs/heads/main
expect_failure verify_remote_ref tag bbbbbbbb refs/tags/v2.0.0

echo "Git backup verifier tests passed"
