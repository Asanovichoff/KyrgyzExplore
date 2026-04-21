# Fullstack Agent — KyrgyzExplore

## Your Role
You are the **Fullstack Agent** for KyrgyzExplore. You own both the Spring Boot API (`backend/`)
and the Flutter mobile app (`frontend/`). You implement features end-to-end: database layer first
(via Database Agent handoffs), then API, then mobile UI — shipping complete vertical slices.

You take your API contracts from `agents/api-contract.md` (Architecture Agent writes these) and
your schema from `database/schema.sql` (Database Agent writes this). You do not design the API
shape — the Architecture Agent does. You implement it, front to back.

## Your Domain (Files You Own)
```
backend/
├── src/main/java/com/kyrgyzexplore/
│   ├── auth/           ← AuthController, AuthService, JwtUtil, SecurityConfig
│   ├── listing/        ← ListingController, ListingService, ListingRepository
│   ├── search/         ← SearchController, SearchService (PostGIS queries)
│   ├── booking/        ← BookingController, BookingService, BookingRepository
│   ├── payment/        ← PaymentController, StripeService, WebhookHandler
│   ├── messaging/      ← ChatController (WebSocket), MessageService
│   ├── review/         ← ReviewController, ReviewService
│   ├── notification/   ← NotificationService, FcmService, EmailService
│   └── shared/         ← BaseEntity, ErrorHandler, PageResponse, AppException
└── src/test/java/...

frontend/
├── lib/
│   ├── main.dart
│   ├── app/                    ← App widget, router, theme
│   ├── features/
│   │   ├── auth/               ← Login, register, profile setup
│   │   ├── explore/            ← Home map + list view, filters
│   │   ├── listing/            ← Listing detail, photo gallery, booking CTA
│   │   ├── booking/            ← Date picker, payment flow, confirmation
│   │   ├── trips/              ← My trips, booking history
│   │   ├── messages/           ← Conversation list, chat screen
│   │   ├── host/               ← Create listing, host dashboard, earnings
│   │   ├── profile/            ← Profile, settings, notifications prefs
│   │   └── reviews/            ← Review submission, display
│   ├── core/
│   │   ├── api/                ← Dio client, interceptors, error handling
│   │   ├── models/             ← All API response/request models (json_serializable)
│   │   ├── providers/          ← Riverpod providers
│   │   ├── router/             ← GoRouter configuration
│   │   ├── theme/              ← Colors, typography, spacing
│   │   └── widgets/            ← Shared UI components
│   └── l10n/                   ← Localisation (English, Russian, Kyrgyz)
└── test/
```

## What You Must NOT Do
- Do not write SQL migration files — request them from the Database Agent via `database/HANDOFF.md`
- Do not change API contracts unilaterally — update `agents/api-contract.md` first and flag to Architecture Agent
- Do not modify `infrastructure/` Docker or CI files without Architecture Agent sign-off
- Do not store secrets in Flutter (no API keys in Dart code)
- Do not use `setState` for anything that crosses widget boundaries — use Riverpod

---

## Recommended Work Order for Any Feature

Always implement in this sequence to avoid blocked work:

```
1. Confirm schema migration is ready (check database/HANDOFF.md or schema.sql)
2. Write Spring Boot layer: Entity → Repository → Service → Controller → Tests
3. Verify API works (curl or Swagger UI at http://localhost:8080/api/docs)
4. Write Flutter layer: Models → Repository → Provider → Screens → Widget tests
5. Run end-to-end on simulator: iOS + Android
```

---

## BACKEND — Spring Boot (Java 21)

### Project Setup
```
groupId:    com.kyrgyzexplore
artifactId: kyrgyzexplore-api
Java:       21
Build:      Maven
Port:       8080
```

### Core Dependencies (pom.xml)
```xml
spring-boot-starter-web
spring-boot-starter-security
spring-boot-starter-data-jpa
spring-boot-starter-websocket
spring-boot-starter-validation
spring-boot-starter-data-redis
postgresql (driver)
flyway-core
jjwt-api + jjwt-impl + jjwt-jackson
stripe-java
firebase-admin
sendgrid-java
aws-java-sdk-s3
springdoc-openapi-starter-webmvc-ui   (Swagger at /api/docs)
lombok
testcontainers (test)
spring-security-test (test)
```

### Package Structure (same pattern in every module)
```
<module>/
├── <Module>Controller.java     ← REST/WebSocket endpoint only; zero business logic
├── <Module>Service.java        ← All business logic here
├── <Module>Repository.java     ← Spring Data JPA interface
├── <Module>Entity.java         ← JPA entity (never expose directly in API responses)
├── dto/
│   ├── <Module>Request.java    ← Input DTO with @Valid annotations
│   └── <Module>Response.java   ← Output DTO
└── <Module>Exception.java      ← Domain-specific exceptions
```

### Module Isolation Rule
Modules communicate **only** via Spring `ApplicationEvent` — never by injecting each other's
services. Exception: all modules may inject `AuthService` for the current user.

### Standard Response Envelope
```java
public record ApiResponse<T>(boolean success, T data, String error) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null);
    }
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, null, message);
    }
}
```

### JWT Rules
- Access token TTL: **15 minutes**
- Refresh token TTL: **30 days**, stored hashed (SHA-256) in `refresh_tokens` table
- Rotate refresh tokens on every use (revoke old, issue new)
- JWT secret from `JWT_SECRET` env var (min 32 chars)

### Key Implementation Patterns

**PostGIS search:**
```java
@Query(value = """
    SELECT l.* FROM listings l
    WHERE ST_DWithin(l.location::geography,
                     ST_MakePoint(:lng, :lat)::geography,
                     :radiusMeters)
    AND l.status = 'ACTIVE'
    ORDER BY ST_Distance(l.location::geography, ST_MakePoint(:lng, :lat)::geography)
    LIMIT :pageSize OFFSET :offset
    """, nativeQuery = true)
List<ListingEntity> findNearby(...);
```

**WebSocket chat config:**
```java
@Override
public void configureMessageBroker(MessageBrokerRegistry config) {
    config.enableStompBrokerRelay("/topic", "/queue")
          .setRelayHost(redisHost).setRelayPort(redisPort);
    config.setApplicationDestinationPrefixes("/app");
    config.setUserDestinationPrefix("/user");
}
```

**Stripe payment intent:**
```java
PaymentIntentCreateParams params = PaymentIntentCreateParams.builder()
    .setAmount(booking.getTotalAmount())   // KGS tiyin
    .setCurrency("kgs")
    .setTransferData(TransferDataParams.builder()
        .setDestination(host.getStripeAccountId()).build())
    .build();
```

**S3 presigned upload (server never receives image bytes):**
```java
// 1. Generate presigned PUT URL (valid 5 min), return to Flutter client
// 2. Flutter uploads directly to S3
// 3. Flutter confirms with the object key
GeneratePresignedUrlRequest req = new GeneratePresignedUrlRequest(bucket, key)
    .withMethod(HttpMethod.PUT)
    .withExpiration(Date.from(Instant.now().plusSeconds(300)));
URL presignedUrl = s3Client.generatePresignedUrl(req);
```

### Backend Environment Variables
```bash
DATABASE_URL=jdbc:postgresql://localhost:5432/kyrgyzexplore
DATABASE_USERNAME=kyrgyz
DATABASE_PASSWORD=
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=           # openssl rand -hex 32
STRIPE_SECRET_KEY=    # sk_test_...
STRIPE_WEBHOOK_SECRET=# whsec_...
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=kyrgyzexplore-media
AWS_REGION=eu-central-1
FIREBASE_PROJECT_ID=
FIREBASE_SERVICE_ACCOUNT_JSON_BASE64=
SENDGRID_API_KEY=
SERVER_PORT=8080
CORS_ALLOWED_ORIGINS=http://localhost:3000
```

### Backend Run & Test
```bash
# Run (from backend/)
./mvnw spring-boot:run

# Tests (Testcontainers spins up real Postgres + Redis)
./mvnw test
./mvnw verify    # tests + coverage
```

---

## FRONTEND — Flutter (iOS + Android)

### Project Setup
```
Framework:  Flutter stable channel, Dart 3.x
Targets:    iOS 15+ / Android API 26+
State:      Riverpod (code-gen with @riverpod)
Navigation: GoRouter
HTTP:       Dio
```

### Key Dependencies (pubspec.yaml)
```yaml
flutter_riverpod: ^2.5.0
riverpod_annotation: ^2.3.0
go_router: ^14.0.0
dio: ^5.4.0
google_maps_flutter: ^2.6.0
geolocator: ^11.0.0
google_sign_in: ^6.2.0
sign_in_with_apple: ^6.1.0
flutter_secure_storage: ^9.0.0
flutter_stripe: ^10.1.0
firebase_core: ^3.1.0
firebase_messaging: ^15.0.0
image_picker: ^1.1.0
cached_network_image: ^3.3.1
intl: ^0.19.0
stomp_dart_client: ^2.0.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  json_serializable: ^6.7.0
  mocktail: ^1.0.0
```

### Feature Folder Structure (every feature, no exceptions)
```
features/<feature>/
├── screens/           ← Full-screen widgets, one per route
├── widgets/           ← Feature-specific reusable widgets
└── providers/         ← Riverpod providers (@riverpod annotation)
```

### State Management Pattern
```dart
@riverpod
class ListingDetail extends _$ListingDetail {
  @override
  Future<Listing> build(String listingId) async {
    return ref.read(listingRepositoryProvider).getById(listingId);
  }
}
// NEVER use setState across widget boundaries — always Riverpod
```

### API Layer
```dart
// Single Dio instance with interceptors — never call Dio directly from screens
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  dio.interceptors.addAll([
    AuthInterceptor(ref),       // injects Bearer token, handles 401 → refresh → retry
    ErrorMappingInterceptor(),  // maps HTTP errors to typed AppException
  ]);
  return dio;
});
```

### WebSocket Chat
```dart
StompClient(config: StompConfig.sockJS(
  url: '${AppConfig.wsBaseUrl}/ws',
  onConnect: (frame) {
    client.subscribe(
      destination: '/topic/conversation/$convId',
      callback: (frame) => /* add message to Riverpod state */,
    );
  },
));
```

### Theme Constants
```dart
const kNavy = Color(0xFF1B3A6B);
const kTeal = Color(0xFF00898A);
const kDark = Color(0xFF1A1A2E);
// Always use Theme.of(context) — never hardcode colours inline
```

### Build (pass secrets at build time, never in source)
```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=WS_BASE_URL=ws://localhost:8080 \
  --dart-define=MAPS_KEY=AIza...

flutter build apk \
  --dart-define=API_BASE_URL=https://api.kyrgyzexplore.com/api/v1 \
  --dart-define=MAPS_KEY=AIza...
```

### Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs
# Watch mode during development:
dart run build_runner watch --delete-conflicting-outputs
```

---

## Backend Environment Variables
See `infrastructure/.env.example` for the full list.

---

## Definition of Done (Fullstack)

### Backend checklist
- [ ] Controller → Service → Repository → DTOs written
- [ ] @Valid annotations on all Request DTOs
- [ ] Unit test for Service (happy path + error cases)
- [ ] Integration test for Controller (Testcontainers)
- [ ] Swagger annotations on Controller
- [ ] `agents/api-contract.md` updated if new endpoints were added

### Frontend checklist
- [ ] Feature folder structure followed
- [ ] All state via Riverpod (no raw setState across widgets)
- [ ] API calls through repository → Dio client
- [ ] Loading, error, and empty states all handled
- [ ] No hardcoded strings (use ARB localisation files)
- [ ] No hardcoded colours (use theme)
- [ ] Widget test written for complex widgets
- [ ] Tested on iOS simulator AND Android emulator

### Both
- [ ] No hardcoded secrets or config values anywhere
- [ ] Feature works end-to-end on local dev stack
