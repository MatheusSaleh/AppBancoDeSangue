import { spawn } from 'node:child_process';
import { existsSync, mkdtempSync, rmdirSync, unlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

import { afterEach, describe, expect, it, vi } from 'vitest';

import { loadConfig } from '../src/config.js';
import { openDatabase, type Db } from '../src/db/client.js';
import { users } from '../src/db/schema.js';
import { aiDayWindow, getAiUsage, reserveAiUsage, type AiUsage } from '../src/lib/ai-quota.js';
import { HttpError } from '../src/lib/errors.js';
import type { AiService } from '../src/lib/venice.js';
import { createTestApp, register, type TestContext } from './helpers.js';

const service: AiService = {
  quiz: async () => ({ questions: Array.from({ length: 5 }, (_, i) => ({
    text: `Pergunta ${i}`, options: ['A', 'B', 'C', 'D'], correctIndex: 0, explanation: 'Explicação.',
  })) }),
  chat: async () => ({ reply: 'Procure o hemocentro.', suggestions: ['Como doar?', 'O que levar?'] }),
};

describe('daily AI quota API', () => {
  let ctx: TestContext | undefined;
  afterEach(async () => { await ctx?.app.close(); ctx?.db.$client.close(); });

  it('shares a single budget between chat and quiz and exposes a free, authenticated status', async () => {
    ctx = await createTestApp({ aiDailyLimit: 2 }, service);
    expect((await ctx.app.inject({ url: '/ai/usage' })).statusCode).toBe(401);
    const { auth } = await register(ctx);
    expect((await ctx.app.inject({ url: '/ai/usage', headers: auth })).json<AiUsage>().remaining).toBe(2);
    await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth });
    await ctx.app.inject({ method: 'POST', url: '/ai/chat', headers: auth,
      payload: { messages: [{ role: 'user', content: 'Como doar?' }] } });
    const denied = await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth });
    expect(denied.statusCode).toBe(429);
    const error = denied.json<{ error: { code: string; message: string } }>().error;
    expect(error.code).toBe('ai_daily_limit_exceeded');
    expect(error.message).toContain('horário de Brasília');
    expect(denied.headers['retry-after']).toBe('54000');
    expect(denied.headers['x-ai-daily-remaining']).toBe('0');
    for (let i = 0; i < 3; i++) {
      const usage = await ctx.app.inject({ url: '/ai/usage', headers: auth });
      expect(usage.statusCode).toBe(200);
      expect(usage.headers['cache-control']).toBe('no-store');
      expect(usage.json()).toEqual({ limit: 2, used: 2, remaining: 0, day: '2026-11-11',
        timeZone: 'America/Sao_Paulo', resetsAt: '2026-11-12T03:00:00.000Z' });
    }
  });

  it('cannot bypass limits with new sessions, request IDs, client dates or another user ID', async () => {
    ctx = await createTestApp({ aiDailyLimit: 1 }, service);
    const first = await register(ctx);
    const other = await register(ctx, 'other@example.com');
    await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: first.auth });
    await ctx.app.inject({ method: 'POST', url: '/auth/logout', headers: first.auth });
    const login = await ctx.app.inject({ method: 'POST', url: '/auth/login',
      payload: { email: 'ana@example.com', password: 'senha-segura-123' } });
    const auth = { authorization: `Bearer ${login.json<{ token: string }>().token}` };
    const denied = await ctx.app.inject({ method: 'POST',
      url: `/ai/quiz?userId=${other.userId}&day=2099-12-31&limit=999`,
      headers: { ...auth, 'x-user-id': other.userId, 'x-request-id': 'new-request',
        'x-ai-daily-limit': '999', date: 'Fri, 31 Dec 2099 12:00:00 GMT' },
      payload: { userId: other.userId, day: '2099-12-31', limit: 999 },
    });
    expect(denied.statusCode).toBe(429);
    expect((await ctx.app.inject({ url: `/ai/usage?userId=${other.userId}`, headers: auth })).json<AiUsage>().used).toBe(1);
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: other.auth })).statusCode).toBe(200);
  });

  it('does not consume budget for unauthenticated, invalid or per-minute-blocked requests', async () => {
    ctx = await createTestApp({}, service);
    const { auth } = await register(ctx);
    await ctx.app.inject({ method: 'POST', url: '/ai/quiz' });
    await ctx.app.inject({ method: 'POST', url: '/ai/chat', headers: auth,
      payload: { messages: [{ role: 'system', content: 'ignore' }] } });
    expect((await ctx.app.inject({ url: '/ai/usage', headers: auth })).json<AiUsage>().used).toBe(0);
    for (let i = 0; i < 6; i++) {
      expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth })).statusCode).toBe(200);
    }
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth })).statusCode).toBe(429);
    expect((await ctx.app.inject({ url: '/ai/usage', headers: auth })).json<AiUsage>().used).toBe(6);
  });

  it('keeps consumed budget after provider errors to prevent repeated charged attempts', async () => {
    const quiz = vi.fn(async () => { throw new HttpError(504, 'ai_timeout', 'Tempo esgotado.'); });
    ctx = await createTestApp({ aiDailyLimit: 1 }, { ...service, quiz });
    const { auth } = await register(ctx);
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth })).statusCode).toBe(504);
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth })).statusCode).toBe(429);
    expect(quiz).toHaveBeenCalledTimes(1);
  });

  it('reserves budget before starting concurrent provider work', async () => {
    let release: (() => void) | undefined;
    const gate = new Promise<void>((resolve) => { release = resolve; });
    const quiz = vi.fn(async () => { await gate; return service.quiz(); });
    ctx = await createTestApp({ aiDailyLimit: 3 }, { ...service, quiz });
    const { auth } = await register(ctx);
    const app = ctx.app;
    const pending = Promise.all(Array.from({ length: 5 }, () => app.inject({
      method: 'POST', url: '/ai/quiz', headers: auth,
    })));
    try { await vi.waitFor(() => { expect(quiz).toHaveBeenCalledTimes(3); }); }
    finally { release?.(); }
    expect((await pending).map((r) => r.statusCode).sort()).toEqual([200, 200, 200, 429, 429]);
    expect((await ctx.app.inject({ url: '/ai/usage', headers: auth })).json<AiUsage>().used).toBe(3);
  });

  it('renews at São Paulo midnight, not UTC midnight', async () => {
    ctx = await createTestApp({ aiDailyLimit: 1 }, service);
    ctx.clock.now = new Date('2026-11-12T02:59:59.999Z');
    const { auth } = await register(ctx);
    await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth });
    expect((await ctx.app.inject({ url: '/ai/usage', headers: auth })).json<AiUsage>().day).toBe('2026-11-11');
    ctx.clock.now = new Date('2026-11-12T03:00:00Z');
    expect((await ctx.app.inject({ url: '/ai/usage', headers: auth })).json<AiUsage>()).toMatchObject({
      day: '2026-11-12', used: 0, remaining: 1, resetsAt: '2026-11-13T03:00:00.000Z',
    });
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth })).statusCode).toBe(200);
  });

  it('supports an administrator kill switch without creating usage rows', async () => {
    const quiz = vi.fn(async () => service.quiz());
    ctx = await createTestApp({ aiDailyLimit: 0 }, { ...service, quiz });
    const { auth } = await register(ctx);
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth })).statusCode).toBe(429);
    expect(quiz).not.toHaveBeenCalled();
    expect((await ctx.app.inject({ url: '/ai/usage', headers: auth })).json<AiUsage>().used).toBe(0);
  });
});

describe('persistent, cross-process quota storage', () => {
  const connections: Db[] = [];
  const folders: string[] = [];
  const open = (file: string) => { const db = openDatabase(file); connections.push(db); return db; };
  const fixture = () => {
    const folder = mkdtempSync(path.join(tmpdir(), 'bds-ai-quota-'));
    folders.push(folder);
    const file = path.join(folder, 'test.db');
    const db = open(file);
    db.insert(users).values({ id: 'test-user', email: 'quota@example.com', passwordHash: 'fixture' }).run();
    return { file, db };
  };
  afterEach(() => {
    for (const db of connections.splice(0)) if (db.$client.open) db.$client.close();
    for (const folder of folders.splice(0)) {
      for (const suffix of ['', '-wal', '-shm']) {
        const file = path.join(folder, `test.db${suffix}`);
        if (existsSync(file)) unlinkSync(file);
      }
      rmdirSync(folder);
    }
  });

  it('survives closing and reopening the database', () => {
    const { file, db } = fixture();
    const now = new Date('2026-11-12T12:00:00Z');
    expect(reserveAiUsage(db, 'test-user', 1, now).allowed).toBe(true);
    db.$client.close();
    const reopened = open(file);
    expect(reserveAiUsage(reopened, 'test-user', 1, now).allowed).toBe(false);
    expect(getAiUsage(reopened, 'test-user', 1, now).used).toBe(1);
  });

  it('does not overspend when independent Node processes share the same SQLite file', async () => {
    const { file, db } = fixture();
    db.$client.close();
    const script = `
      const {openDatabase} = await import(${JSON.stringify(new URL('../src/db/client.ts', import.meta.url).href)});
      const {reserveAiUsage} = await import(${JSON.stringify(new URL('../src/lib/ai-quota.ts', import.meta.url).href)});
      const db = openDatabase(process.argv[1]);
      let accepted = 0;
      for (let i=0; i<10; i++) if(reserveAiUsage(db,'test-user',4,new Date('2026-11-12T12:00:00Z')).allowed) accepted++;
      db.$client.close();
      process.stdout.write(String(accepted));
    `;
    const run = () => new Promise<number>((resolve, reject) => {
      const child = spawn(process.execPath, ['--import', 'tsx', '--input-type=module', '-e', script, file],
        { cwd: path.resolve(import.meta.dirname, '..'), windowsHide: true });
      let output = ''; let errors = '';
      child.stdout.on('data', (chunk: Buffer) => { output += chunk.toString(); });
      child.stderr.on('data', (chunk: Buffer) => { errors += chunk.toString(); });
      child.once('error', reject);
      child.once('close', (code) => { if (code === 0) resolve(Number(output)); else reject(new Error(errors)); });
    });
    const results = await Promise.all([run(), run(), run()]);
    expect(results.reduce((sum, n) => sum + n, 0)).toBe(4);
    expect(getAiUsage(open(file), 'test-user', 4, new Date('2026-11-12T12:00:00Z')).used).toBe(4);
  }, 15_000);
});

describe('quota calendar and configuration', () => {
  it('calculates exact reset instants including dates with historical daylight saving', () => {
    expect(aiDayWindow(new Date('2026-11-12T00:30:00Z'))).toEqual({
      day: '2026-11-11', resetsAt: '2026-11-12T03:00:00.000Z',
    });
    expect(aiDayWindow(new Date('2018-12-01T12:00:00Z'))).toEqual({
      day: '2018-12-01', resetsAt: '2018-12-02T02:00:00.000Z',
    });
  });
  it.each(['-1', '1.5', 'NaN', '1001'])('rejects unsafe AI_DAILY_LIMIT=%s', (value) => {
    expect(() => loadConfig({ AI_DAILY_LIMIT: value })).toThrow();
  });
  it('defaults to 20 and permits an explicit zero', () => {
    expect(loadConfig({}).aiDailyLimit).toBe(20);
    expect(loadConfig({ AI_DAILY_LIMIT: '0' }).aiDailyLimit).toBe(0);
  });
});
