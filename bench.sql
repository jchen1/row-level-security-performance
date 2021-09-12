BEGIN;
SET LOCAL jwt.claims.roles TO 'c94a743e-8ffd-42dc-a237-b1613e111f53,be95031e-76e0–401a-808c-5c7acde292de';
-- this represents an example query from an interface
EXPLAIN ANALYZE SELECT count(*) FROM items;
COMMIT;
