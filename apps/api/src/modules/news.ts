import { randomUUID } from 'node:crypto';

import { desc, eq } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';

import { news } from '../db/schema.js';
import { notFound } from '../lib/errors.js';
import { currentUser } from '../plugins/auth.js';
import * as s from '../schemas.js';
import type { AppDeps } from '../app.js';

/** News: any signed-in user reads; only admins publish or remove. */
export const newsRoutes: FastifyPluginAsyncZod<AppDeps> = async (app, { db, now }) => {
  const security = [{ bearer: [] }];

  app.get(
    '/',
    {
      onRequest: app.authenticate,
      schema: { tags: ['notícias'], security, response: { 200: z.array(s.newsArticle) } },
    },
    () =>
      db
        .select()
        .from(news)
        .orderBy(desc(news.publishedAt))
        .limit(100)
        .all()
        .map(({ createdBy, ...n }) => ({ ...n, publishedAt: n.publishedAt.toISOString() })),
  );

  app.post(
    '/',
    {
      onRequest: app.requireAdmin,
      schema: {
        tags: ['notícias'],
        summary: 'Publica uma notícia (administradores)',
        security,
        body: s.newsInput,
        response: { 201: s.newsArticle, 403: s.errorBody },
      },
    },
    async (request, reply) => {
      const row = { id: randomUUID(), ...request.body, publishedAt: now() };
      db.insert(news)
        .values({ ...row, createdBy: currentUser(request).id })
        .run();
      return reply.code(201).send({ ...row, publishedAt: row.publishedAt.toISOString() });
    },
  );

  app.delete(
    '/:id',
    {
      onRequest: app.requireAdmin,
      schema: {
        tags: ['notícias'],
        summary: 'Remove uma notícia (administradores)',
        security,
        params: s.idParam,
        response: { 204: s.noContent, 403: s.errorBody, 404: s.errorBody },
      },
    },
    async (request, reply) => {
      const result = db.delete(news).where(eq(news.id, request.params.id)).run();
      if (result.changes === 0) throw notFound('Notícia');
      return reply.code(204).send(null);
    },
  );
};
