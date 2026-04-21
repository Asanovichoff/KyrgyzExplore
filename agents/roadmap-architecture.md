# KyrgyzExplore — Architecture Agent Roadmap

> This roadmap defines the architectural decisions, contracts, and infra scaffolding
> that must be completed before or alongside each feature phase. The Architecture Agent
> owns everything here. Feature code is built by the Fullstack and Database agents.

---

## Phase 0 — Foundation & Contracts
**Goal:** Establish the architectural baseline so all other agents have a clear contract to work against.

**Deliverables:**
- [x] `agents/architecture.md` — full system design document
- [x] `agents/adr-log.md` — ADR log initialized
- [x] `agents/api-contract.md` — REST + WebSocket contract skeleton
- [x] `infrastructure/docker-compose.yml` — all local services defined
- [x] `infrastructure/.env.example` — all required env vars listed
- [x] `.gitignore` — secrets and build artifacts excluded
- [x] `.github/workflows/ci.yml` — CI pipeline skeleton

**Agents unblocked after this phase:**
- Database Agent can start writing migrations (has schema context)
- Fullstack Agent can scaffold Spring Boot and Flutter projects (has API contract)

---

## Phase 1 — Infrastructure Hardening
**Goal:** Make local dev environment fully runnable with one command.

**Deliverables:**
- [ ] `infrastructure/docker-compose.yml` tested end-to-end (all services start healthy)
- [ ] `infrastructure/setup.sh` installs dependencies and runs migrations
- [ ] Nginx config with routing rules for `/api/v1/`, `/ws/`, static assets
- [ ] PgBouncer config tuned (pool size, transaction mode)
- [ ] Redis config with persistence (AOF) for local dev
- [ ] MailHog wired as SMTP target in `.env.example`
- [ ] ADR-001: Document choice of PgBouncer over direct PostgreSQL connections

**Agents unblocked after this phase:**
- Fullstack Agent can run backend locally against real database and cache
- Database Agent can run Flyway migrations against live PostgreSQL instance

---

## Phase 2 — Security Architecture
**Goal:** Define and document the auth and authorization model before any feature code touches security.

**Deliverables:**
- [ ] ADR-002: JWT (RS256) vs symmetric key — document choice and rotation strategy
- [ ] Define JWT payload structure: `{ sub, role, iat, exp }` — publish to `api-contract.md`
- [ ] Define refresh token strategy in `api-contract.md` (Redis key pattern, TTL, rotation policy)
- [ ] Define RBAC matrix in `api-contract.md`: TRAVELER / HOST / ADMIN permissions per endpoint
- [ ] Review and approve `SecurityConfig.java` once Fullstack Agent writes it
- [ ] ADR-003: Document CORS policy (allowed origins, headers, methods)

**Agents unblocked after this phase:**
- Fullstack Agent can implement auth endpoints with approved security design

---

## Phase 3 — API Contract: Listings & Search
**Goal:** Define all listing and search endpoints before implementation starts.

**Deliverables:**
- [ ] `api-contract.md` — Listings endpoints fully specified:
  - `GET /api/v1/listings` (paginated, filters: type, price, location, dates)
  - `GET /api/v1/listings/{id}`
  - `POST /api/v1/listings` (HOST only)
  - `PUT /api/v1/listings/{id}` (HOST only, own listings)
  - `DELETE /api/v1/listings/{id}` (HOST only, soft delete)
  - `POST /api/v1/listings/images/presign` (S3 pre-signed URL generation)
- [ ] Search query parameter schema defined (lat, lng, radius, type, checkIn, checkOut, minPrice, maxPrice)
- [ ] Listing response envelope schema defined (with pagination metadata)
- [ ] ADR-004: Document PostGIS proximity search approach and GiST index strategy

**Agents unblocked after this phase:**
- Fullstack Agent can implement listing CRUD and search
- Database Agent can finalize listings table and spatial indexes

---

## Phase 4 — API Contract: Bookings & Availability
**Goal:** Define booking lifecycle and availability calendar API before implementation.

**Deliverables:**
- [ ] `api-contract.md` — Bookings endpoints fully specified:
  - `GET /api/v1/listings/{id}/availability`
  - `POST /api/v1/bookings`
  - `GET /api/v1/bookings/{id}`
  - `GET /api/v1/bookings/my` (traveler's bookings)
  - `GET /api/v1/bookings/host` (host's incoming bookings)
  - `PUT /api/v1/bookings/{id}/status` (confirm/cancel)
- [ ] Booking status lifecycle diagram: `PENDING → CONFIRMED → COMPLETED | CANCELLED`
- [ ] Availability conflict detection logic documented
- [ ] ADR-005: Optimistic vs pessimistic locking for concurrent booking — document chosen strategy

**Agents unblocked after this phase:**
- Fullstack Agent can implement booking engine

---

## Phase 5 — API Contract: Payments
**Goal:** Define payment flow and Stripe integration contract.

**Deliverables:**
- [ ] `api-contract.md` — Payments endpoints fully specified:
  - `POST /api/v1/payments/intent` (create Stripe PaymentIntent)
  - `POST /api/v1/payments/confirm` (confirm payment, trigger booking confirmation)
  - `POST /api/v1/payments/webhook` (Stripe webhook handler)
  - `GET /api/v1/payments/onboarding` (Stripe Connect onboarding link for hosts)
  - `GET /api/v1/payments/dashboard` (Stripe Connect dashboard link for hosts)
- [ ] Stripe Connect flow documented (how hosts receive payouts)
- [ ] ADR-006: Platform fee percentage and payout timing (T+1 after checkout)
- [ ] Webhook security: Stripe signature verification requirement documented

**Agents unblocked after this phase:**
- Fullstack Agent can implement payment flow

---

## Phase 6 — API Contract: Messaging & Notifications
**Goal:** Define real-time messaging and push notification contracts.

**Deliverables:**
- [ ] `api-contract.md` — Messaging REST endpoints:
  - `GET /api/v1/messages/threads`
  - `GET /api/v1/messages/threads/{threadId}`
  - `POST /api/v1/messages/threads/{threadId}/messages`
- [ ] WebSocket topics documented:
  - `SUBSCRIBE /topic/chat/{threadId}` — receive messages
  - `SEND /app/chat/{threadId}` — send message
  - `SUBSCRIBE /topic/notifications/{userId}` — real-time alerts
- [ ] Message payload schema defined (threadId, senderId, content, timestamp)
- [ ] ADR-007: WebSocket (STOMP) vs SSE vs polling — document choice

**Agents unblocked after this phase:**
- Fullstack Agent can implement chat and push notifications

---

## Phase 7 — API Contract: Reviews & Admin
**Goal:** Complete the API contract so all features are specified end-to-end.

**Deliverables:**
- [ ] `api-contract.md` — Reviews endpoints:
  - `POST /api/v1/reviews` (only after booking COMPLETED)
  - `GET /api/v1/listings/{id}/reviews`
- [ ] Admin endpoints documented (user management, listing moderation, reporting)
- [ ] Full `api-contract.md` review — ensure no gaps or contradictions

---

## Phase 8 — CI/CD & Production Readiness
**Goal:** Harden the pipeline and define the path to production deployment.

**Deliverables:**
- [ ] `.github/workflows/ci.yml` complete: build, test, lint for both backend and frontend
- [ ] `infrastructure/docker-compose.prod.yml` with production-safe config (no pgadmin, no mailhog)
- [ ] ADR-008: Deployment target (VPS vs managed Kubernetes vs PaaS) — document choice
- [ ] Environment variable checklist reviewed — all secrets accounted for
- [ ] Database backup strategy documented
- [ ] ADR-009: Monitoring and alerting strategy

---

## Architecture Agent Principles (Apply Throughout)

1. **Contract first** — define the interface before either side implements it
2. **ADR every non-obvious choice** — future team members must understand the why
3. **No gold-plating** — don't design for scale that isn't needed yet
4. **Security by default** — auth, input validation, and secrets management are non-negotiable from day 1
5. **One source of truth** — `api-contract.md` is the only place REST/WS contracts live

---

## Dependency Map

```
Phase 0 (Foundation)
    └── Phase 1 (Infra) ─────────────────────────────────┐
    └── Phase 2 (Security) ──────────────────────────────┤
    └── Phase 3 (Listings API contract) ─────────────────┤
        └── Phase 4 (Bookings API contract) ─────────────┤
            └── Phase 5 (Payments API contract) ──────────┤
            └── Phase 6 (Messaging API contract) ──────────► Phase 7 (Reviews + Admin)
                                                                └── Phase 8 (CI/CD + Prod)
```
