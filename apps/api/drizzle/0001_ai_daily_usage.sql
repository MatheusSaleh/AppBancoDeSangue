CREATE TABLE `ai_daily_usage` (
	`user_id` text NOT NULL,
	`day` text NOT NULL,
	`used` integer DEFAULT 0 NOT NULL,
	PRIMARY KEY(`user_id`, `day`),
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "ai_daily_usage_nonnegative" CHECK("ai_daily_usage"."used" >= 0)
);
