# Multi-Agent Workflow Guide — KyrgyzExplore

## Overview

This project uses **three specialized Claude Code agents**. Each agent has deep expertise in
its domain and passes work to other agents via `HANDOFF.md` files.

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE AGENT                           │
│  Designs systems · Writes ADRs · Owns API contract · Reviews    │
└──────────┬──────────────────────────────────────┬──────────────┘
           │ defines schema                        │ defines API contract
           ▼                                       ▼
┌──────────────────────┐            ┌─────────────────────────────┐
│    DATABASE AGENT    │            │      FULLSTACK AGENT        │
│                      │──schema──▶ │                             │
│  Migrations          │            │  Spring Boot API (Java 21)  │
│  Schema              │            │  Flutter App (iOS + Android)│
│  Indexes · Seeds     │            │  WebSocket · Stripe · Maps  │
└──────────────────────┘            └─────────────────────────────┘
```

---

## How to Start an Agent Session

Open a terminal in the project root, then:

```bash
# Architecture Agent — use from project root
claude --system-prompt agents/architecture-agent.md

# Fullstack Agent — use from project root (works across backend/ and frontend/)
claude --system-prompt agents/fullstack-agent.md

# Database Agent — use from database/ directory
cd database
claude --system-prompt ../agents/database-agent.md
```

> Each agent reads the project CLAUDE.md automatically (it's at the root).
> The agent prompt gives it domain-specific rules on top of the shared context.

---

## Shared Files (All Agents Must Know These)

| File | Owner | Purpose |
|------|-------|---------|
| `CLAUDE.md` | Architecture | Project overview, tech stack, conventions |
| `agents/api-contract.md` | Architecture | REST + WebSocket contract |
| `agents/adr-log.md` | Architecture | All architecture decisions |
| `database/schema.sql` | Database | Canonical full schema |

---

## The HANDOFF.md Protocol

When work crosses an agent boundary, the sending agent creates a `HANDOFF.md` in the
receiving agent's directory. The receiving agent checks for it at the start of every session.

### Template
```markdown
## Handoff: [Feature Name]
**From:** [Sending Agent]
**To:** [Receiving Agent]
**Date:** YYYY-MM-DD
**Priority:** High | Normal | Low

### Context
[Brief background on why this is needed]

### What to Build / Do
[Specific instructions — be precise]

### Inputs / Dependencies
[Files to read, endpoints to implement, schema to use]

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

### Do NOT Change
[Scope boundaries]

### Notify When Done
Create `HANDOFF.md` in [next agent directory] when complete.
```

### Example Flow: Adding a New Feature (e.g., Activity Bookings)

```
Architecture Agent
  → Updates api-contract.md with new endpoints
  → Creates database/HANDOFF.md: "Add activity_bookings table"

Database Agent (reads HANDOFF.md)
  → Writes V8__activity_bookings.sql
  → Updates schema.sql
  → Deletes database/HANDOFF.md
  → Creates HANDOFF.md at project root: "Migration ready, implement booking feature"

Fullstack Agent (reads HANDOFF.md)
  → Implements Spring Boot: BookingController, BookingService, BookingRepository, tests
  → Implements Flutter: booking flow screens, providers, widget tests
  → Deletes HANDOFF.md
  → Feature complete — creates PR
```

---

## Typical Work Sequences

### New Feature (full stack)
1. **Architecture** → ADR + API contract update + Database HANDOFF
2. **Database** → Migration + root HANDOFF.md for Fullstack Agent
3. **Fullstack** → Spring Boot API + Flutter UI + PR

### Code-only change (no schema change)
1. Fullstack Agent works directly — no HANDOFF needed

### Schema change only
1. Database Agent writes migration
2. Database Agent creates root HANDOFF.md if new columns affect queries

### API contract change
1. Architecture Agent MUST update `api-contract.md` first
2. Architecture Agent creates root HANDOFF.md for Fullstack Agent

---

## Rules for All Agents

1. **Always read `agents/adr-log.md` before starting** — don't violate existing decisions
2. **Always check for a `HANDOFF.md`** in your directory at session start
3. **Don't change another agent's files** without a HANDOFF
4. **Keep `api-contract.md` as the source of truth** — code follows the contract, never the reverse
5. **Commit after every meaningful unit of work** — small, clear commits
6. **Never commit secrets** — the pre-commit hook will block `.env` files

---

## Current Feature Status

> Update this table as features are built.

| Feature | Database | Backend | Frontend | Status |
|---------|----------|---------|----------|--------|
| Auth (email + OAuth) | ⬜ | ⬜ | ⬜ | Not started |
| Listing CRUD | ⬜ | ⬜ | ⬜ | Not started |
| Photo upload | ⬜ | ⬜ | ⬜ | Not started |
| Search & Discovery | ⬜ | ⬜ | ⬜ | Not started |
| Booking Engine | ⬜ | ⬜ | ⬜ | Not started |
| Stripe Payments | ⬜ | ⬜ | ⬜ | Not started |
| Real-time Chat | ⬜ | ⬜ | ⬜ | Not started |
| Push Notifications | ⬜ | ⬜ | ⬜ | Not started |
| Reviews | ⬜ | ⬜ | ⬜ | Not started |

Legend: ⬜ Not started · 🟡 In progress · ✅ Done
