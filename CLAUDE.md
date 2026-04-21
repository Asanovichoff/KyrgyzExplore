# KyrgyzExplore — Project Intelligence

## What This Project Is
KyrgyzExplore is a cross-platform mobile app (iOS + Android) for travelers visiting Kyrgyzstan.
It lets travelers book **car rentals**, **accommodations**, and **local activities**, and lets
hosts publish and manage their listings. Think Airbnb + Turo, built for Kyrgyzstan.

---

## Multi-Agent Workflow

This project uses **three specialized Claude Code agents**. Each owns a domain and has its own
`CLAUDE.md` in its subdirectory. When working on a task, route it to the right agent.

| Agent | Invoke with | Owns |
|---|---|---|
| Architecture | `agents/architecture-agent.md` | ADRs, cross-cutting design, API contracts |
| Fullstack | `agents/fullstack-agent.md` | `backend/` + `frontend/` — Spring Boot API & Flutter app |
| Database | `agents/database-agent.md` | `database/` — Migrations, schema, queries |

### How Agents Coordinate
- **Shared contract file:** `agents/api-contract.md` — Architecture Agent writes it, Fullstack Agent implements it.
- **Shared schema file:** `database/schema.sql` — Database Agent owns it, Fullstack Agent reads it.
- **ADR log:** `agents/adr-log.md` — Architecture Agent maintains it; all agents read it.
- **Task handoffs:** Leave a `HANDOFF.md` in the relevant directory when work crosses agent boundaries.

To spawn a subagent task in Claude Code:
```
Use the Task tool with the agent's system prompt loaded from agents/<name>-agent.md
```

---

## Tech Stack (Do Not Change Without an ADR)

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart 3.x), Riverpod, Dio, google_maps_flutter |
| Backend | Spring Boot 3.3.x, Java 21, Spring Security, Spring WebSocket |
| Database | PostgreSQL 16 + PostGIS, Flyway migrations, PgBouncer |
| Cache | Redis 7.x (sessions, pub/sub, rate limit counters) |
| Payments | Stripe + Stripe Connect |
| Push | Firebase Cloud Messaging (FCM) |
| Storage | AWS S3 (images), signed URLs |
| Email | SendGrid |
| Infra | Docker, Nginx, GitHub Actions CI/CD |

---

## Project Structure

```
kyrgyzexplore/
├── CLAUDE.md                  ← you are here
├── agents/                    ← agent prompts & shared contracts
│   ├── architecture-agent.md
│   ├── backend-agent.md
│   ├── frontend-agent.md
│   ├── database-agent.md
│   ├── api-contract.md        ← REST + WebSocket contract (auto-generated)
│   └── adr-log.md             ← Architecture Decision Records
├── backend/                   ← Spring Boot application
│   ├── CLAUDE.md
│   └── src/...
├── frontend/                  ← Flutter application
│   ├── CLAUDE.md
│   └── lib/...
├── database/                  ← SQL migrations and schema
│   ├── CLAUDE.md
│   └── migrations/
└── infrastructure/            ← Docker, CI/CD, cloud config
    ├── docker-compose.yml
    ├── docker-compose.prod.yml
    ├── .env.example
    └── setup.sh
```

---

## Universal Coding Standards (All Agents Must Follow)

### Git
- Branch naming: `feat/<agent>/<short-description>` (e.g. `feat/backend/booking-engine`)
- Commit format: `[scope] verb: description` (e.g. `[backend] add: booking availability check`)
- Never commit `.env` files, secrets, or API keys
- PR requires passing CI before merge

### Code Quality
- No commented-out code — delete it or file a TODO with a ticket reference
- All public methods must have doc comments
- Tests live next to the code they test (`*Test.java` for backend, `*_test.dart` for frontend)

### Security
- Never log sensitive data (passwords, tokens, card info)
- All user input must be validated before processing
- Database queries must use parameterized statements (no string concatenation)

### Environment Variables
- All config comes from environment variables — never hardcode URLs, keys, or secrets
- Use `.env.example` as the template; copy to `.env` for local dev (`.env` is gitignored)

---

## Running Locally

```bash
# 1. Clone & configure
cp infrastructure/.env.example infrastructure/.env
# Fill in STRIPE_SECRET, FIREBASE credentials, etc.

# 2. Start all infrastructure
cd infrastructure
docker-compose up -d

# 3. Backend (in a new terminal)
cd backend
./mvnw spring-boot:run

# 4. Frontend (in a new terminal)
cd frontend
flutter run

# Services:
# Backend API:  http://localhost:8080
# PgAdmin:      http://localhost:5050
# MailHog:      http://localhost:8025
# Redis:        localhost:6379
```

---

## Key Contacts & Resources
- Architecture doc: `KyrgyzExplore_Architecture_v1.docx`
- API contract: `agents/api-contract.md`
- ADR log: `agents/adr-log.md`
- Stripe dashboard: https://dashboard.stripe.com
- Firebase console: https://console.firebase.google.com
- GitHub repo: (set after repo creation)
