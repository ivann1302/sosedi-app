import assert from 'node:assert/strict';
import test from 'node:test';

import { verifyBackupScheduler } from './verify-backup-scheduler.mjs';

const service = `[Service]
Type=oneshot
User=sosedi-backup
Group=sosedi-backup
WorkingDirectory=/opt/sosedi/current/backend
EnvironmentFile=/etc/sosedi/backup.env
ExecStartPre=/usr/bin/test -r /etc/sosedi/backup.env
ExecStart=/usr/bin/node dist/src/operations/postgres-backup.js
TimeoutStartSec=60min
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/node_exporter/textfile_collector
`;

const timer = `[Timer]
OnCalendar=*-*-* 00,06,12,18:00:00 UTC
AccuracySec=1min
Persistent=true
Unit=sosedi-postgres-backup.service
[Install]
WantedBy=timers.target
`;

test('accepts the hardened six-hour scheduler contract', () => {
  assert.doesNotThrow(() => verifyBackupScheduler(service, timer));
});

test('rejects a privileged service or a relaxed schedule', () => {
  assert.throws(
    () =>
      verifyBackupScheduler(
        service.replace('User=sosedi-backup', 'User=root'),
        timer,
      ),
    /missing: User=sosedi-backup/u,
  );
  assert.throws(
    () =>
      verifyBackupScheduler(
        service,
        timer.replace(
          'OnCalendar=*-*-* 00,06,12,18:00:00 UTC',
          'OnCalendar=daily',
        ),
      ),
    /missing: OnCalendar/u,
  );
});
