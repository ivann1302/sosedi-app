import { assertLocalPilotSeedAllowed } from './local-pilot-seed';

const localEnvironment = {
  NODE_ENV: 'development',
  ALLOW_LOCAL_PILOT_SEED: 'true',
  DATABASE_URL:
    'postgresql://sosedi:sosedi@localhost:5432/sosedi?schema=public',
};

describe('local pilot seed guard', () => {
  it('requires an explicit opt-in', () => {
    expect(() =>
      assertLocalPilotSeedAllowed({
        ...localEnvironment,
        ALLOW_LOCAL_PILOT_SEED: undefined,
      }),
    ).toThrow('ALLOW_LOCAL_PILOT_SEED=true');
  });

  it('rejects production even with an explicit opt-in', () => {
    expect(() =>
      assertLocalPilotSeedAllowed({
        ...localEnvironment,
        NODE_ENV: 'production',
      }),
    ).toThrow('production');
  });

  it('rejects a non-loopback PostgreSQL target', () => {
    expect(() =>
      assertLocalPilotSeedAllowed({
        ...localEnvironment,
        DATABASE_URL: 'postgresql://user:pass@db.example/sosedi',
      }),
    ).toThrow('loopback');
  });

  it('allows an explicitly opted-in local development database', () => {
    expect(() => assertLocalPilotSeedAllowed(localEnvironment)).not.toThrow();
  });
});
