import { sql } from 'drizzle-orm';
import { index, integer, sqliteTable, text } from 'drizzle-orm/sqlite-core';

const timestamps = {
  createdAt: integer('created_at', { mode: 'timestamp_ms' })
    .notNull()
    .default(sql`(unixepoch('subsec') * 1000)`),
};

/** Account + donor profile (1:1, so they share the table). */
export const users = sqliteTable('users', {
  id: text('id').primaryKey(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  role: text('role', { enum: ['user', 'admin'] }).notNull().default('user'),
  name: text('name').notNull().default(''),
  sex: text('sex', { enum: ['masculino', 'feminino'] }),
  bloodType: text('blood_type'),
  ...timestamps,
});

/** Opaque bearer tokens. Only the SHA-256 hash is stored. */
export const sessions = sqliteTable(
  'sessions',
  {
    id: text('id').primaryKey(),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    tokenHash: text('token_hash').notNull().unique(),
    expiresAt: integer('expires_at', { mode: 'timestamp_ms' }).notNull(),
    ...timestamps,
  },
  (t) => [index('sessions_user_idx').on(t.userId)],
);

/** Single-use password reset tokens (hashed, short-lived). */
export const passwordResets = sqliteTable(
  'password_resets',
  {
    id: text('id').primaryKey(),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    tokenHash: text('token_hash').notNull().unique(),
    expiresAt: integer('expires_at', { mode: 'timestamp_ms' }).notNull(),
    usedAt: integer('used_at', { mode: 'timestamp_ms' }),
    ...timestamps,
  },
  (t) => [index('password_resets_user_idx').on(t.userId)],
);

export const donations = sqliteTable(
  'donations',
  {
    id: text('id').primaryKey(),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    /** Calendar date `YYYY-MM-DD`: donation rules work on days, not instants. */
    date: text('date').notNull(),
    location: text('location').notNull().default(''),
    notes: text('notes').notNull().default(''),
    ...timestamps,
    updatedAt: integer('updated_at', { mode: 'timestamp_ms' }),
  },
  (t) => [index('donations_user_date_idx').on(t.userId, t.date)],
);

export const news = sqliteTable('news', {
  id: text('id').primaryKey(),
  title: text('title').notNull(),
  summary: text('summary').notNull().default(''),
  body: text('body').notNull().default(''),
  publishedAt: integer('published_at', { mode: 'timestamp_ms' }).notNull(),
  createdBy: text('created_by').references(() => users.id, { onDelete: 'set null' }),
});
