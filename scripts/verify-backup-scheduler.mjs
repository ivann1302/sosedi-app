import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const serviceRequirements = [
  '[Service]',
  'Type=oneshot',
  'User=sosedi-backup',
  'Group=sosedi-backup',
  'WorkingDirectory=/opt/sosedi/current/backend',
  'EnvironmentFile=/etc/sosedi/backup.env',
  'ExecStartPre=/usr/bin/test -r /etc/sosedi/backup.env',
  'ExecStart=/usr/bin/node dist/src/operations/postgres-backup.js',
  'TimeoutStartSec=60min',
  'UMask=0077',
  'NoNewPrivileges=true',
  'PrivateTmp=true',
  'ProtectSystem=strict',
  'ProtectHome=true',
  'ReadWritePaths=/var/lib/node_exporter/textfile_collector',
];

const timerRequirements = [
  '[Timer]',
  'OnCalendar=*-*-* 00,06,12,18:00:00 UTC',
  'AccuracySec=1min',
  'Persistent=true',
  'Unit=sosedi-postgres-backup.service',
  '[Install]',
  'WantedBy=timers.target',
];

export function verifyBackupScheduler(service, timer) {
  requireLines('service', service, serviceRequirements);
  requireLines('timer', timer, timerRequirements);
  if (/^User=root$/m.test(service)) {
    throw new Error('Backup service must not run as root');
  }
}

function requireLines(name, source, required) {
  for (const line of required) {
    if (!source.split(/\r?\n/u).includes(line)) {
      throw new Error(`Backup ${name} is missing: ${line}`);
    }
  }
}

async function main() {
  const servicePath =
    process.argv[2] ?? 'ops/systemd/sosedi-postgres-backup.service';
  const timerPath =
    process.argv[3] ?? 'ops/systemd/sosedi-postgres-backup.timer';
  const [service, timer] = await Promise.all([
    readFile(servicePath, 'utf8'),
    readFile(timerPath, 'utf8'),
  ]);
  verifyBackupScheduler(service, timer);
  process.stdout.write('Backup scheduler contract is valid\n');
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  await main();
}
