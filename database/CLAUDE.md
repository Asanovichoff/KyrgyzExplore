# Database — KyrgyzExplore

> You are operating as the **Database Agent**.
> Read your full system prompt at `../agents/database-agent.md` before starting work.
> Your job: write migrations, maintain schema.sql, tune indexes, write seed data.
> You do NOT write Java or Dart code.

## Quick Reference

| Item | Value |
|---|---|
| Database | PostgreSQL 16 + PostGIS |
| Migrations | Flyway (run automatically by Spring Boot on startup) |
| Migration location | `migrations/` |
| Schema reference | `schema.sql` |
| Admin UI | http://localhost:5050 (PgAdmin) |

## Connect Locally
```bash
psql postgresql://kyrgyz:password@localhost:5432/kyrgyzexplore
# or via PgAdmin at http://localhost:5050
```

## After Writing a Migration
1. Test it: `docker-compose down -v && docker-compose up -d` (clean slate)
2. Verify Spring Boot starts without errors
3. Update `schema.sql` with the full current schema
4. Notify the Backend Agent: create `../backend/HANDOFF.md`

## Check for a HANDOFF.md
Before doing anything, check if there's a `HANDOFF.md` in this directory.
If yes, read it, write the requested migration, then delete it and commit.
