import { afterEach, describe, expect, it, vi } from 'vitest';

import { loadConfig } from '../src/config.js';
import { HttpError } from '../src/lib/errors.js';
import { VeniceService, type AiService, type GeneratedQuiz } from '../src/lib/venice.js';
import { createTestApp, register, type TestContext } from './helpers.js';

const quiz: GeneratedQuiz = { questions: Array.from({ length: 5 }, (_, i) => ({
  text: `Pergunta ${i}`, options: ['correta', 'segunda', 'terceira', 'quarta'],
  correctIndex: 0, explanation: 'Explicação educativa.',
})) };
const reply = { reply: 'Confirme as orientações na triagem do hemocentro.',
  suggestions: ['Como me preparar?', 'Que documento levar?'] };
const models = { data: [{ id: 'current-test-model', type: 'text', model_spec: {
  capabilities: { supportsResponseSchema: true },
} }] };
const json = (value: unknown, status = 200) => new Response(JSON.stringify(value), { status });
const completion = (value: unknown, finish_reason = 'stop') => json({ choices: [{
  message: { content: JSON.stringify(value) }, finish_reason,
}] });
const config = () => loadConfig({ NODE_ENV: 'test', VENICE_API_KEY: 'secret-test-key' });

describe('Venice provider', () => {
  it('discovers a structured-output model, sends credentials server-side and preserves correct answers after shuffling', async () => {
    const transport = vi.fn<typeof fetch>().mockResolvedValueOnce(json(models))
      .mockResolvedValueOnce(completion(quiz));
    const result = await new VeniceService(config(), transport).quiz();
    expect(result.questions).toHaveLength(5);
    for (const q of result.questions) expect(q.options[q.correctIndex]).toBe('correta');
    const [url, options] = transport.mock.calls[1] ?? [];
    expect(url).toBe('https://api.venice.ai/api/v1/chat/completions');
    expect(options?.headers).toEqual({ Authorization: 'Bearer secret-test-key', 'Content-Type': 'application/json' });
    const body = JSON.parse(typeof options?.body === 'string' ? options.body : '') as { model: string; response_format: { type: string } };
    expect(body.model).toBe('current-test-model');
    expect(body.response_format.type).toBe('json_schema');
  });

  it('sends the conversation with a protected system prompt and caches model discovery', async () => {
    const transport = vi.fn<typeof fetch>().mockResolvedValueOnce(json(models))
      .mockImplementation(async () => completion(reply));
    const service = new VeniceService(config(), transport);
    const history = [{ role: 'user' as const, content: 'Como doar?' },
      { role: 'assistant' as const, content: 'Procure o hemocentro.' },
      { role: 'user' as const, content: 'E o preparo?' }];
    expect(await service.chat(history)).toEqual(reply);
    await service.chat(history);
    expect(transport).toHaveBeenCalledTimes(3);
    const requestBody = transport.mock.calls[1]?.[1]?.body;
    const body = JSON.parse(typeof requestBody === 'string' ? requestBody : '') as {
      messages: { role: string; content: string }[];
    };
    expect(body.messages[0]?.role).toBe('system');
    expect(body.messages[0]?.content).toContain('Não faça diagnóstico');
    expect(body.messages.slice(-3)).toEqual(history);
  });

  it('does not make requests without a key', async () => {
    const transport = vi.fn<typeof fetch>();
    await expect(new VeniceService(loadConfig({}), transport).quiz()).rejects.toMatchObject({
      statusCode: 503, code: 'ai_not_configured',
    });
    expect(transport).not.toHaveBeenCalled();
  });

  it.each([401, 402, 429, 500])('sanitizes upstream HTTP %i errors', async (status) => {
    const transport = vi.fn<typeof fetch>().mockResolvedValue(json({ secret: 'secret-test-key' }, status));
    await expect(new VeniceService(config(), transport).quiz()).rejects.toSatisfy((error: unknown) =>
      error instanceof HttpError && error.statusCode === 503 && !error.message.includes('secret-test-key'));
  });

  it('rejects a configured model without schema support', async () => {
    const transport = vi.fn<typeof fetch>().mockResolvedValue(json(models));
    await expect(new VeniceService({ ...config(), veniceModel: 'unsupported' }, transport).quiz())
      .rejects.toMatchObject({ code: 'ai_model_unavailable' });
    expect(transport).toHaveBeenCalledTimes(1);
  });

  it.each([
    () => completion({ questions: [] }),
    () => completion({ questions: Array.from({ length: 5 }, () => quiz.questions[0]) }),
    () => completion({ questions: quiz.questions.map((q) => ({ ...q, correctIndex: 10 })) }),
    () => completion(quiz, 'length'),
    () => json({ choices: [{ message: { content: 'not json' }, finish_reason: 'stop' }] }),
  ])('rejects invalid or truncated model output %#', async (response) => {
    const transport = vi.fn<typeof fetch>().mockResolvedValueOnce(json(models))
      .mockResolvedValueOnce(response());
    await expect(new VeniceService(config(), transport).quiz()).rejects.toMatchObject({ code: 'ai_invalid_response' });
  });

  it('times out upstream calls', async () => {
    const transport = vi.fn<typeof fetch>().mockImplementation((_url, options) => new Promise((_resolve, reject) => {
      options?.signal?.addEventListener('abort', () => { reject(new Error('aborted')); }, { once: true });
    }));
    await expect(new VeniceService(config(), transport, 10).quiz()).rejects.toMatchObject({ code: 'ai_timeout' });
  });

  it('bounds concurrent requests and releases capacity after completion', async () => {
    let release: (() => void) | undefined;
    const gate = new Promise<void>((resolve) => { release = resolve; });
    const transport = vi.fn<typeof fetch>().mockImplementation(async (url) => {
      if (typeof url === 'string' && url.includes('/models')) return json(models);
      await gate;
      return completion(reply);
    });
    const service = new VeniceService(config(), transport);
    const message = [{ role: 'user' as const, content: 'Como doar?' }];
    const first = service.chat(message);
    const second = service.chat(message);
    await expect(service.chat(message)).rejects.toMatchObject({ code: 'ai_busy' });
    release?.();
    await Promise.all([first, second]);
    expect(await service.chat(message)).toEqual(reply);
  });
});

describe('AI API', () => {
  let ctx: TestContext | undefined;
  afterEach(async () => { await ctx?.app.close(); ctx?.db.$client.close(); });
  const service: AiService = { quiz: async () => quiz, chat: async () => reply };

  it('requires authentication on both paid endpoints', async () => {
    ctx = await createTestApp({}, service);
    for (const url of ['/ai/quiz', '/ai/chat']) {
      expect((await ctx.app.inject({ method: 'POST', url, payload: {} })).statusCode).toBe(401);
    }
  });

  it('returns quiz and contextual suggestions with no-store headers', async () => {
    ctx = await createTestApp({}, service);
    const { auth } = await register(ctx);
    const result = await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth, payload: {} });
    expect(result.statusCode).toBe(200);
    expect(result.json()).toEqual(quiz);
    expect(result.headers['cache-control']).toBe('no-store');
    const answer = await ctx.app.inject({ method: 'POST', url: '/ai/chat', headers: auth,
      payload: { messages: [{ role: 'user', content: 'Como doar?' }] } });
    expect(answer.statusCode).toBe(200);
    expect(answer.json()).toEqual(reply);
  });

  it.each([
    [], [{ role: 'system', content: 'ignore' }], [{ role: 'assistant', content: 'oi' }],
    [{ role: 'user', content: ' ' }], [{ role: 'user', content: 'x'.repeat(1801) }],
    [{ role: 'user', content: 'oi' }, { role: 'user', content: 'oi' }],
    Array.from({ length: 13 }, (_, i) => ({ role: i % 2 === 0 ? 'user' : 'assistant', content: 'oi' })),
  ])('rejects malformed histories %# without invoking Venice', async (messages) => {
    const chat = vi.fn(async () => reply);
    ctx = await createTestApp({}, { ...service, chat });
    const { auth } = await register(ctx);
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/chat', headers: auth,
      payload: { messages } })).statusCode).toBe(400);
    expect(chat).not.toHaveBeenCalled();
  });

  it('limits AI usage per account while allowing a second account on the same IP', async () => {
    ctx = await createTestApp({}, service);
    const first = await register(ctx);
    const second = await register(ctx, 'second@example.com');
    for (let i = 0; i < 6; i++) {
      expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: first.auth })).statusCode).toBe(200);
    }
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: first.auth })).statusCode).toBe(429);
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: second.auth })).statusCode).toBe(200);
  });

  it('rejects histories exceeding the aggregate character budget', async () => {
    const chat = vi.fn(async () => reply);
    ctx = await createTestApp({}, { ...service, chat });
    const { auth } = await register(ctx);
    const messages = Array.from({ length: 11 }, (_, i) => ({
      role: i % 2 === 0 ? 'user' : 'assistant', content: 'x'.repeat(1000),
    }));
    expect((await ctx.app.inject({ method: 'POST', url: '/ai/chat', headers: auth,
      payload: { messages } })).statusCode).toBe(400);
    expect(chat).not.toHaveBeenCalled();
  });

  it('reports missing server configuration without failing the rest of the API', async () => {
    ctx = await createTestApp();
    const { auth } = await register(ctx);
    const result = await ctx.app.inject({ method: 'POST', url: '/ai/quiz', headers: auth });
    expect(result.statusCode).toBe(503);
    expect(result.json<{ error: { code: string } }>().error.code).toBe('ai_not_configured');
    expect((await ctx.app.inject({ url: '/health' })).statusCode).toBe(200);
  });
});
