import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import ts from 'typescript';

test('OTP request and verification use the same installation ID', async () => {
  const source = readFileSync(new URL('../src/api.ts', import.meta.url), 'utf8');
  const compiled = ts.transpileModule(source, {
    compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.ESNext },
  }).outputText;
  const { api } = await import(`data:text/javascript;base64,${Buffer.from(compiled).toString('base64')}`);
  const stored = new Map();
  const requests = [];
  const originalFetch = globalThis.fetch;
  globalThis.localStorage = { getItem: key => stored.get(key), setItem: (key, value) => stored.set(key, value) };
  globalThis.document = { cookie: '' };
  globalThis.fetch = async (url, options) => {
    requests.push({ url, headers: new Headers(options.headers) });
    return new Response(JSON.stringify({ success: true, data: {}, error: null }));
  };
  try {
    await api.requestOtp('+79990001003');
    await api.verifyOtp('+79990001003', '123456');
    const id = requests[0].headers.get('X-Installation-Id');
    assert.match(id, /^[0-9a-f-]{36}$/);
    assert.equal(requests[1].headers.get('X-Installation-Id'), id);
  } finally {
    globalThis.fetch = originalFetch;
    delete globalThis.localStorage;
    delete globalThis.document;
  }
});
