-- Restore missing games from paygame (5).sql without replacing existing data.
-- IDs are generated to avoid collisions with existing games and orders.
-- Safe to run again: existing games, including disabled games, are preserved.
START TRANSACTION;

INSERT INTO games (game_name, category, uid_pattern, requires_server, is_active)
SELECT 'ROV', 'MOBA', '0002', 0, 1
WHERE NOT EXISTS (
    SELECT 1 FROM games WHERE LOWER(TRIM(game_name)) IN ('rov', 'arena of valor')
);

INSERT INTO games (game_name, category, uid_pattern, requires_server, is_active)
SELECT 'PUBG', 'Battle Royal', '003', 1, 1
WHERE NOT EXISTS (
    SELECT 1 FROM games WHERE LOWER(TRIM(game_name)) IN ('pubg', 'pubg mobile')
);

COMMIT;

-- The source archive has no package seed rows. Configure packages and prices
-- in the admin interface before accepting purchases for these games.
