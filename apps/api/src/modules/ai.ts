import type { FastifyReply, FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';

import type { AppDeps } from '../app.js';
import { aiUsageSchema, dailyLimitMessage, getAiUsage, reserveAiUsage } from '../lib/ai-quota.js';
import { HttpError } from '../lib/errors.js';
import { chatInput, chatOutput, quizOutput } from '../lib/venice.js';
import { currentUser } from '../plugins/auth.js';

export const aiRoutes: FastifyPluginAsyncZod<AppDeps> = async (app, { ai, db, now, config: settings }) => {
  const config = { rateLimit: {
    max: 6, timeWindow: '1 minute', hook: 'preHandler' as const,
    keyGenerator: (request: Parameters<typeof currentUser>[0]) => currentUser(request).id,
  } };
  app.addHook('onRequest', app.authenticate);
  app.addHook('onSend', async (request, reply, payload) => {
    reply.header('Cache-Control', 'no-store');
    if (request.authUser) {
      const usage = getAiUsage(db, request.authUser.id, settings.aiDailyLimit, now());
      reply.header('X-AI-Daily-Limit', usage.limit);
      reply.header('X-AI-Daily-Remaining', usage.remaining);
      reply.header('X-AI-Reset-At', usage.resetsAt);
    }
    return payload;
  });
  app.get('/usage', {
    schema: { tags: ['ai'], summary: 'Consulta a própria cota diária sem consumir IA',
      security: [{ bearer: [] }], response: { 200: aiUsageSchema } },
  }, (request) => getAiUsage(db, currentUser(request).id, settings.aiDailyLimit, now()));

  // Fastify validates the body and applies the per-minute limiter first.
  // Both generation endpoints share the same persistent account/day counter.
  const reserve = (request: FastifyRequest, reply: FastifyReply) => {
      const { allowed, usage } = reserveAiUsage(db, currentUser(request).id, settings.aiDailyLimit, now());
      if (!allowed) {
        reply.header('Retry-After', Math.max(1, Math.ceil((Date.parse(usage.resetsAt) - now().getTime()) / 1000)));
        throw new HttpError(429, 'ai_daily_limit_exceeded', dailyLimitMessage(usage));
      }
    };
  app.post('/quiz', {
    config,
    schema: { tags: ['ai'], summary: 'Gera questionário educativo com 5 perguntas',
      security: [{ bearer: [] }], response: { 200: quizOutput } },
  }, (request, reply) => { reserve(request, reply); return ai.quiz(); });
  app.post('/chat', {
    config, bodyLimit: 32 * 1024,
    schema: { tags: ['ai'], summary: 'Responde dúvidas e sugere próximas perguntas',
      security: [{ bearer: [] }], body: chatInput, response: { 200: chatOutput } },
  }, (request, reply) => { reserve(request, reply); return ai.chat(request.body.messages); });
};
