import { buildApp } from './app.js';
import { loadConfig } from './config.js';
import { openDatabase } from './db/client.js';

const config = loadConfig();
const db = openDatabase(config.databasePath);

const app = await buildApp(
  { config, db },
  {
    logger: {
      level: config.logLevel,
      // Tokens and passwords must never reach the logs.
      redact: ['req.headers.authorization', 'req.body.password', 'req.body.token'],
    },
  },
);

if (config.env === 'production') {
  app.log.warn('Nenhum provedor de e-mail configurado: códigos de redefinição só aparecem no log.');
}

const shutdown = async (signal: string) => {
  app.log.info({ signal }, 'Encerrando');
  await app.close();
  db.$client.close();
  process.exit(0);
};
process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));

await app.listen({ host: config.host, port: config.port });
