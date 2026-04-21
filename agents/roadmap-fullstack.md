# KyrgyzExplore — Fullstack Agent Roadmap

> This roadmap covers all Spring Boot (backend) and Flutter (frontend) work phase by phase.
> The Fullstack Agent owns `backend/` and `frontend/`. Database migrations are owned by the
> Database Agent — backend never modifies `database/` directly.

---

## Phase 1 — Project Scaffold
**Goal:** Get both Spring Boot and Flutter apps running locally with no features yet.

### Backend tasks
- Initialize Spring Boot project (Spring Initializr): Web, Security, Data JPA, WebSocket, Validation, Actuator, Lombok
- `pom.xml`: add MapStruct, Flyway, PostgreSQL driver, Redis, Stripe SDK, AWS S3 SDK, Firebase Admin SDK
- Base package structure: `config/`, `auth/`, `user/`, `listing/`, `booking/`, `payment/`, `message/`, `review/`, `notification/`, `search/`, `admin/`, `common/`
- `BaseEntity.java`: `id (UUID)`, `createdAt`, `updatedAt` with `@MappedSuperclass`
- `ApiResponse.java`: generic envelope `{ success, data, error, errorCode }`
- `GlobalExceptionHandler.java`: `@RestControllerAdvice` handling validation, not-found, unauthorized
- `application.yml`: read all config from env vars (DB URL, Redis, JWT secret, S3, Stripe)
- `HealthController.java`: `GET /api/v1/health` returns 200 — smoke test endpoint

### Frontend tasks
- Initialize Flutter project: `flutter create kyrgyz_explore --org com.kyrgyzexplore`
- Add dependencies to `pubspec.yaml`: `riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `google_maps_flutter`, `firebase_core`, `firebase_messaging`, `cached_network_image`, `intl`
- Folder structure: `lib/core/`, `lib/features/auth/`, `lib/features/listings/`, `lib/features/bookings/`, `lib/features/chat/`, `lib/features/profile/`
- `ApiClient` (Dio): base URL from env, auth interceptor (attach JWT), retry interceptor
- `AppRouter` (go_router): skeleton routes for all screens, redirect to login if unauthenticated
- `AppTheme`: colors, typography, spacing constants

### Dependencies
- Docker Compose running (PostgreSQL, Redis)
- Database Agent: V1 migration (users table) must exist before backend starts

### Definition of done
- `GET /api/v1/health` returns 200
- Flutter app builds and shows a placeholder home screen on iOS simulator and Android emulator

---

## Phase 2 — Authentication
**Goal:** Users can register, log in, and the app stores their JWT securely.

### Backend tasks
- `User.java` entity: `id`, `email`, `passwordHash`, `role (TRAVELER|HOST)`, `firstName`, `lastName`, `profileImageUrl`, `isActive`, `createdAt`, `updatedAt`
- `UserRepository.java`: `findByEmail()`
- `JwtService.java`: RS256 sign/verify, extract claims, `generateAccessToken()`, `generateRefreshToken()`
- `AuthController.java`:
  - `POST /api/v1/auth/register` → hash password, save user, return tokens
  - `POST /api/v1/auth/login` → verify password, return tokens
  - `POST /api/v1/auth/refresh` → validate refresh token from Redis, rotate and return new tokens
  - `POST /api/v1/auth/logout` → delete refresh token from Redis
- `SecurityConfig.java`: public routes (register, login, refresh), protected everything else
- `UserDetailsServiceImpl.java`: load user by email for Spring Security
- `RefreshTokenService.java`: store/retrieve/delete tokens in Redis with 30-day TTL
- `UserController.java`: `GET /api/v1/users/me`, `PUT /api/v1/users/me`

### Frontend tasks
- `AuthRepository`: register, login, logout, refresh API calls
- `AuthProvider` (Riverpod): manage auth state (authenticated / unauthenticated / loading)
- `LoginScreen`: email + password form, error display, navigate to home on success
- `RegisterScreen`: name, email, password, role selection (TRAVELER/HOST)
- `SecureStorageService`: save/read/delete JWT and refresh token
- Auto-refresh: Dio interceptor checks token expiry, calls refresh endpoint before retrying

### Dependencies
- Architecture Agent: JWT payload structure and refresh token strategy from `api-contract.md`
- Database Agent: V1 migration (users + refresh_tokens tables)

### Definition of done
- User can register, log in, and stay logged in across app restarts
- Expired token is automatically refreshed without user action
- `GET /api/v1/users/me` returns correct user data with valid JWT

---

## Phase 3 — Listings CRUD
**Goal:** Hosts can create listings; travelers can view listing details.

### Backend tasks
- `Listing.java` entity: `id`, `hostId`, `type (HOUSE|CAR|ACTIVITY)`, `title`, `description`, `pricePerNight/Day`, `location (PostGIS Point)`, `address`, `city`, `isActive`, `createdAt`, `updatedAt`
- `ListingImage.java` entity: `id`, `listingId`, `s3Key`, `displayOrder`
- `ListingRepository.java`: custom `@Query` for PostGIS proximity search
- `S3Service.java`: generate pre-signed PUT URLs, generate signed GET URLs
- `ListingController.java`:
  - `POST /api/v1/listings/images/presign` → return S3 pre-signed URL
  - `POST /api/v1/listings` (HOST) → create listing with image keys
  - `GET /api/v1/listings/{id}` → listing detail with signed image URLs
  - `PUT /api/v1/listings/{id}` (HOST, own) → update
  - `DELETE /api/v1/listings/{id}` (HOST, own) → soft delete
  - `GET /api/v1/listings/host/my` (HOST) → host's own listings
- `ListingService.java`: validate host ownership, convert coordinates to PostGIS Point, resolve S3 image URLs

### Frontend tasks
- `ListingRepository`: API calls for create, read, update, delete
- `ListingsProvider`: state for listing list and selected listing detail
- `ListingDetailScreen`: photos, title, description, price, location map, Book button
- `CreateListingScreen` (HOST): multi-step form — type, details, photos (pick + upload), location picker, price
- `EditListingScreen` (HOST): pre-filled form, same as create
- `HostListingsScreen` (HOST): list of host's own listings with edit/delete actions
- `ImageUploadService`: pick images, upload to S3 pre-signed URL, return keys

### Dependencies
- Database Agent: V2 migration (listings + listing_images tables, PostGIS extension)
- Architecture Agent: S3 pre-signed URL strategy confirmed in `api-contract.md`

### Definition of done
- Host can create a listing with photos uploaded to S3
- Traveler can view listing detail with photos loading from S3

---

## Phase 4 — Search & Discovery
**Goal:** Travelers can search listings by location, type, dates, and price range.

### Backend tasks
- `SearchController.java`: `GET /api/v1/listings` with query params: `lat`, `lng`, `radius`, `type`, `checkIn`, `checkOut`, `minPrice`, `maxPrice`, `page`, `size`
- `SearchService.java`: build PostGIS `ST_DWithin` query, apply filters, paginate
- `ListingRepository.java`: custom JPQL with PostGIS functions
- `PagedResponse.java`: `{ content, page, size, totalElements, totalPages }`
- Response includes distance from search point

### Frontend tasks
- `SearchScreen`: map view (google_maps_flutter) with listing pins + list view toggle
- `SearchFiltersSheet`: type selector, price range slider, date range picker
- `SearchProvider`: manage search params, results, loading state
- `ListingCard` widget: thumbnail, title, price, distance, rating
- `MapController`: cluster pins when zoomed out, tap pin to show listing card
- Deep link support: open listing from map pin

### Dependencies
- Database Agent: GiST spatial index on `listings.location`
- Phase 3 complete (listings exist to search)

### Definition of done
- Search returns listings within a given radius sorted by distance
- Map view shows pins for all results, tapping opens listing detail

---

## Phase 5 — Bookings & Availability
**Goal:** Travelers can check availability and book listings; hosts can confirm or decline.

### Backend tasks
- `Booking.java` entity: `id`, `listingId`, `travelerId`, `checkIn`, `checkOut`, `totalPrice`, `status (PENDING|CONFIRMED|COMPLETED|CANCELLED)`, `createdAt`
- `Availability.java` entity: `id`, `listingId`, `date`, `isBlocked` (host manually blocks dates)
- `BookingRepository.java`: find overlapping bookings query
- `BookingController.java`:
  - `GET /api/v1/listings/{id}/availability?month=YYYY-MM`
  - `POST /api/v1/bookings` → check overlap, create PENDING booking
  - `GET /api/v1/bookings/{id}`
  - `GET /api/v1/bookings/my` (TRAVELER)
  - `GET /api/v1/bookings/host` (HOST)
  - `PUT /api/v1/bookings/{id}/status` (HOST: CONFIRMED/CANCELLED; TRAVELER: CANCELLED)
- `BookingService.java`: overlap detection with optimistic lock, status transition validation
- Send email on booking creation and status change (SendGrid)

### Frontend tasks
- `AvailabilityCalendar` widget: show booked/blocked/available dates
- `BookingCheckoutScreen`: date picker, price breakdown, Confirm button
- `BookingDetailScreen`: booking info, status badge, cancel button
- `BookingsHistoryScreen` (TRAVELER): list of past and upcoming bookings
- `HostBookingsScreen` (HOST): incoming booking requests, confirm/decline actions
- `BookingProvider`: booking state management

### Dependencies
- Database Agent: V3 migration (bookings + availabilities tables)
- Phase 3 complete (listings exist to book)

### Definition of done
- Traveler can pick dates, see price, and submit booking
- Host sees the booking request and can confirm or decline
- Email is sent on booking creation and status changes

---

## Phase 6 — Payments (Stripe)
**Goal:** Travelers pay at booking; hosts receive payouts via Stripe Connect.

### Backend tasks
- `StripeService.java`: create PaymentIntent, confirm, refund, create Connect account, create transfer
- `PaymentController.java`:
  - `POST /api/v1/payments/intent` → create Stripe PaymentIntent, return `clientSecret`
  - `POST /api/v1/payments/confirm` → confirm booking after payment
  - `POST /api/v1/payments/webhook` → handle Stripe webhooks (verify signature)
  - `GET /api/v1/payments/onboarding` (HOST) → Stripe Connect onboarding URL
  - `GET /api/v1/payments/dashboard` (HOST) → Stripe Connect dashboard link
- `Payment.java` entity: `id`, `bookingId`, `stripePaymentIntentId`, `amount`, `currency`, `status`, `createdAt`
- Webhook handler: `payment_intent.succeeded` → confirm booking, schedule payout
- `PayoutService.java`: transfer platform fee, send remainder to host Stripe account

### Frontend tasks
- `flutter_stripe` package integration
- `PaymentScreen`: Stripe Payment Sheet (handles card input natively)
- `PaymentProvider`: create intent, confirm payment, handle errors
- `HostOnboardingScreen` (HOST): "Connect bank account" button → Stripe onboarding web view
- `HostEarningsScreen` (HOST): earnings summary, payout history, "Open Stripe Dashboard" button
- Handle payment errors gracefully (declined card, 3D Secure, etc.)

### Dependencies
- Database Agent: V4 migration (payments table)
- Phase 5 complete (bookings must exist before payment)
- Stripe account and API keys in `.env`

### Definition of done
- Traveler can pay for a booking with a real (test mode) card
- Host receives a payout minus platform fee after checkout

---

## Phase 7 — Messaging (WebSocket Chat)
**Goal:** Travelers and hosts can message each other in real time.

### Backend tasks
- `MessageThread.java` entity: `id`, `listingId`, `travelerId`, `hostId`, `createdAt`
- `Message.java` entity: `id`, `threadId`, `senderId`, `content`, `sentAt`, `isRead`
- `MessageRepository.java`, `MessageThreadRepository.java`
- `WebSocketConfig.java`: STOMP over WebSocket, SockJS fallback, auth handshake interceptor
- `ChatController.java` (`@MessageMapping`):
  - `SUBSCRIBE /topic/chat/{threadId}` — receive real-time messages
  - `SEND /app/chat/{threadId}` — send a message (broadcast via Redis pub/sub)
- `MessageController.java` (REST):
  - `GET /api/v1/messages/threads` — list user's threads
  - `GET /api/v1/messages/threads/{id}` — thread history (paginated)
  - `POST /api/v1/messages/threads` — start a new thread
- Redis pub/sub: distribute messages across nodes (future scale)

### Frontend tasks
- `web_socket_channel` or `stomp_dart_client` package
- `ChatListScreen`: list of message threads with last message preview
- `ChatScreen`: real-time message thread, send box, auto-scroll
- `ChatProvider`: WebSocket connection lifecycle, message state
- Unread badge on tab bar icon
- Open chat from listing detail ("Message host" button) and booking detail

### Dependencies
- Database Agent: V5 migration (message_threads + messages tables)
- Phase 2 complete (auth needed for WebSocket handshake)

### Definition of done
- Traveler and host can exchange messages in real time
- Messages persist and reload correctly on app restart

---

## Phase 8 — Reviews & Ratings
**Goal:** Travelers can leave reviews after a completed booking; ratings show on listings.

### Backend tasks
- `Review.java` entity: `id`, `bookingId`, `listingId`, `reviewerId`, `rating (1-5)`, `comment`, `createdAt`
- `ReviewController.java`:
  - `POST /api/v1/reviews` (TRAVELER, booking must be COMPLETED, one review per booking)
  - `GET /api/v1/listings/{id}/reviews` (paginated)
- `ReviewService.java`: validate booking ownership, one-review-per-booking constraint
- `ListingService.java`: recompute and cache `averageRating` + `reviewCount` on new review

### Frontend tasks
- `WriteReviewScreen`: star rating selector + comment text field
- `ReviewsListScreen`: paginated reviews for a listing
- Show average rating + review count on `ListingCard` and `ListingDetailScreen`
- Post-booking prompt: "How was your stay?" notification after booking completion

### Dependencies
- Database Agent: V6 migration (reviews table, average_rating column on listings)
- Phase 5 complete (bookings must be COMPLETED)

### Definition of done
- Traveler can submit one review per completed booking
- Average rating updates on the listing immediately after review submission

---

## Phase 9 — Push Notifications (FCM)
**Goal:** Users receive push notifications for key events.

### Backend tasks
- `FcmService.java`: send push notification via Firebase Admin SDK
- `DeviceToken.java` entity: `id`, `userId`, `fcmToken`, `platform (IOS|ANDROID)`, `updatedAt`
- `NotificationController.java`:
  - `POST /api/v1/notifications/token` — register/update device FCM token
  - `GET /api/v1/notifications` — notification history
- Trigger FCM push from:
  - New booking request (HOST)
  - Booking confirmed/cancelled (TRAVELER)
  - New message received (both)
  - Review left (HOST)

### Frontend tasks
- `FirebaseMessagingService`: request permission, get token, register with backend
- Handle foreground messages (show in-app banner)
- Handle background/terminated messages (deep link to relevant screen)
- `NotificationCentreScreen`: list of past notifications

### Dependencies
- Database Agent: V7 migration (device_tokens + notifications tables)
- Firebase project set up with Android and iOS apps registered

### Definition of done
- Host receives push when traveler books
- Traveler receives push when host confirms or cancels
- Tapping push notification navigates to the relevant screen

---

## Phase 10 — Admin Panel
**Goal:** Admin can view, moderate, and manage users and listings.

### Backend tasks
- `AdminController.java` (ADMIN role only):
  - `GET /api/v1/admin/users` (paginated, search by email)
  - `PUT /api/v1/admin/users/{id}/status` (activate/suspend)
  - `GET /api/v1/admin/listings` (paginated, filter by status)
  - `PUT /api/v1/admin/listings/{id}/status` (activate/deactivate)
  - `GET /api/v1/admin/bookings` (paginated)
  - `GET /api/v1/admin/stats` (total users, bookings, revenue)

### Frontend tasks
- Admin screens are Flutter web (or a separate web app) — out of scope for mobile build
- For mobile: add `AdminDashboardScreen` visible only to ADMIN role users
- Stats: total users, total listings, total bookings, total revenue widgets

### Dependencies
- All previous phases complete

### Definition of done
- Admin can suspend a user and their listings are hidden from search
- Admin can view platform-wide booking and revenue stats

---

## Phase 11 — Polish, Testing & CI/CD Hardening
**Goal:** App is stable, tested, and ready for production release.

### Backend tasks
- Unit tests for all services (`*Test.java`, Mockito)
- Integration tests for all controllers (`@SpringBootTest`, TestContainers for real PostgreSQL)
- Performance: add database query logging, identify N+1 queries, add `@EntityGraph` where needed
- API rate limiting via Redis counters (auth endpoints: 10 req/min per IP)
- `ActuatorConfig`: expose health, metrics endpoints for monitoring

### Frontend tasks
- Widget tests for all screens
- Integration tests for auth, booking, payment flows
- Handle all network error states gracefully (no internet, timeout, 500)
- Accessibility audit: semantic labels, contrast ratios
- App icons, splash screen, `AndroidManifest.xml` + `Info.plist` permissions review
- TestFlight / Play Store internal testing release

### CI/CD tasks
- GitHub Actions: build + test backend on every PR
- GitHub Actions: `flutter test` + `flutter build apk` on every PR
- Docker build and push to registry on merge to `main`
- Secrets stored in GitHub Actions secrets (never in code)

### Definition of done
- All tests pass in CI
- App builds for both iOS and Android without errors
- Zero critical security issues in dependency audit

---

## Phase Summary

| Phase | Backend | Frontend | Est. complexity |
|---|---|---|---|
| 1 Scaffold | Spring Boot init | Flutter init | Low |
| 2 Auth | JWT + refresh | Login/Register screens | Medium |
| 3 Listings | CRUD + S3 | Create/view listing | Medium |
| 4 Search | PostGIS query | Map + filter UI | High |
| 5 Bookings | Calendar + status | Checkout + history | High |
| 6 Payments | Stripe integration | Payment sheet | High |
| 7 Messaging | WebSocket STOMP | Real-time chat | High |
| 8 Reviews | CRUD + avg rating | Star rating UI | Low |
| 9 Push | FCM service | Notification handling | Medium |
| 10 Admin | Admin endpoints | Admin screens | Medium |
| 11 Polish | Tests + perf | Tests + accessibility | High |
