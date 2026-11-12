import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { createTestApp, promote, register, type TestContext } from './helpers.js';

let ctx: TestContext;
beforeEach(async () => {
  ctx = await createTestApp();
});
afterEach(async () => {
  await ctx.app.close();
});

describe('profile', () => {
  it('starts empty and can be updated', async () => {
    const { auth } = await register(ctx);
    const empty = await ctx.app.inject({ url: '/profile', headers: auth });
    expect(empty.json()).toEqual({ name: '', sex: null, bloodType: null });

    const profile = { name: 'Ana Souza', sex: 'feminino', bloodType: 'O-' };
    const put = await ctx.app.inject({ method: 'PUT', url: '/profile', headers: auth, payload: profile });
    expect(put.statusCode).toBe(200);
    expect((await ctx.app.inject({ url: '/profile', headers: auth })).json()).toEqual(profile);
  });

  it('validates sex and blood type', async () => {
    const { auth } = await register(ctx);
    const res = await ctx.app.inject({
      method: 'PUT',
      url: '/profile',
      headers: auth,
      payload: { name: 'Ana', sex: 'outro', bloodType: 'C+' },
    });
    expect(res.statusCode).toBe(400);
  });
});

describe('donations', () => {
  it('creates, lists (most recent first), updates and deletes', async () => {
    const { auth } = await register(ctx);
    const create = (date: string, location = '') =>
      ctx.app.inject({ method: 'POST', url: '/donations', headers: auth, payload: { date, location } });

    const a = (await create('2026-01-10', 'Hemocentro')).json<{ id: string }>();
    await create('2026-06-01');
    const list = await ctx.app.inject({ url: '/donations', headers: auth });
    expect(list.json<{ date: string }[]>().map((d) => d.date)).toEqual(['2026-06-01', '2026-01-10']);

    const updated = await ctx.app.inject({
      method: 'PUT',
      url: `/donations/${a.id}`,
      headers: auth,
      payload: { date: '2026-01-11', notes: 'corrigido' },
    });
    expect(updated.json()).toEqual({ id: a.id, date: '2026-01-11', location: '', notes: 'corrigido' });

    expect((await ctx.app.inject({ method: 'DELETE', url: `/donations/${a.id}`, headers: auth })).statusCode).toBe(204);
    expect((await ctx.app.inject({ url: '/donations', headers: auth })).json()).toHaveLength(1);
  });

  it('rejects future dates and invalid input', async () => {
    const { auth } = await register(ctx);
    const post = (payload: object) =>
      ctx.app.inject({ method: 'POST', url: '/donations', headers: auth, payload });

    // Today is 2026-11-11 (test clock); one day of tolerance for time zones.
    expect((await post({ date: '2026-11-12' })).statusCode).toBe(201);
    const future = await post({ date: '2026-11-20' });
    expect(future.statusCode).toBe(422);
    expect(future.json<{ error: { code: string } }>().error.code).toBe('future_date');

    expect((await post({ date: '11/10/2026' })).statusCode).toBe(400);
    expect((await post({ date: '2026-02-30' })).statusCode).toBe(400);
    expect((await post({ date: '2026-01-01', notes: 'x'.repeat(281) })).statusCode).toBe(400);
  });

  it("isolates users: nobody can read or change someone else's records", async () => {
    const ana = await register(ctx, 'ana@example.com');
    const bia = await register(ctx, 'bia@example.com');
    const created = await ctx.app.inject({
      method: 'POST',
      url: '/donations',
      headers: ana.auth,
      payload: { date: '2026-03-01' },
    });
    const id = created.json<{ id: string }>().id;

    expect((await ctx.app.inject({ url: '/donations', headers: bia.auth })).json()).toEqual([]);
    const update = await ctx.app.inject({
      method: 'PUT',
      url: `/donations/${id}`,
      headers: bia.auth,
      payload: { date: '2026-03-02' },
    });
    expect(update.statusCode).toBe(404);
    const del = await ctx.app.inject({ method: 'DELETE', url: `/donations/${id}`, headers: bia.auth });
    expect(del.statusCode).toBe(404);

    // Ana's record is untouched.
    const list = await ctx.app.inject({ url: '/donations', headers: ana.auth });
    expect(list.json()).toEqual([{ id, date: '2026-03-01', location: '', notes: '' }]);
  });

  it('rejects malformed ids and missing auth', async () => {
    const { auth } = await register(ctx);
    expect((await ctx.app.inject({ method: 'DELETE', url: '/donations/1 OR 1=1', headers: auth })).statusCode).toBe(400);
    expect((await ctx.app.inject({ url: '/donations' })).statusCode).toBe(401);
  });
});

describe('news', () => {
  it('signed-in users read; only admins publish and delete', async () => {
    const user = await register(ctx, 'ana@example.com');
    const admin = await register(ctx, 'admin@example.com');
    promote(ctx, admin.userId);
    const article = { title: 'Campanha', summary: 'Resumo', body: 'Texto' };

    expect((await ctx.app.inject({ url: '/news' })).statusCode).toBe(401);
    const forbidden = await ctx.app.inject({ method: 'POST', url: '/news', headers: user.auth, payload: article });
    expect(forbidden.statusCode).toBe(403);

    const created = await ctx.app.inject({ method: 'POST', url: '/news', headers: admin.auth, payload: article });
    expect(created.statusCode).toBe(201);
    const list = await ctx.app.inject({ url: '/news', headers: user.auth });
    expect(list.json()).toEqual([
      { ...article, id: created.json<{ id: string }>().id, publishedAt: '2026-11-11T12:00:00.000Z' },
    ]);

    const id = created.json<{ id: string }>().id;
    expect((await ctx.app.inject({ method: 'DELETE', url: `/news/${id}`, headers: user.auth })).statusCode).toBe(403);
    expect((await ctx.app.inject({ method: 'DELETE', url: `/news/${id}`, headers: admin.auth })).statusCode).toBe(204);
  });
});

describe('http hardening', () => {
  it('exposes a health check without auth', async () => {
    const res = await ctx.app.inject({ url: '/health' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ status: 'ok' });
  });

  it('sets security headers and returns JSON errors', async () => {
    const res = await ctx.app.inject({ url: '/rota-inexistente' });
    expect(res.statusCode).toBe(404);
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.json<{ error: { code: string } }>().error.code).toBe('not_found');
  });

  it('only allows configured browser origins', async () => {
    const preflight = (origin: string) =>
      ctx.app.inject({
        method: 'OPTIONS',
        url: '/auth/login',
        headers: { origin, 'access-control-request-method': 'POST' },
      });
    expect((await preflight('http://localhost:5555')).headers['access-control-allow-origin']).toBe(
      'http://localhost:5555',
    );
    expect((await preflight('https://evil.example')).headers['access-control-allow-origin']).toBeUndefined();
  });

  it('rejects oversized bodies', async () => {
    const res = await ctx.app.inject({
      method: 'POST',
      url: '/auth/login',
      payload: { email: 'a@b.com', password: 'x'.repeat(20_000) },
    });
    expect(res.statusCode).toBe(413);
  });
});
