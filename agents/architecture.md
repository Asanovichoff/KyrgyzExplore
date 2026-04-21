# KyrgyzExplore — System Architecture

## 1. System Overview

KyrgyzExplore is a travel marketplace for Kyrgyzstan. Travelers can browse and book **houses**
(accommodations), **cars** (vehicle rentals), and **activities** (experiences, tours, hikes).
Hosts publish and manage listings. One admin panel oversees the platform.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                                    │
│                                                                         │
│   ┌──────────────────────────────────────────────────────────────┐      │
│   │  Flutter Mobile App (iOS + Android)                          │      │
│   │  Riverpod (state) · Dio (HTTP) · google_maps_flutter (maps)  │      │
│   └──────────────────────────┬───────────────────────────────────┘      │
└──────────────────────────────┼──────────────────────────────────────────┘
                               │ HTTPS / WSS
┌──────────────────────────────▼──────────────────────────────────────────┐
│                         INGRESS LAYER                                   │
│                                                                         │
│   ┌──────────────────────────────────────────────────────────────┐      │
│   │  Nginx (reverse proxy, TLS termination, rate limiting)       │      │
│   └──────────────────────────┬───────────────────────────────────┘      │
└──────────────────────────────┼──────────────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────────────┐
│                         APPLICATION LAYER                               │
│                                                                         │
│   ┌──────────────────────────────────────────────────────────────┐      │
│   │  Spring Boot 3.3.x  (Java 21)                                │      │
│   │                                                              │      │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │      │
│   │  │  REST API   │  │  WebSocket  │  │  Async Workers      │  │      │
│   │  │  (HTTPS)    │  │  (STOMP/WS) │  │  (email, push, pay) │  │      │
│   │  └─────────────┘  └─────────────┘  └─────────────────────┘  │      │
│   │                                                              │      │
│   │  Spring Security (JWT) · Spring Data JPA · Spring WebSocket  │      │
│   └──────────────────────────────────────────────────────────────┘      │
└──────────┬──────────────────────┬───────────────────────────────────────┘
           │                      │
┌──────────▼──────────┐  ┌────────▼───────────────────────────────────────┐
│   DATA LAYER        │  │  EXTERNAL SERVICES                             │
│                     │  │                                                │
│  ┌───────────────┐  │  │  ┌──────────┐  ┌────────────┐  ┌──────────┐   │
│  │ PostgreSQL 16 │  │  │  │  Stripe  │  │  AWS S3    │  │  FCM     │   │
│  │  + PostGIS    │  │  │  │  Connect │  │  (images)  │  │  (push)  │   │
│  └───────────────┘  │  │  └──────────┘  └────────────┘  └──────────┘   │
│  ┌───────────────┐  │  │  ┌──────────┐                                 │
│  │  PgBouncer    │  │  │  │ SendGrid │                                 │
│  │  (conn pool)  │  │  │  │  (email) │                                 │
│  └───────────────┘  │  │  └──────────┘                                 │
│  ┌───────────────┐  │  └────────────────────────────────────────────────┘
│  │  Redis 7.x    │  │
│  │  (sessions,   │  │
│  │   pub/sub,    │  │
│  │   rate limit) │  │
│  └───────────────┘  │
└─────────────────────┘
```

---

## 2. Component Breakdown

### 2.1 Flutter Mobile App
| Concern | Solution |
|---|---|
| State management | Riverpod (providers per feature) |
| HTTP client | Dio with interceptors (auth token, retry) |
| Navigation | go_router (declarative, deep links) |
| Maps | google_maps_flutter |
| Image upload | S3 pre-signed URL (upload direct from device) |
| Push notifications | firebase_messaging package |
| Local storage | flutter_secure_storage (token), shared_preferences (prefs) |

**Feature modules (each has its own screens + providers):**
- `auth/` — login, register, forgot password
- `listings/` — browse, detail, create, edit
- `search/` — filters, map view, results
- `bookings/` — calendar, checkout, booking history
- `payments/` — Stripe payment sheet
- `chat/` — WebSocket messaging thread
- `reviews/` — post and view reviews
- `profile/` — user profile, host dashboard
- `notifications/` — notification centre

---

### 2.2 Spring Boot Backend

**Package structure:**
```
com.kyrgyzexplore/
├── config/          — SecurityConfig, WebSocketConfig, RedisConfig, S3Config
├── auth/            — AuthController, JwtService, UserDetailsServiceImpl
├── user/            — UserController, UserService, UserRepository
├── listing/         — ListingController, ListingService, ListingRepository
├── booking/         — BookingController, BookingService, BookingRepository
├── payment/         — PaymentController, StripeService, PayoutService
├── message/         — MessageController, ChatService, MessageRepository
├── review/          — ReviewController, ReviewService, ReviewRepository
├── notification/    — NotificationController, FcmService
├── search/          — SearchController, SearchService (PostGIS queries)
├── admin/           — AdminController, AdminService
└── common/          — BaseEntity, PagedResponse, ErrorResponse, enums/
```

**Key Spring Boot patterns:**
- All controllers return `ResponseEntity<ApiResponse<T>>`
- Services contain all business logic — controllers are thin
- Repositories extend `JpaRepository` + custom `@Query` for PostGIS
- Global exception handler via `@RestControllerAdvice`
- DTOs separate from JPA entities — MapStruct for mapping

---

### 2.3 PostgreSQL + PostGIS

Core tables: `users`, `listings`, `listing_images`, `availabilities`, `bookings`,
`payments`, `messages`, `reviews`, `notifications`, `refresh_tokens`

PostGIS `GEOMETRY(Point, 4326)` column on `listings.location` enables:
- Proximity search (`ST_DWithin`)
- Bounding box map queries (`ST_Within`)
- Distance sorting (`ST_Distance`)

Flyway manages all schema changes. PgBouncer pools connections (transaction mode).

---

### 2.4 Redis

| Use case | Key pattern | TTL |
|---|---|---|
| JWT refresh token store | `refresh:{userId}` | 30 days |
| Rate limiting | `rate:{ip}:{endpoint}` | 1 minute |
| Session cache | `session:{token}` | 15 minutes |
| Pub/Sub for WebSocket | channel: `chat:{threadId}` | — |
| Listing view counter | `views:{listingId}` | — |

---

### 2.5 Nginx

```nginx
# Routing rules
/api/v1/*        → Spring Boot :8080
/ws/*            → Spring Boot :8080 (WebSocket upgrade)
/                → Flutter web build (if enabled)

# Features enabled
- TLS termination (Let's Encrypt)
- Gzip compression
- Rate limiting (10 req/s per IP on auth endpoints)
- CORS headers
- Request size limit (10MB for image uploads)
```

---

## 3. Core User Journey Data Flows

### 3.1 Browse & Book Flow
```
Flutter                  Spring Boot              PostgreSQL
  │                           │                       │
  ├── GET /listings?lat=&lng= ──►                      │
  │                           ├── ST_DWithin query ──►│
  │                           │◄── listing rows ───────┤
  │◄── ListingPageResponse ───┤                       │
  │                           │                       │
  ├── GET /listings/{id} ─────►                      │
  │◄── ListingDetailResponse ─┤                       │
  │                           │                       │
  ├── GET /listings/{id}/availability?month= ─────────►
  │◄── AvailabilityResponse ──┤                       │
  │                           │                       │
  ├── POST /bookings ─────────►                      │
  │   { listingId, dates }    ├── create booking ───►│
  │                           ├── create PaymentIntent│
  │◄── { clientSecret } ──────┤    (Stripe)           │
  │                           │                       │
  ├── [Stripe Payment Sheet]  │                       │
  ├── POST /payments/confirm ─►                      │
  │                           ├── confirm booking ──►│
  │                           ├── send email (SendGrid)│
  │                           ├── send push (FCM) ────►FCM
  │◄── BookingResponse ───────┤                       │
```

### 3.2 Host Listing Creation Flow
```
Flutter                  Spring Boot              AWS S3
  │                           │                    │
  ├── POST /listings/images/presign ──►            │
  │◄── { presignedUrl, key } ─┤                    │
  │                           │                    │
  ├── PUT {presignedUrl} ──────────────────────────►
  │◄── 200 OK ─────────────────────────────────────┤
  │                           │                    │
  ├── POST /listings ─────────►                   │
  │   { type, title, price,   ├── save listing    │
  │     imageKeys[], location }├── geocode location│
  │◄── ListingResponse ───────┤                    │
```

### 3.3 Payment & Payout Flow
```
Flutter        Spring Boot        Stripe           Host Bank
  │                │                │                 │
  │ POST /bookings │                │                 │
  ├───────────────►│                │                 │
  │                ├─ createPaymentIntent ──────────► │
  │                │◄── clientSecret ────────────────┤│
  │◄── clientSecret┤                │                 │
  │                │                │                 │
  │ [Payment Sheet]│                │                 │
  ├─ confirmPayment────────────────►│                 │
  │                │                │                 │
  │                │◄── webhook: payment_intent.succeeded
  │                ├─ confirm booking                 │
  │                ├─ schedule payout (T+1 after checkout)
  │                ├─────────────── transfer ────────►│
```

---

## 4. Security Architecture

### Authentication
- **Registration/Login** → returns short-lived JWT (15 min) + long-lived refresh token (30 days)
- **JWT** is RS256 signed, stored in flutter_secure_storage on device
- **Refresh token** stored in Redis with `refresh:{userId}` key, rotated on each use
- **Logout** invalidates refresh token in Redis

### Authorization
| Role | Can do |
|---|---|
| `TRAVELER` | Browse, book, message hosts, write reviews, manage own profile |
| `HOST` | Everything TRAVELER can + create/edit listings, manage availability, receive payouts |
| `ADMIN` | Full read/write access, can suspend users and listings |

- Spring Security `@PreAuthorize` on all sensitive endpoints
- Host-only listing mutations verified: `listing.hostId == currentUser.id`
- Booking access verified: `booking.travelerId == currentUser.id OR booking.listing.hostId == currentUser.id`

### Input Validation
- All request bodies validated with `@Valid` + Jakarta Bean Validation annotations
- File uploads: type checked (image/jpeg, image/png only), max 10MB
- SQL injection: all queries use JPA parameterized statements or Spring Data method names

---

## 5. Infrastructure Layout (Docker Compose)

```
Services (docker-compose.yml):
┌─────────────────────────────────────────────────────────┐
│  nginx          :80, :443                               │
│  backend        :8080  (Spring Boot JAR)                │
│  postgres       :5432  (PostgreSQL 16 + PostGIS)        │
│  pgbouncer      :6432  (connection pooler → postgres)   │
│  redis          :6379                                   │
│  pgadmin        :5050  (dev only)                       │
│  mailhog        :8025  (dev email catcher)              │
└─────────────────────────────────────────────────────────┘

Networks:
- backend-net: backend ↔ pgbouncer ↔ redis
- db-net: pgbouncer ↔ postgres

Volumes:
- postgres-data
- redis-data
```

---

## 6. API Design Principles

- **Versioned:** all routes prefixed `/api/v1/`
- **RESTful resources:** nouns not verbs (`/bookings` not `/createBooking`)
- **Consistent envelope:** `{ "success": true, "data": {...}, "error": null }`
- **Pagination:** cursor-based for listings/search, offset for admin
- **Error codes:** machine-readable codes alongside HTTP status (`LISTING_NOT_FOUND`, `BOOKING_OVERLAP`)
- **WebSocket topics:** `/topic/chat/{threadId}` for messages, `/topic/notifications/{userId}` for push

---

## 7. Scalability Notes

| Concern | Current approach | Scale path |
|---|---|---|
| DB connections | PgBouncer (transaction mode) | Increase pool size, read replicas |
| Search latency | PostGIS GiST index | Add Elasticsearch if needed |
| Image delivery | S3 signed URLs | Add CloudFront CDN |
| Real-time chat | Single Spring Boot node + Redis pub/sub | Add Redis Cluster + multiple app nodes |
| Background jobs | Spring `@Async` | Migrate to dedicated job queue (e.g. Quartz) |
| Rate limiting | Redis counters in Nginx | Already horizontally scalable |
