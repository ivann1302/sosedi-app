# Source repository backup

The GitHub `origin` is the working remote, not an independent backup. A backup
is accepted only when all of the following are true:

- it is hosted by a different provider/hostname;
- access is private and protected by MFA;
- the backup credential can write only the backup repository;
- all branches and tags have been copied;
- the current clean `HEAD` is present in the backup default branch;
- restore access is tested by a separate clone without using `origin`.

Configure credentials through the Git credential helper or provider CLI. Never
put a token in the remote URL or repository files.

```bash
git remote add backup <private-independent-repository-url>
git push backup --all
git push backup --tags
make git-backup-verify
```

The verifier is read-only apart from `git fetch`. By default it checks
`backup/main`; names can be overridden with `GIT_BACKUP_REMOTE` and
`GIT_BACKUP_BRANCH`. It rejects local/file remotes, embedded HTTP(S)
credentials, a dirty worktree, the same host as `origin`, a backup branch that
does not contain local `HEAD`, and any local branch/tag whose exact ref is
missing from the independent remote. `make git-backup-test` checks these
fail-closed guards without contacting a provider.

After the first successful verification, test recovery into a temporary
directory and record only the provider, date, commit SHA and restore result.
Do not record the repository URL if it contains organization identifiers that
should remain private.
