import { z } from 'zod';

const bool = z
  .enum(['true', 'false', '1', '0'])
  .transform((v) => v === 'true' || v === '1');

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  HOST: z.string().default('127.0.0.1'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_PATH: z.string().default('./data/app.db'),
  CORS_ORIGINS: z.string().default(''),
  SESSION_TTL_DAYS: z.coerce.number().int().min(1).max(365).default(30),
  ENABLE_DOCS: bool.optional(),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  TRUST_PROXY: bool.default(false),
});

export interface Config {
  env: 'development' | 'production' | 'test';
  host: string;
  port: number;
  databasePath: string;
  corsOrigins: string[];
  sessionTtlDays: number;
  enableDocs: boolean;
  logLevel: string;
  trustProxy: boolean;
  /** Requests per minute per IP on authentication endpoints. */
  authRateLimit: number;
  /** Requests per minute per IP on every other endpoint. */
  globalRateLimit: number;
}

/** Parses and validates environment variables, failing fast on bad input. */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const parsed = envSchema.safeParse(env);
  if (!parsed.success) {
    throw new Error(`Configuração inválida: ${z.prettifyError(parsed.error)}`);
  }
  const e = parsed.data;
  return {
    env: e.NODE_ENV,
    host: e.HOST,
    port: e.PORT,
    databasePath: e.DATABASE_PATH,
    corsOrigins: e.CORS_ORIGINS.split(',').map((s) => s.trim()).filter(Boolean),
    sessionTtlDays: e.SESSION_TTL_DAYS,
    enableDocs: e.ENABLE_DOCS ?? e.NODE_ENV !== 'production',
    logLevel: e.LOG_LEVEL,
    trustProxy: e.TRUST_PROXY,
    authRateLimit: 10,
    globalRateLimit: 300,
  };
}
