import { spawn } from 'node:child_process';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const stages = [
  ['make', ['check']],
  ['make', ['backend-test-e2e']],
  ['make', ['mobile-screenshots']],
  ['make', ['app-user-paths-check']],
];
const cleanup = ['make', ['test-infra-down']];

export async function runLocalPilotSmoke(run = runCommand) {
  let failure;
  try {
    for (const [command, args] of stages) {
      await run(command, args);
    }
  } catch (error) {
    failure = error;
  }

  try {
    await run(cleanup[0], cleanup[1]);
  } catch (error) {
    failure ??= error;
  }

  if (failure) {
    throw failure;
  }
}

function runCommand(command, args) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, { stdio: 'inherit' });
    child.once('error', reject);
    child.once('exit', (code, signal) => {
      if (code === 0) {
        resolvePromise();
        return;
      }
      reject(
        new Error(
          `${command} ${args.join(' ')} failed with ${signal ? `signal ${signal}` : `exit ${code}`}`,
        ),
      );
    });
  });
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  void runLocalPilotSmoke().catch((error) => {
    const message = error instanceof Error ? error.message : 'Unknown error';
    process.stderr.write(`Local pilot smoke failed: ${message}\n`);
    process.exitCode = 1;
  });
}
