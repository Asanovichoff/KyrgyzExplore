# Backend — KyrgyzExplore API

> You are operating as the **Fullstack Agent** (backend half).
> Read your full system prompt at `../agents/fullstack-agent.md` before starting work.
> Read the API contract at `../agents/api-contract.md` — implement what's there, no more.
> Read the DB schema at `../database/schema.sql` — use it, don't rewrite it.

## Quick Reference

| Item | Value |
|---|---|
| Language | Java 21 |
| Framework | Spring Boot 3.3.x |
| Build | Maven (`./mvnw`) |
| Package root | `com.kyrgyzexplore` |
| Port | 8080 |
| Swagger UI | http://localhost:8080/api/docs |

## Run Locally
```bash
# Prereq: docker-compose up -d (from ../infrastructure/)
./mvnw spring-boot:run
```

## Run Tests
```bash
./mvnw test                         # all tests (Testcontainers spins up real DB+Redis)
./mvnw test -Dtest=BookingServiceTest  # single test
./mvnw verify                       # tests + coverage report
```

## Check for a HANDOFF.md
Before doing anything, check if there's a `HANDOFF.md` in this directory.
If yes, read it, complete the task, then delete it and commit.
