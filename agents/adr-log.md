# Architecture Decision Records — KyrgyzExplore

> Maintained by the Architecture Agent.
> All agents must read this before starting any significant work.

---

### ADR-001: Flutter for Cross-Platform Mobile
**Status:** Accepted
**Date:** 2026-04-21
**Deciders:** Architecture Agent

#### Context
Need one codebase for iOS and Android. Primary alternatives: Flutter (Dart) vs React Native (JS/TS).

#### Decision
Use Flutter (stable channel, Dart 3.x).

#### Options Considered
| Option | Pros | Cons |
|--------|------|------|
| Flutter | Native ARM compilation, pixel-perfect UI, official Google Maps plugin, strong typing | Dart learning curve |
| React Native | Larger ecosystem, JS familiarity | JS bridge overhead, community Maps plugin |

#### Consequences
- ✅ Single codebase ships to both stores
- ✅ Smooth 60fps animations for map interactions
- ⚠️ Team must learn Dart if unfamiliar

---

### ADR-002: Spring Boot Modular Monolith for MVP Backend
**Status:** Accepted
**Date:** 2026-04-21
**Deciders:** Architecture Agent

#### Context
Need a backend framework. Team is comfortable with Java. Options: modular monolith vs microservices.

#### Decision
Spring Boot 3.3.x on Java 21, structured as a modular monolith.
Modules: auth, listing, search, booking, payment, messaging, review, notification.
Cross-module communication via Spring ApplicationEvent only.

#### Options Considered
| Option | Pros | Cons |
|--------|------|------|
| Modular monolith | Fast to build, easy to debug, single deploy | Harder to scale individual modules |
| Microservices | Per-service scaling | Over-engineered for MVP team size |

#### Consequences
- ✅ Ship faster with smaller team
- ✅ Easy extraction to microservices later (strangler fig)
- ⚠️ Must enforce module boundaries via ArchUnit tests

---

### ADR-003: PostgreSQL 16 + PostGIS
**Status:** Accepted
**Date:** 2026-04-21
**Deciders:** Architecture Agent + Database Agent

#### Context
Primary data store. Need geospatial query support for location-based listing discovery.

#### Decision
PostgreSQL 16 with PostGIS extension. Redis as complementary cache and pub/sub broker.

#### Consequences
- ✅ ST_DWithin for radius search with GiST indexes
- ✅ JSONB for flexible listing attributes
- ✅ Full ACID compliance for booking + payment transactions
- ⚠️ PostGIS adds setup complexity vs plain PostgreSQL

---

### ADR-004: Spring WebSocket + Redis Pub/Sub for Real-time Chat
**Status:** Accepted
**Date:** 2026-04-21
**Deciders:** Architecture Agent + Backend Agent

#### Context
Real-time host-traveler messaging required for v1.

#### Decision
Spring WebSocket with STOMP protocol. Redis Pub/Sub as message broker relay so multiple
Spring Boot replicas can share chat messages without sticky sessions.

#### Consequences
- ✅ Scales horizontally behind a load balancer
- ✅ SockJS fallback for restrictive networks
- ⚠️ Redis becomes a critical dependency (must monitor uptime)

---

### ADR-005: Stripe + Stripe Connect for Payments
**Status:** Accepted
**Date:** 2026-04-21
**Deciders:** Architecture Agent

#### Decision
Stripe for traveler payments. Stripe Connect for host onboarding and automatic payouts.
Platform takes 30% (configurable via env var). All amounts in KGS tiyin (minor unit).

#### Consequences
- ✅ No PCI compliance burden (card data never touches server)
- ✅ Automatic host payouts after booking completion
- ⚠️ Stripe availability in Kyrgyzstan may require entity in supported country — verify during legal setup

---

### ADR-006: Firebase Cloud Messaging (FCM) for Push Notifications
**Status:** Accepted
**Date:** 2026-04-21

#### Decision
FCM for both iOS and Android push notifications. One SDK, one credential, both platforms.

#### Consequences
- ✅ Free up to 1M notifications/day
- ✅ Single integration point for all push
- ⚠️ Requires Google Play Services on Android (not available on Huawei — defer HMS if needed)

---

### ADR-007: Riverpod for Flutter State Management
**Status:** Accepted
**Date:** 2026-04-21

#### Decision
Riverpod (code generation variant with @riverpod annotation) for all state management in Flutter.

#### Consequences
- ✅ Compile-time safety, testable without widget tree
- ✅ Works outside widgets (providers accessible from other providers)
- ⚠️ build_runner required; adds code generation step to workflow

---

_Next ADR number: ADR-008_
