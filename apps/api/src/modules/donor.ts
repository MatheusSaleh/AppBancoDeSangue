import { randomUUID } from 'node:crypto';

import { and, desc, eq } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';

import { donations, users } from '../db/schema.js';
import { HttpError, notFound } from '../lib/errors.js';
import { currentUser } from '../plugins/auth.js';
import * as s from '../schemas.js';
import type { AppDeps } from '../app.js';

/**
 * Profile and donation history. Every query is scoped by the authenticated
 * user's id, so one user can never read or change another user's records
 * (an id from someone else simply returns 404).
 */
export const donorRoutes: FastifyPluginAsyncZod<AppDeps> = async (app, { db, now }) => {
  app.addHook('onRequest', app.authenticate);
  const security = [{ bearer: [] }];

  /** Rejects dates in the future. One day of tolerance covers time zones
   * ahead of the server (e.g. a client already on the next calendar day). */
  function assertNotFuture(date: string) {
    const limit = new Date(now().getTime() + 86_400_000).toISOString().slice(0, 10);
    if (date > limit) {
      throw new HttpError(422, 'future_date', 'A data da doação não pode estar no futuro.');
    }
  }

  app.get(
    '/profile',
    { schema: { tags: ['perfil'], security, response: { 200: s.profile } } },
    (request) => {
      const row = db
        .select({ name: users.name, sex: users.sex, bloodType: users.bloodType })
        .from(users)
        .where(eq(users.id, currentUser(request).id))
        .get();
      if (!row) throw notFound('Conta');
      return { ...row, bloodType: s.bloodType.nullable().catch(null).parse(row.bloodType) };
    },
  );

  app.put(
    '/profile',
    { schema: { tags: ['perfil'], security, body: s.profile, response: { 200: s.profile } } },
    (request) => {
      db.update(users).set(request.body).where(eq(users.id, currentUser(request).id)).run();
      return request.body;
    },
  );

  app.get(
    '/donations',
    {
      schema: {
        tags: ['doações'],
        summary: 'Doações do usuário, mais recentes primeiro',
        security,
        response: { 200: z.array(s.donation) },
      },
    },
    (request) =>
      db
        .select({
          id: donations.id,
          date: donations.date,
          location: donations.location,
          notes: donations.notes,
        })
        .from(donations)
        .where(eq(donations.userId, currentUser(request).id))
        .orderBy(desc(donations.date), desc(donations.createdAt))
        .all(),
  );

  app.post(
    '/donations',
    {
      schema: {
        tags: ['doações'],
        security,
        body: s.donationInput,
        response: { 201: s.donation, 422: s.errorBody },
      },
    },
    async (request, reply) => {
      assertNotFuture(request.body.date);
      const row = { id: randomUUID(), ...request.body };
      db.insert(donations)
        .values({ ...row, userId: currentUser(request).id })
        .run();
      return reply.code(201).send(row);
    },
  );

  app.put(
    '/donations/:id',
    {
      schema: {
        tags: ['doações'],
        security,
        params: s.idParam,
        body: s.donationInput,
        response: { 200: s.donation, 404: s.errorBody, 422: s.errorBody },
      },
    },
    (request) => {
      assertNotFuture(request.body.date);
      // undefined when no row matched (wrong id or another user's record).
      const updated = db
        .update(donations)
        .set({ ...request.body, updatedAt: now() })
        .where(
          and(eq(donations.id, request.params.id), eq(donations.userId, currentUser(request).id)),
        )
        .returning({ id: donations.id })
        .get() as { id: string } | undefined;
      if (!updated) throw notFound('Doação');
      return { id: updated.id, ...request.body };
    },
  );

  app.delete(
    '/donations/:id',
    {
      schema: {
        tags: ['doações'],
        security,
        params: s.idParam,
        response: { 204: s.noContent, 404: s.errorBody },
      },
    },
    async (request, reply) => {
      const result = db
        .delete(donations)
        .where(
          and(eq(donations.id, request.params.id), eq(donations.userId, currentUser(request).id)),
        )
        .run();
      if (result.changes === 0) throw notFound('Doação');
      return reply.code(204).send(null);
    },
  );
};
