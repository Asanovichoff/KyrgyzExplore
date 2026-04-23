-- CHAR(3) was used in V4 for the currency column, but Hibernate maps Java String to VARCHAR.
-- Schema validation fails because PostgreSQL reports CHAR as "bpchar" (Types#CHAR)
-- while Hibernate expects varchar. Changing to VARCHAR(3) aligns DB and entity.
ALTER TABLE listings ALTER COLUMN currency TYPE VARCHAR(3) USING currency::VARCHAR;
