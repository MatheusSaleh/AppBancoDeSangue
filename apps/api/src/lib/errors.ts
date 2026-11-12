/** Error with an HTTP status and a message safe to show to the user (pt-BR). */
export class HttpError extends Error {
  constructor(
    readonly statusCode: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

export const unauthorized = () =>
  new HttpError(401, 'unauthorized', 'Sessão inválida ou expirada. Entre novamente.');

export const forbidden = () =>
  new HttpError(403, 'forbidden', 'Você não tem permissão para esta ação.');

export const notFound = (what: string) => new HttpError(404, 'not_found', `${what} não encontrada.`);
