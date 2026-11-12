import { and, eq, lt, sql } from 'drizzle-orm';
import { z } from 'zod';

import type { Db } from '../db/client.js';
import { aiDailyUsage } from '../db/schema.js';

export const AI_TIME_ZONE = 'America/Sao_Paulo';
export const aiUsageSchema = z.object({
  limit: z.number().int().nonnegative(),
  used: z.number().int().nonnegative(),
  remaining: z.number().int().nonnegative(),
  day: z.string(),
  timeZone: z.literal(AI_TIME_ZONE),
  resetsAt: z.iso.datetime(),
});
export type AiUsage = z.infer<typeof aiUsageSchema>;

const calendar = new Intl.DateTimeFormat('en-CA', {
  timeZone: AI_TIME_ZONE, year: 'numeric', month: '2-digit', day: '2-digit',
});

function dayKey(date: Date): string {
  const parts = calendar.formatToParts(date);
  const part = (type: Intl.DateTimeFormatPartTypes) => parts.find((p) => p.type === type)?.value;
  return `${part('year')}-${part('month')}-${part('day')}`;
}

/** Find the next local midnight using IANA rules, without assuming a UTC offset. */
export function aiDayWindow(now: Date): { day: string; resetsAt: string } {
  const day = dayKey(now);
  let low = Math.floor(now.getTime() / 1000);
  let high = low + 48 * 3600;
  while (high - low > 1) {
    const mid = Math.floor((low + high) / 2);
    if (dayKey(new Date(mid * 1000)) === day) low = mid;
    else high = mid;
  }
  return { day, resetsAt: new Date(high * 1000).toISOString() };
}

function status(used: number, limit: number, window: ReturnType<typeof aiDayWindow>): AiUsage {
  return { ...window, limit, used, remaining: Math.max(0, limit - used), timeZone: AI_TIME_ZONE };
}

export function getAiUsage(db: Db, userId: string, limit: number, now: Date): AiUsage {
  const window = aiDayWindow(now);
  const row = db.select({ used: aiDailyUsage.used }).from(aiDailyUsage)
    .where(and(eq(aiDailyUsage.userId, userId), eq(aiDailyUsage.day, window.day))).get();
  return status(row?.used ?? 0, limit, window);
}

/**
 * A single conditional UPSERT reserves budget BEFORE any external work.
 * SQLite serializes writers across connections/processes; no read/check/write
 * race, no reset on API restart, no trust in client dates, IPs or user IDs.
 * Reservations are not refunded: upstream errors can still incur charges.
 */
export function reserveAiUsage(db: Db, userId: string, limit: number, now: Date): {
  allowed: boolean; usage: AiUsage;
} {
  const window = aiDayWindow(now);
  if (limit === 0) return { allowed: false, usage: getAiUsage(db, userId, limit, now) };
  const rows = db.insert(aiDailyUsage).values({ userId, day: window.day, used: 1 })
    .onConflictDoUpdate({ target: [aiDailyUsage.userId, aiDailyUsage.day],
      set: { used: sql`${aiDailyUsage.used} + 1` }, setWhere: lt(aiDailyUsage.used, limit) })
    .returning({ used: aiDailyUsage.used }).all();
  const row = rows[0];
  return row ? { allowed: true, usage: status(row.used, limit, window) }
    : { allowed: false, usage: getAiUsage(db, userId, limit, now) };
}

export function dailyLimitMessage(usage: AiUsage): string {
  const reset = new Intl.DateTimeFormat('pt-BR', { timeZone: AI_TIME_ZONE,
    day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
  }).format(new Date(usage.resetsAt));
  return `Seu limite diário de ${usage.limit} solicitações de IA foi atingido. `
    + `A cota renova em ${reset} (horário de Brasília).`;
}
