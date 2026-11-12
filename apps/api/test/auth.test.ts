import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { generateToken, hashPassword, hashToken, verifyPassword } from '../src/lib/crypto.js';
import { createTestApp, register, type TestContext } from './helpers.js';

describe('crypto', () => {
  const params = { N: 2 ** 10, r: 8, p: 1 };

  it('hashes with a random salt and verifies', async () => {
    const a = await hashPassword('correta-123', params);
    const b = await hashPassword('correta-123', params);
    expect(a).not.toBe(b);
    expect(a.startsWith('scrypt$1024$8$1$')).toBe(true);
    expect(await verifyPassword('correta-123', a)).toBe(true);
    expect(await verifyPassword('errada-123', a)).toBe(false);
  });

  it('rejects malformed hashes', async () => {
    expect(await verifyPassword('x', 'bcrypt$abc')).toBe(false);
  });

  it('generates 256-bit tokens and hashes them deterministically', () => {
    const t = generateToken();
    expect(Buffer.from(t, 'base64url')).toHaveLength(32);
    expect(hashToken(t)).toBe(hashToken(t));
    expect(hashToken(t)).not.toContain(t);
  });
});

describe('auth', () => {
  let ctx: TestContext;
  beforeEach(async () => {
    ctx = await createTestApp();
  });
  afterEach(async () => {
    await ctx.app.close();
  });

  it('registers, normalizes the e-mail and never returns the hash', async () => {
    const res = await ctx.app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: { email: '  Ana@Example.COM ', password: 'senha-segura-123' },
    });
    expect(res.statusCode).toBe(201);
    const body = res.json<{ user: { id: string; email: string; role: string }; token: string }>();
    expect(body.user).toEqual({ id: body.user.id, email: 'ana@example.com', role: 'user' });
    expect(body.user.id).toMatch(/^[0-9a-f-]{36}$/);
    expect(typeof body.token).toBe('string');
    expect(res.body).not.toContain('scrypt');
  });

  it('rejects duplicate e-mails', async () => {
    await register(ctx);
    const res = await ctx.app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: { email: 'ANA@example.com', password: 'outra-senha-123' },
    });
    expect(res.statusCode).toBe(409);
    expect(res.json<{ error: { code: string } }>().error.code).toBe('email_taken');
  });

  it.each([
    [{ email: 'nao-e-email', password: 'senha-segura-123' }],
    [{ email: 'a@b.com', password: 'curta' }],
    [{ email: 'a@b.com', password: 'x'.repeat(129) }],
    [{ email: 'a@b.com' }],
  ])('validates input %#', async (payload) => {
    const res = await ctx.app.inject({ method: 'POST', url: '/auth/register', payload });
    expect(res.statusCode).toBe(400);
    expect(res.json<{ error: { code: string } }>().error.code).toBe('validation_error');
  });

  it('logs in and gives the same error for unknown e-mail and wrong password', async () => {
    await register(ctx);
    const ok = await ctx.app.inject({
      method: 'POST',
      url: '/auth/login',
      payload: { email: 'ana@example.com', password: 'senha-segura-123' },
    });
    expect(ok.statusCode).toBe(200);

    const wrong = await ctx.app.inject({
      method: 'POST',
      url: '/auth/login',
      payload: { email: 'ana@example.com', password: 'senha-errada-123' },
    });
    const unknown = await ctx.app.inject({
      method: 'POST',
      url: '/auth/login',
      payload: { email: 'ninguem@example.com', password: 'senha-errada-123' },
    });
    expect(wrong.statusCode).toBe(401);
    expect(unknown.statusCode).toBe(401);
    expect(wrong.json()).toEqual(unknown.json());
  });

  it('requires a valid bearer token', async () => {
    expect((await ctx.app.inject({ url: '/auth/me' })).statusCode).toBe(401);
    const bad = await ctx.app.inject({
      url: '/auth/me',
      headers: { authorization: `Bearer ${generateToken()}` },
    });
    expect(bad.statusCode).toBe(401);

    const { auth } = await register(ctx);
    const me = await ctx.app.inject({ url: '/auth/me', headers: auth });
    expect(me.json()).toMatchObject({ email: 'ana@example.com', role: 'user' });
  });

  it('logout revokes the token', async () => {
    const { auth } = await register(ctx);
    expect((await ctx.app.inject({ method: 'POST', url: '/auth/logout', headers: auth })).statusCode).toBe(204);
    expect((await ctx.app.inject({ url: '/auth/me', headers: auth })).statusCode).toBe(401);
  });

  it('sessions expire after the configured TTL', async () => {
    const { auth } = await register(ctx);
    ctx.clock.now = new Date(ctx.clock.now.getTime() + 31 * 86_400_000);
    expect((await ctx.app.inject({ url: '/auth/me', headers: auth })).statusCode).toBe(401);
  });

  describe('password reset', () => {
    it('allows only one concurrent confirmation of the same code', async () => {
      const { auth } = await register(ctx);
      await ctx.app.inject({
        method: 'POST',
        url: '/auth/password-reset/request',
        payload: { email: 'ana@example.com' },
      });
      const token = ctx.mailer.sent[0]?.token;
      const passwords = ['primeira-senha-123', 'segunda-senha-456'];
      const results = await Promise.all(passwords.map((password) => ctx.app.inject({
        method: 'POST',
        url: '/auth/password-reset/confirm',
        payload: { token, password },
      })));
      expect(results.map((res) => res.statusCode).sort()).toEqual([204, 400]);
      expect((await ctx.app.inject({ url: '/auth/me', headers: auth })).statusCode).toBe(401);
      for (const [index, password] of passwords.entries()) {
        const login = await ctx.app.inject({
          method: 'POST',
          url: '/auth/login',
          payload: { email: 'ana@example.com', password },
        });
        expect(login.statusCode).toBe(results[index]?.statusCode === 204 ? 200 : 401);
      }
    });

    it('does not reveal whether an account exists', async () => {
      const res = await ctx.app.inject({
        method: 'POST',
        url: '/auth/password-reset/request',
        payload: { email: 'ninguem@example.com' },
      });
      expect(res.statusCode).toBe(202);
      expect(ctx.mailer.sent).toHaveLength(0);
    });

    it('resets the password once and signs out every device', async () => {
      const { auth } = await register(ctx);
      await ctx.app.inject({
        method: 'POST',
        url: '/auth/password-reset/request',
        payload: { email: 'ana@example.com' },
      });
      const token = ctx.mailer.sent[0]?.token;
      expect(token).toBeDefined();

      const confirm = (password: string) =>
        ctx.app.inject({
          method: 'POST',
          url: '/auth/password-reset/confirm',
          payload: { token, password },
        });
      expect((await confirm('nova-senha-456')).statusCode).toBe(204);
      expect((await confirm('outra-senha-789')).statusCode).toBe(400); // single use

      expect((await ctx.app.inject({ url: '/auth/me', headers: auth })).statusCode).toBe(401);
      const login = (password: string) =>
        ctx.app.inject({
          method: 'POST',
          url: '/auth/login',
          payload: { email: 'ana@example.com', password },
        });
      expect((await login('senha-segura-123')).statusCode).toBe(401);
      expect((await login('nova-senha-456')).statusCode).toBe(200);
    });

    it('rejects expired codes and invalidates older ones', async () => {
      await register(ctx);
      const request = () =>
        ctx.app.inject({
          method: 'POST',
          url: '/auth/password-reset/request',
          payload: { email: 'ana@example.com' },
        });
      await request();
      await request();
      const [first, second] = ctx.mailer.sent;

      const confirm = (token: string | undefined) =>
        ctx.app.inject({
          method: 'POST',
          url: '/auth/password-reset/confirm',
          payload: { token, password: 'nova-senha-456' },
        });
      expect((await confirm(first?.token)).statusCode).toBe(400);

      ctx.clock.now = new Date(ctx.clock.now.getTime() + 31 * 60_000);
      expect((await confirm(second?.token)).statusCode).toBe(400);
    });
  });
});

describe('rate limiting', () => {
  it('throttles repeated login attempts per IP', async () => {
    const ctx = await createTestApp({ authRateLimit: 3 });
    const attempt = () =>
      ctx.app.inject({
        method: 'POST',
        url: '/auth/login',
        payload: { email: 'ana@example.com', password: 'senha-errada-123' },
      });
    for (let i = 0; i < 3; i++) expect((await attempt()).statusCode).toBe(401);
    const blocked = await attempt();
    expect(blocked.statusCode).toBe(429);
    expect(blocked.json<{ error: { code: string } }>().error.code).toBe('rate_limited');
    await ctx.app.close();
  });
});
