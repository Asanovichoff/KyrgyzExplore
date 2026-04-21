-- V1: Install required PostgreSQL extensions.
-- This must be the first migration — all other migrations depend on uuid-ossp and postgis.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "citext";
