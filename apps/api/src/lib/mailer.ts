import type { FastifyBaseLogger } from 'fastify';

export interface Mailer {
  sendPasswordReset(to: string, token: string): Promise<void>;
}

/**
 * Development mailer: writes the reset token to the server log instead of
 * sending an e-mail. Production needs a real provider implementing [Mailer]
 * (none is configured, to avoid committing to an external paid service).
 */
export class LogMailer implements Mailer {
  constructor(private readonly log: FastifyBaseLogger) {}

  sendPasswordReset(to: string, token: string): Promise<void> {
    this.log.warn({ to, token }, 'Redefinição de senha (LogMailer: e-mail não enviado)');
    return Promise.resolve();
  }
}

/** Collects messages in memory; used by tests. */
export class MemoryMailer implements Mailer {
  readonly sent: { to: string; token: string }[] = [];

  sendPasswordReset(to: string, token: string): Promise<void> {
    this.sent.push({ to, token });
    return Promise.resolve();
  }
}
