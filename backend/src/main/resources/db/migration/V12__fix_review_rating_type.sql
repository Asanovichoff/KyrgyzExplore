-- Hibernate maps Java `int` to INTEGER (int4), but V11 created the column as SMALLINT (int2).
-- Schema validation fails on startup with a type mismatch. Widening to INTEGER is safe —
-- all valid rating values (1-5) fit in both types, and the CHECK constraint still applies.
ALTER TABLE reviews ALTER COLUMN rating TYPE INTEGER;
