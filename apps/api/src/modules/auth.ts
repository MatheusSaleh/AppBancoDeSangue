import { randomUUID } from 'node:crypto';

import { and, eq, gt, isNull } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';

import { passwordResets, sessions, users } from '../db/schema.js';
import { generateToken, hashPassword, hashToken, verifyPassword } from '../lib/crypto.js';
import { HttpError } from '../lib/errors.js';
import { currentUser } from '../plugins/auth.js';
import * as s from '../schemas.js';
import type { AppDeps } from '../app.js';

const RESET_TTL_MS = 30 * 60 * 1000;

export const authRoutes: FastifyPluginAsyncZod<AppDeps> = async (app, deps) => {
  const { db, now, config, mailer, scrypt } = deps;
  const authLimit = { rateLimit: { max: config.authRateLimit, timeWindow: '1 minute' } };

  // Verifying against a dummy hash when the e-mail does not exist keeps the
  // response time similar, so login timing does not reveal registered e-mails.
  const dummyHash = hashPassword(randomUUID(), scrypt);

  function createSession(userId: string) {
    const token = generateToken();
    const expiresAt = new Date(now().getTime() + config.sessionTtlDays * 86_400_000);
    db.insert(sessions)
      .values({ id: randomUUID(), userId, tokenHash: hashToken(token), expiresAt })
      .run();
    return { token, expiresAt: expiresAt.toISOString() };
  }

  app.post(
    '/register',
    {
      config: authLimit,
      schema: {
        tags: ['auth'],
        summary: 'Cria uma conta e inicia uma sessão',
        body: s.credentials,
        response: { 201: s.session, 409: s.errorBody },
      },
    },
    async (request, reply) => {
      const { email, password } = request.body;
      const passwordHash = await hashPassword(password, scrypt);
      const id = randomUUID();
      // Drizzle types `.get()` as always defined, but it is undefined when the
      // insert was skipped by the conflict clause.
      const inserted = db
        .insert(users)
        .values({ id, email, passwordHash })
        .onConflictDoNothing({ target: users.email })
        .returning({ id: users.id })
        .get() as { id: string } | undefined;
      if (!inserted) {
        throw new HttpError(409, 'email_taken', 'Já existe uma conta com este e-mail.');
      }
      return reply.code(201).send({ ...createSession(id), user: { id, email, role: 'user' } });
    },
  );

  app.post(
    '/login',
    {
      config: authLimit,
      schema: {
        tags: ['auth'],
        summary: 'Entra com e-mail e senha',
        body: s.credentials,
        response: { 200: s.session, 401: s.errorBody },
      },
    },
    async (request) => {
      const { email, password } = request.body;
      const user = db.select().from(users).where(eq(users.email, email)).get();
      const ok = await verifyPassword(password, user?.passwordHash ?? (await dummyHash));
      if (!user || !ok) {
        throw new HttpError(401, 'invalid_credentials', 'E-mail ou senha incorretos.');
      }
      return {
        ...createSession(user.id),
        user: { id: user.id, email: user.email, role: user.role },
      };
    },
  );

  app.post(
    '/logout',
    {
      onRequest: app.authenticate,
      schema: { tags: ['auth'], summary: 'Encerra a sessão atual', security: [{ bearer: [] }] },
    },
    async (request, reply) => {
      db.delete(sessions).where(eq(sessions.id, currentUser(request).sessionId)).run();
      return reply.code(204).send(null);
    },
  );

  app.get(
    '/me',
    {
      onRequest: app.authenticate,
      schema: {
        tags: ['auth'],
        summary: 'Usuário da sessão atual',
        security: [{ bearer: [] }],
        response: { 200: s.user },
      },
    },
    (request) => {
      const { id, email, role } = currentUser(request);
      return { id, email, role };
    },
  );

  app.post(
    '/password-reset/request',
    {
      config: authLimit,
      schema: {
        tags: ['auth'],
        summary: 'Envia um código de redefinição de senha',
        description: 'Responde 202 mesmo quando o e-mail não existe, para não revelar contas.',
        body: z.object({ email: s.email }),
      },
    },
    async (request, reply) => {
      const user = db
        .select({ id: users.id, email: users.email })
        .from(users)
        .where(eq(users.email, request.body.email))
        .get();
      if (user) {
        const token = generateToken();
        db.transaction((tx) => {
          // Only the most recent code is valid.
          tx.delete(passwordResets)
            .where(and(eq(passwordResets.userId, user.id), isNull(passwordResets.usedAt)))
            .run();
          tx.insert(passwordResets)
            .values({
              id: randomUUID(),
              userId: user.id,
              tokenHash: hashToken(token),
              expiresAt: new Date(now().getTime() + RESET_TTL_MS),
            })
            .run();
        });
        await mailer.sendPasswordReset(user.email, token);
      }
      return reply.code(202).send(null);
    },
  );

  app.post(
    '/password-reset/confirm',
    {
      config: authLimit,
      schema: {
        tags: ['auth'],
        summary: 'Define uma nova senha com o código recebido',
        body: z.object({ token: z.string().min(20).max(128), password: s.password }),
        response: { 204: s.noContent, 400: s.errorBody },
      },
    },
    async (request, reply) => {
      const reset = db
        .select()
        .from(passwordResets)
        .where(
          and(
            eq(passwordResets.tokenHash, hashToken(request.body.token)),
            isNull(passwordResets.usedAt),
            gt(passwordResets.expiresAt, now()),
          ),
        )
        .get();
      if (!reset) {
        throw new HttpError(400, 'invalid_token', 'Código inválido ou expirado.');
      }
      const passwordHash = await hashPassword(request.body.password, scrypt);
      db.transaction((tx) => {
        // Hashing yields to other requests. Revalidate and consume atomically:
        // the code may have been used, replaced or expired in the meantime.
        const consumed = tx.update(passwordResets)
          .set({ usedAt: now() })
          .where(and(
            eq(passwordResets.id, reset.id),
            isNull(passwordResets.usedAt),
            gt(passwordResets.expiresAt, now()),
          ))
          .run();
        if (consumed.changes !== 1) {
          throw new HttpError(400, 'invalid_token', 'Código inválido ou expirado.');
        }
        tx.update(users).set({ passwordHash }).where(eq(users.id, reset.userId)).run();
        // A password change signs out every device.
        tx.delete(sessions).where(eq(sessions.userId, reset.userId)).run();
      });
      return reply.code(204).send(null);
    },
  );
};
