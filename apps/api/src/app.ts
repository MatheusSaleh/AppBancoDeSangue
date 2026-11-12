import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import Fastify, { type FastifyServerOptions } from 'fastify';
import {
  hasZodFastifySchemaValidationErrors,
  jsonSchemaTransform,
  serializerCompiler,
  validatorCompiler,
  type ZodTypeProvider,
} from 'fastify-type-provider-zod';

import type { Config } from './config.js';
import type { Db } from './db/client.js';
import { DEFAULT_SCRYPT, type ScryptParams } from './lib/crypto.js';
import { HttpError } from './lib/errors.js';
import { LogMailer, type Mailer } from './lib/mailer.js';
import { VeniceService, type AiService } from './lib/venice.js';
import { aiRoutes } from './modules/ai.js';
import { authRoutes } from './modules/auth.js';
import { donorRoutes } from './modules/donor.js';
import { newsRoutes } from './modules/news.js';
import { authPlugin } from './plugins/auth.js';

export interface AppDeps {
  config: Config;
  db: Db;
  mailer: Mailer;
  now: () => Date;
  scrypt: ScryptParams;
  ai: AiService;
}

type BuildDeps = Pick<AppDeps, 'config' | 'db'> & Partial<Omit<AppDeps, 'config' | 'db'>>;

export async function buildApp(deps: BuildDeps, options: FastifyServerOptions = {}) {
  const { config } = deps;
  const app = Fastify({
    bodyLimit: 16 * 1024,
    trustProxy: config.trustProxy,
    ...options,
  }).withTypeProvider<ZodTypeProvider>();

  const full: AppDeps = {
    ai: new VeniceService(config),
    now: () => new Date(),
    scrypt: DEFAULT_SCRYPT,
    // Without a real provider, reset codes go to the server log.
    mailer: new LogMailer(app.log),
    ...deps,
  };

  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  // JSON-only API: CSP and other HTML-oriented headers are left to Helmet's
  // defaults, except where the interactive docs need inline assets.
  await app.register(helmet, { contentSecurityPolicy: !config.enableDocs });
  await app.register(cors, {
    origin: (origin, cb) => {
      // Native apps send no Origin header; browsers must be allow-listed.
      if (!origin) {
        cb(null, true);
        return;
      }
      const devLocalhost =
        config.env !== 'production' && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
      cb(null, devLocalhost || config.corsOrigins.includes(origin));
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Authorization', 'Content-Type'],
    exposedHeaders: ['X-AI-Daily-Limit', 'X-AI-Daily-Remaining', 'X-AI-Reset-At', 'Retry-After'],
    maxAge: 600,
  });
  await app.register(rateLimit, { max: config.globalRateLimit, timeWindow: '1 minute' });

  if (config.enableDocs) {
    await app.register(swagger, {
      openapi: {
        info: {
          title: 'Banco de Sangue API',
          description: 'Autenticação, perfil do doador, doações e notícias.',
          version: '1.0.0',
        },
        components: {
          securitySchemes: { bearer: { type: 'http', scheme: 'bearer' } },
        },
      },
      transform: jsonSchemaTransform,
    });
    await app.register(swaggerUi, { routePrefix: '/docs' });
  }

  app.setErrorHandler((error, request, reply) => {
    if (hasZodFastifySchemaValidationErrors(error)) {
      return reply.code(400).send({
        error: {
          code: 'validation_error',
          message: error.validation[0]?.message ?? 'Dados inválidos.',
          details: error.validation.map((v) => ({
            path: v.instancePath.replace(/^\//, '').replaceAll('/', '.'),
            message: v.message ?? 'inválido',
          })),
        },
      });
    }
    if (error instanceof HttpError) {
      return reply
        .code(error.statusCode)
        .send({ error: { code: error.code, message: error.message } });
    }
    const status = typeof error === 'object' && error && 'statusCode' in error
      ? Number(error.statusCode)
      : 500;
    if (status === 429) {
      return reply.code(429).send({
        error: { code: 'rate_limited', message: 'Muitas tentativas. Aguarde um minuto.' },
      });
    }
    if (status >= 400 && status < 500) {
      return reply.code(status).send({ error: { code: 'bad_request', message: 'Requisição inválida.' } });
    }
    // Never leak internals: details go to the log only.
    request.log.error(error);
    return reply
      .code(500)
      .send({ error: { code: 'internal', message: 'Erro interno. Tente novamente.' } });
  });

  app.setNotFoundHandler((_request, reply) =>
    reply.code(404).send({ error: { code: 'not_found', message: 'Rota não encontrada.' } }),
  );

  await app.register(authPlugin, { db: full.db, now: full.now });

  app.get('/health', { schema: { hide: true } }, () => ({ status: 'ok' }));
  await app.register(authRoutes, { prefix: '/auth', ...full });
  await app.register(donorRoutes, full);
  await app.register(newsRoutes, { prefix: '/news', ...full });
  await app.register(aiRoutes, { prefix: '/ai', ...full });

  return app;
}
