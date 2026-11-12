// Inserts sample news so a fresh database has something to show.
// The articles are explicitly fictitious.
// Usage: npm run seed
import { randomUUID } from 'node:crypto';

import { count } from 'drizzle-orm';

import { loadConfig } from '../config.js';
import { openDatabase } from '../db/client.js';
import { news } from '../db/schema.js';

const db = openDatabase(loadConfig().databasePath);

const existing = db.select({ n: count() }).from(news).get()?.n ?? 0;
if (existing > 0) {
  console.log('Já existem notícias; nada foi inserido.');
} else {
  const now = Date.now();
  db.insert(news)
    .values([
      {
        id: randomUUID(),
        title: 'Exemplo: campanha de inverno',
        summary: 'Notícia fictícia de exemplo, criada pelo script de seed.',
        body: 'Publique notícias reais com POST /news usando uma conta de administrador.',
        publishedAt: new Date(now),
      },
      {
        id: randomUUID(),
        title: 'Exemplo: estoque de O- em alerta',
        summary: 'Notícia fictícia de exemplo.',
        body: '',
        publishedAt: new Date(now - 86_400_000),
      },
    ])
    .run();
  console.log('2 notícias de exemplo inseridas.');
}
db.$client.close();
