#!/usr/bin/env node

import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const require = createRequire(
  new URL('../backend/package.json', import.meta.url),
);
const { load } = require('js-yaml');
const REQUIRED_ALERTS = new Set([
  'SosediNodeDiskLow',
  'SosediTlsCertificateExpiring',
  'SosediDomainDnsUnavailable',
  'SosediDomainRegistrationExpiring',
  'SosediProviderCredentialExpiring',
  'SosediExpiryInventoryMissing',
  'SosediPostgresBackupMissing',
  'SosediPostgresBackupSchedulerFailed',
]);
const OWNERS = new Set(['product-owner', 'on-call-operator']);
const SEVERITIES = new Set(['warning', 'critical']);

export function verifyAlertGroups(document) {
  if (!document || !Array.isArray(document.groups)) {
    throw new Error('Alert rules must contain groups');
  }

  const names = new Set();
  for (const group of document.groups) {
    if (!group || !Array.isArray(group.rules)) {
      throw new Error('Each alert group must contain rules');
    }
    for (const rule of group.rules) {
      if (typeof rule?.alert !== 'string' || !rule.alert) {
        throw new Error('Every rule must have an alert name');
      }
      if (names.has(rule.alert)) {
        throw new Error(`Duplicate alert ${rule.alert}`);
      }
      names.add(rule.alert);
      if (!OWNERS.has(rule.labels?.owner)) {
        throw new Error(`${rule.alert} must have an actionable owner`);
      }
      if (!SEVERITIES.has(rule.labels?.severity)) {
        throw new Error(`${rule.alert} must have a supported severity`);
      }
      for (const annotation of ['summary', 'threshold', 'runbook']) {
        if (typeof rule.annotations?.[annotation] !== 'string') {
          throw new Error(`${rule.alert} must have ${annotation}`);
        }
      }
      if (
        !rule.annotations.runbook.startsWith(
          'docs/monitoring-alert-runbooks.md#',
        )
      ) {
        throw new Error(`${rule.alert} must link the monitoring runbook`);
      }
      if (
        rule.alert === 'SosediPostgresBackupMissing' &&
        !String(rule.expr).includes(
          'absent(sosedi_backup_last_success_timestamp_seconds)',
        )
      ) {
        throw new Error(
          'SosediPostgresBackupMissing must alert when the freshness metric is absent',
        );
      }
      if (
        rule.alert === 'SosediPostgresBackupMissing' &&
        !String(rule.expr).includes(
          'sosedi_backup_last_success_timestamp_seconds > 25200',
        )
      ) {
        throw new Error(
          'SosediPostgresBackupMissing must enforce the 7-hour freshness threshold',
        );
      }
      if (
        rule.alert === 'SosediPostgresBackupSchedulerFailed' &&
        !String(rule.expr).includes(
          'node_systemd_unit_state{name="sosedi-postgres-backup.service",state="failed"}',
        )
      ) {
        throw new Error(
          'SosediPostgresBackupSchedulerFailed must target only the failed backup service',
        );
      }
    }
  }

  for (const required of REQUIRED_ALERTS) {
    if (!names.has(required)) {
      throw new Error(`Missing required alert ${required}`);
    }
  }
}

export function loadAlertRules(path) {
  return load(readFileSync(path, 'utf8'));
}

function main() {
  const path = resolve(
    process.argv[2] ?? 'ops/monitoring/prometheus-alerts.yml',
  );
  verifyAlertGroups(loadAlertRules(path));
  process.stdout.write(`Alert rules are actionable: ${path}\n`);
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  try {
    main();
  } catch (error) {
    process.stderr.write(
      `Alert rule verification failed: ${
        error instanceof Error ? error.message : 'unknown error'
      }\n`,
    );
    process.exitCode = 1;
  }
}
