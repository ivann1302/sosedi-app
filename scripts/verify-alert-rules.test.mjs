import assert from 'node:assert/strict';
import test from 'node:test';
import {
  loadAlertRules,
  verifyAlertGroups,
} from './verify-alert-rules.mjs';

const rules = loadAlertRules('ops/monitoring/prometheus-alerts.yml');

test('accepts the repository alert contract', () => {
  assert.doesNotThrow(() => verifyAlertGroups(rules));
});

test('rejects a rule without an owner', () => {
  assert.throws(
    () =>
      verifyAlertGroups({
        groups: [
          {
            rules: [
              {
                alert: 'Incomplete',
                labels: { severity: 'warning' },
                annotations: {
                  summary: 'summary',
                  threshold: 'threshold',
                  runbook: 'docs/monitoring-alert-runbooks.md#test',
                },
              },
            ],
          },
        ],
      }),
    /actionable owner/,
  );
});

test('rejects a backup freshness rule that ignores an absent metric', () => {
  const document = structuredClone(rules);
  const backupRule = document.groups
    .flatMap((group) => group.rules)
    .find((rule) => rule.alert === 'SosediPostgresBackupMissing');
  backupRule.expr =
    'time() - sosedi_backup_last_success_timestamp_seconds > 93600';

  assert.throws(
    () => verifyAlertGroups(document),
    /freshness metric is absent/,
  );
});

test('rejects a backup freshness threshold beyond the six-hour RPO grace', () => {
  const document = structuredClone(rules);
  const backupRule = document.groups
    .flatMap((group) => group.rules)
    .find((rule) => rule.alert === 'SosediPostgresBackupMissing');
  backupRule.expr = String(backupRule.expr).replace('25200', '93600');

  assert.throws(
    () => verifyAlertGroups(document),
    /7-hour freshness threshold/,
  );
});

test('rejects a backup scheduler alert without the exact failed unit', () => {
  const document = structuredClone(rules);
  const schedulerRule = document.groups
    .flatMap((group) => group.rules)
    .find((rule) => rule.alert === 'SosediPostgresBackupSchedulerFailed');
  schedulerRule.expr = 'node_systemd_unit_state{state="failed"} == 1';

  assert.throws(
    () => verifyAlertGroups(document),
    /failed backup service/,
  );
});
