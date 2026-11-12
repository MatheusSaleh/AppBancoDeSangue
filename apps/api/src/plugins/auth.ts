import { and, eq, gt } from 'drizzle-orm';
import type { FastifyInstance, FastifyRequest } from 'fastify';
import fp from 'fastify-plugin';

import type { Db } from '../db/client.js';
import { sessions, users } from '../db/schema.js';
import { hashToken } from '../lib/crypto.js';
import { forbidden, unauthorized } from '../lib/errors.js';

export interface AuthUser {
  id: string;
  email: string;
  role: 'user' | 'admin';
  sessionId: string;
}

declare module 'fastify' {
  interface FastifyRequest {
    /** Set by the `authenticate` hook. */
    authUser: AuthUser | null;
  }
  interface FastifyInstance {
    authenticate: (request: FastifyRequest) => Promise<void>;
    requireAdmin: (request: FastifyRequest) => Promise<void>;
  }
}

export interface AuthPluginOptions {
  db: Db;
  now: () => Date;
}

/** Resolves `Authorization: Bearer <token>` against hashed sessions. */
export const authPlugin = fp<AuthPluginOptions>(
  (app: FastifyInstance, { db, now }) => {
    app.decorateRequest('authUser', null);

    app.decorate('authenticate', async (request: FastifyRequest) => {
      const header = request.headers.authorization;
      const match = header?.match(/^Bearer ([A-Za-z0-9_-]{20,128})$/);
      if (!match?.[1]) throw unauthorized();

      const row = db
        .select({
          sessionId: sessions.id,
          id: users.id,
          email: users.email,
          role: users.role,
        })
        .from(sessions)
        .innerJoin(users, eq(users.id, sessions.userId))
        .where(and(eq(sessions.tokenHash, hashToken(match[1])), gt(sessions.expiresAt, now())))
        .get();

      if (!row) throw unauthorized();
      request.authUser = row;
      await Promise.resolve();
    });

    app.decorate('requireAdmin', async (request: FastifyRequest) => {
      await app.authenticate(request);
      if (request.authUser?.role !== 'admin') throw forbidden();
    });
  },
  { name: 'auth' },
);

/** Narrowing helper for handlers behind `authenticate`. */
export function currentUser(request: FastifyRequest): AuthUser {
  if (!request.authUser) throw unauthorized();
  return request.authUser;
}
