-- V3: Enforce case-insensitive email uniqueness at the database level.
--
-- WHY this matters:
-- V2 added a standard UNIQUE constraint on email (VARCHAR). That only catches
-- exact duplicates. Without this index, 'User@example.com' and 'user@example.com'
-- are treated as different emails and both get inserted — two accounts for the
-- same person, and neither can log in with certainty.
--
-- The app normalizes email to lowercase before saving, but relying on app code
-- alone is fragile. Any future code path that forgets .toLowerCase() silently
-- breaks this invariant. The DB must enforce it independently.
--
-- HOW it works:
-- PostgreSQL supports functional indexes — indexes built on the result of a
-- function, not just a raw column value. LOWER(email) computes the lowercase
-- version, and UNIQUE ensures no two rows share the same lowercased email.
-- The original UNIQUE on the raw column stays as a secondary safeguard.

CREATE UNIQUE INDEX ux_users_email_lower ON users (LOWER(email));
