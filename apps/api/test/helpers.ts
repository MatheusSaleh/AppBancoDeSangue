import { eq } from 'drizzle-orm';

import { buildApp } from '../src/app.js';
import { loadConfig, type Config } from '../src/config.js';
import { openDatabase, type Db } from '../src/db/client.js';
import { users } from '../src/db/schema.js';
import { MemoryMailer } from '../src/lib/mailer.js';

export interface TestContext {
  app: Awaited<ReturnType<typeof buildApp>>;
  db: Db;
  mailer: MemoryMailer;
  clock: { now: Date };
}

/** Fresh in-memory database per test; cheap scrypt params keep tests fast. */
export async function createTestApp(overrides: Partial<Config> = {}): Promise<TestContext> {
  const config: Config = {
    ...loadConfig({ NODE_ENV: 'test' }),
    authRateLimit: 1000,
    globalRateLimit: 10_000,
    ...overrides,
  };
  const db = openDatabase(':memory:');
  const mailer = new MemoryMailer();
  const clock = { now: new Date('2026-11-11T12:00:00Z') };
  const app = await buildApp({
    config,
    db,
    mailer,
    now: () => clock.now,
    scrypt: { N: 2 ** 10, r: 8, p: 1 },
  });
  return { app, db, mailer, clock };
}

export async function register(
  ctx: TestContext,
  email = 'ana@example.com',
  password = 'senha-segura-123',
) {
  const res = await ctx.app.inject({
    method: 'POST',
    url: '/auth/register',
    payload: { email, password },
  });
  const body = res.json<{ token: string; user: { id: string } }>();
  return { token: body.token, userId: body.user.id, auth: { authorization: `Bearer ${body.token}` } };
}

export function promote(ctx: TestContext, userId: string) {
  ctx.db.update(users).set({ role: 'admin' }).where(eq(users.id, userId)).run();
}
