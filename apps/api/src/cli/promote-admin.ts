// Grants the admin role (publish news) to an existing account.
// Usage: npm run user:promote -- pessoa@example.com
import { eq } from 'drizzle-orm';

import { loadConfig } from '../config.js';
import { openDatabase } from '../db/client.js';
import { users } from '../db/schema.js';
import { email as emailSchema } from '../schemas.js';

const parsed = emailSchema.safeParse(process.argv[2]);
if (!parsed.success) {
  console.error('Uso: npm run user:promote -- <email>');
  process.exit(1);
}

const db = openDatabase(loadConfig().databasePath);
const result = db.update(users).set({ role: 'admin' }).where(eq(users.email, parsed.data)).run();
console.log(result.changes ? `${parsed.data} agora é administrador.` : 'Conta não encontrada.');
db.$client.close();
process.exit(result.changes ? 0 : 1);
