import {
  assertIsolatedTarget,
  assertRestoreTargetIsEmpty,
} from './postgres-restore';

describe('PostgreSQL restore target guard', () => {
  const target = {
    host: 'restore-db.internal',
    port: '5432',
    username: 'restore',
    password: 'not-used-by-guard',
    database: 'sosedi_restore_20260729',
    sslMode: 'require',
  };

  it('requires an isolated database and exact target confirmation', () => {
    expect(() =>
      assertIsolatedTarget(
        target,
        'restore-db.internal:5432/sosedi_restore_20260729',
      ),
    ).not.toThrow();
    expect(() =>
      assertIsolatedTarget(target, 'production-db.internal:5432/sosedi'),
    ).toThrow('RESTORE_CONFIRM_TARGET');
  });

  it('rejects a database without the restore prefix', () => {
    expect(() =>
      assertIsolatedTarget(
        { ...target, database: 'sosedi' },
        'restore-db.internal:5432/sosedi',
      ),
    ).toThrow('sosedi_restore_');
  });

  it('rejects a restore target that already contains application tables', () => {
    expect(() => assertRestoreTargetIsEmpty('')).not.toThrow();
    expect(() => assertRestoreTargetIsEmpty('public.users')).toThrow(
      'must be empty',
    );
  });
});
