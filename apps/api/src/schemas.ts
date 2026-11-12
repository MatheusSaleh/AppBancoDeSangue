import { z } from 'zod';

/** Shared request/response schemas. Response schemas also act as an
 * allow-list: fields not declared here (e.g. password hashes) are never
 * serialized. */

export const email = z
  .string()
  .trim()
  .toLowerCase()
  .max(254)
  .pipe(z.email({ error: 'E-mail inválido.' }));

// Upper bound prevents abuse of the (deliberately slow) password hash.
export const password = z
  .string()
  .min(8, { error: 'A senha deve ter pelo menos 8 caracteres.' })
  .max(128, { error: 'A senha deve ter no máximo 128 caracteres.' });

export const credentials = z.object({ email, password });

export const sex = z.enum(['masculino', 'feminino']);
export const bloodType = z.enum(['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+']);

export const isoDate = z.iso.date({ error: 'Data inválida (use AAAA-MM-DD).' });

export const user = z.object({
  id: z.string(),
  email: z.string(),
  role: z.enum(['user', 'admin']),
});

export const session = z.object({
  token: z.string(),
  expiresAt: z.iso.datetime(),
  user,
});

export const profile = z.object({
  name: z.string().trim().max(100),
  sex: sex.nullable(),
  bloodType: bloodType.nullable(),
});

export const donationInput = z.object({
  date: isoDate,
  location: z.string().trim().max(80).default(''),
  notes: z.string().trim().max(280).default(''),
});

export const donation = donationInput.extend({ id: z.string() });

export const newsInput = z.object({
  title: z.string().trim().min(1).max(140),
  summary: z.string().trim().max(500).default(''),
  body: z.string().trim().max(5000).default(''),
});

export const newsArticle = newsInput.extend({
  id: z.string(),
  publishedAt: z.iso.datetime(),
});

/** Empty body for 202/204 responses. */
export const noContent = z.null();

export const idParam = z.object({ id: z.uuid() });

export const errorBody = z.object({
  error: z.object({
    code: z.string(),
    message: z.string(),
    details: z.array(z.object({ path: z.string(), message: z.string() })).optional(),
  }),
});
