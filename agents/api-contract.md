# API Contract — KyrgyzExplore
> **Owner:** Architecture Agent
> **Consumers:** Backend Agent (implements), Frontend Agent (consumes)
> **Rule:** No endpoint may be implemented by the Backend or consumed by the Frontend
> unless it appears in this file. Add endpoints here first.

---

## Base URL
```
Development:  http://localhost:8080/api/v1
Production:   https://api.kyrgyzexplore.com/api/v1
```

## Authentication
All protected endpoints require:
```
Authorization: Bearer <access_token>
```
Access tokens expire in **15 minutes**. Use the refresh endpoint to get a new one.

## Response Envelope
```json
// Success
{ "success": true, "data": { ... } }
{ "success": true, "data": [ ... ], "meta": { "page": 1, "pageSize": 20, "total": 142 } }

// Error
{ "success": false, "error": { "code": "LISTING_NOT_FOUND", "message": "Listing not found" } }
```

## Error Codes
| Code | HTTP | Description |
|------|------|-------------|
| UNAUTHORIZED | 401 | Missing or invalid token |
| FORBIDDEN | 403 | Authenticated but not allowed |
| LISTING_NOT_FOUND | 404 | |
| BOOKING_NOT_FOUND | 404 | |
| BOOKING_CONFLICT | 409 | Dates already booked |
| PAYMENT_FAILED | 402 | Stripe charge failed |
| VALIDATION_ERROR | 400 | Request body failed validation |
| INTERNAL_ERROR | 500 | Unexpected server error |

---

## AUTH

### POST /auth/register
```json
// Request
{ "email": "user@example.com", "password": "min8chars", "fullName": "Aizat Bekova", "role": "TRAVELER" }

// Response 201
{ "success": true, "data": { "accessToken": "eyJ...", "refreshToken": "tok...", "user": { "id": "uuid", "email": "...", "fullName": "...", "role": "TRAVELER" } } }
```

### POST /auth/login
```json
// Request
{ "email": "user@example.com", "password": "..." }
// Response 200 — same shape as register
```

### POST /auth/login/google
```json
// Request
{ "idToken": "<Google ID token from client>" }
// Response 200 — same shape as register
```

### POST /auth/login/apple
```json
// Request
{ "identityToken": "<Apple identity token>", "fullName": "Aizat Bekova" }
// Response 200 — same shape as register
```

### POST /auth/refresh
```json
// Request
{ "refreshToken": "tok..." }
// Response 200
{ "success": true, "data": { "accessToken": "eyJ...", "refreshToken": "newTok..." } }
```

### POST /auth/logout  🔒
```json
// Request
{ "refreshToken": "tok..." }
// Response 204 No Content
```

---

## USERS

### GET /users/me  🔒
```json
// Response 200
{ "id": "uuid", "email": "...", "fullName": "...", "phone": "+996...", "avatarUrl": "...", "role": "TRAVELER", "isVerified": true, "createdAt": "2026-01-01T00:00:00Z" }
```

### PATCH /users/me  🔒
```json
// Request (all fields optional)
{ "fullName": "...", "phone": "+996...", "avatarUrl": "..." }
// Response 200 — updated user object
```

### GET /users/:userId/reviews
```json
// Response 200
{ "success": true, "data": [ { "id": "uuid", "rating": 4, "comment": "...", "authorName": "...", "createdAt": "..." } ], "meta": { "page": 1, "total": 12 } }
```

---

## LISTINGS

### GET /listings  (Search)
**Query params:**
```
type        HOUSE | CAR | ACTIVITY   (optional)
lat         float   required if lng provided
lng         float   required if lat provided
radius      integer km, default 50
checkIn     date    YYYY-MM-DD
checkOut    date    YYYY-MM-DD
guests      integer default 1
minPrice    integer KGS tiyin
maxPrice    integer KGS tiyin
amenities   comma-separated string  e.g. wifi,kitchen
sort        distance | price_asc | price_desc | rating  default: distance
page        integer default 1
pageSize    integer default 20, max 50
```
```json
// Response 200
{ "success": true, "data": [ { "id": "uuid", "type": "HOUSE", "title": "...", "pricePerUnit": 500000, "priceUnit": "NIGHT", "avgRating": 4.7, "reviewCount": 23, "coverPhotoUrl": "...", "latitude": 42.87, "longitude": 74.59, "distanceKm": 2.3 } ], "meta": { "page": 1, "total": 87 } }
```

### POST /listings  🔒 HOST only
```json
// Request
{ "type": "HOUSE", "title": "Cozy Apt in Bishkek", "description": "...", "latitude": 42.87, "longitude": 74.59, "address": "...", "region": "Bishkek", "pricePerUnit": 500000, "priceUnit": "NIGHT", "isInstantBook": true, "attributes": { "bedrooms": 2, "bathrooms": 1, "amenities": ["wifi", "kitchen"] } }
// Response 201
{ "success": true, "data": { "id": "uuid", "status": "DRAFT", ... } }
```

### GET /listings/:listingId
```json
// Response 200
{ "id": "uuid", "type": "HOUSE", "title": "...", "description": "...", "pricePerUnit": 500000, "priceUnit": "NIGHT", "isInstantBook": true, "status": "ACTIVE", "avgRating": 4.7, "reviewCount": 23, "attributes": { ... }, "photos": [ { "id": "uuid", "url": "...", "sortOrder": 0 } ], "host": { "id": "uuid", "fullName": "...", "avatarUrl": "...", "avgRating": 4.8, "reviewCount": 15 }, "latitude": 42.87, "longitude": 74.59, "address": "..." }
```

### PATCH /listings/:listingId  🔒 Host (owner) only
```json
// Request (all fields optional)
{ "title": "...", "description": "...", "pricePerUnit": 600000, "status": "ACTIVE" }
// Response 200 — updated listing object
```

### DELETE /listings/:listingId  🔒 Host (owner) only
```
// Response 204 No Content (soft delete — sets status to DELETED)
```

---

## LISTING PHOTOS

### POST /listings/:listingId/photos/presign  🔒 Host (owner) only
```json
// Request
{ "fileName": "bedroom.jpg", "contentType": "image/jpeg" }
// Response 200
{ "presignedUrl": "https://s3.amazonaws.com/...", "objectKey": "listings/uuid/filename.jpg" }
// Frontend uploads directly to presignedUrl via PUT, then confirms:
```

### POST /listings/:listingId/photos/confirm  🔒 Host (owner) only
```json
// Request
{ "objectKey": "listings/uuid/filename.jpg", "sortOrder": 0 }
// Response 201
{ "id": "uuid", "url": "https://cdn.kyrgyzexplore.com/...", "sortOrder": 0 }
```

### DELETE /listings/:listingId/photos/:photoId  🔒 Host (owner) only
```
Response 204
```

---

## AVAILABILITY

### GET /listings/:listingId/availability
**Query params:** `year` (int), `month` (int 1-12)
```json
// Response 200
{ "success": true, "data": { "blockedDates": ["2026-07-04", "2026-07-05"] } }
```

### PUT /listings/:listingId/availability  🔒 Host (owner) only
```json
// Request
{ "blockedDates": ["2026-07-04", "2026-07-05"], "unblockedDates": ["2026-07-10"] }
// Response 200
{ "success": true, "data": { "updated": 3 } }
```

---

## BOOKINGS

### POST /bookings  🔒 TRAVELER only
```json
// Request
{ "listingId": "uuid", "checkIn": "2026-07-10", "checkOut": "2026-07-15", "guests": 2 }
// Response 201
{ "id": "uuid", "status": "PENDING", "totalAmount": 2500000, "platformFee": 750000, "stripePaymentIntentId": "pi_...", "clientSecret": "pi_..._secret_..." }
// clientSecret is for Stripe.js on the frontend to confirm payment
```

### GET /bookings/my  🔒
```json
// Query params: status (optional), page, pageSize
// Response 200
{ "success": true, "data": [ { "id": "uuid", "listing": { "id": "uuid", "title": "...", "coverPhotoUrl": "..." }, "checkIn": "2026-07-10", "checkOut": "2026-07-15", "totalAmount": 2500000, "status": "CONFIRMED" } ] }
```

### GET /bookings/:bookingId  🔒
```json
// Response 200 — full booking object
{ "id": "uuid", "listing": { ... }, "traveler": { ... }, "checkIn": "...", "checkOut": "...", "guests": 2, "totalAmount": 2500000, "platformFee": 750000, "status": "CONFIRMED", "createdAt": "..." }
```

### PATCH /bookings/:bookingId/status  🔒
```json
// Request
{ "status": "CANCELLED", "reason": "Plans changed" }
// Allowed transitions by role:
//   HOST: PENDING → CONFIRMED, PENDING → CANCELLED, CONFIRMED → CANCELLED
//   TRAVELER: PENDING → CANCELLED, CONFIRMED → CANCELLED (if policy allows)
// Response 200 — updated booking object
```

---

## PAYMENTS

### POST /payments/webhook  (Stripe — no auth, verify Stripe-Signature header)
```
// Handles: payment_intent.succeeded, payment_intent.payment_failed, transfer.created
// Response 200 OK (Stripe requires fast 200 response)
```

### GET /payouts  🔒 HOST only
```json
// Response 200
{ "success": true, "data": [ { "bookingId": "uuid", "amount": 1750000, "status": "paid", "paidAt": "2026-07-16T10:00:00Z" } ] }
```

---

## CONVERSATIONS & MESSAGES

### GET /conversations  🔒
```json
// Response 200
{ "success": true, "data": [ { "id": "uuid", "otherParty": { "id": "uuid", "fullName": "...", "avatarUrl": "..." }, "lastMessage": "...", "lastMessageAt": "...", "unreadCount": 2 } ] }
```

### GET /conversations/:conversationId/messages  🔒
```json
// Query params: page, pageSize (default 50)
// Response 200
{ "success": true, "data": [ { "id": "uuid", "senderId": "uuid", "body": "Hello!", "readAt": null, "createdAt": "..." } ] }
```

### POST /conversations/:conversationId/messages  🔒 (REST fallback — prefer WebSocket)
```json
// Request
{ "body": "When do you arrive?" }
// Response 201
{ "id": "uuid", "senderId": "uuid", "body": "...", "readAt": null, "createdAt": "..." }
```

---

## REVIEWS

### POST /reviews  🔒
```json
// Request (submitted after booking.status = COMPLETED)
{ "bookingId": "uuid", "rating": 5, "comment": "Amazing stay!" }
// Response 201
{ "id": "uuid", "rating": 5, "comment": "...", "createdAt": "..." }
```

### GET /listings/:listingId/reviews
```json
// Query params: page, pageSize
// Response 200
{ "success": true, "data": [ { "id": "uuid", "rating": 4, "comment": "...", "authorName": "...", "authorAvatarUrl": "...", "createdAt": "..." } ] }
```

---

## NOTIFICATIONS

### GET /notifications  🔒
```json
// Query params: unreadOnly (bool), page, pageSize
// Response 200
{ "success": true, "data": [ { "id": "uuid", "type": "BOOKING_CONFIRMED", "title": "Booking confirmed!", "body": "Your booking at Cozy Apt is confirmed.", "payload": { "bookingId": "uuid" }, "readAt": null, "createdAt": "..." } ] }
```

### PATCH /notifications/:notificationId/read  🔒
```
Response 200: { "success": true, "data": { "readAt": "2026-07-10T09:00:00Z" } }
```

### PATCH /notifications/read-all  🔒
```
Response 200: { "success": true, "data": { "marked": 5 } }
```

---

## WEBSOCKET (STOMP over SockJS)

### Connection
```
wss://api.kyrgyzexplore.com/ws  (production)
ws://localhost:8080/ws           (development)
```
Send `Authorization: Bearer <token>` in the CONNECT frame headers.

### Subscribe Destinations
```
/user/{userId}/queue/notifications   → personal real-time events (booking updates, new messages)
/topic/conversation/{conversationId} → conversation message stream
```

### Send Destinations (client → server)
```
/app/chat.send     { "conversationId": "uuid", "body": "Hello!" }
/app/chat.read     { "conversationId": "uuid" }   → marks all messages as read
```

### Notification Event Payload
```json
{ "type": "NEW_MESSAGE | BOOKING_CONFIRMED | BOOKING_CANCELLED | REVIEW_POSTED | PAYOUT_SENT", "payload": { ... } }
```
