# MadeByHands

A Flutter marketplace connecting buyers with independent artisans and handmade products.

## App areas

- Buyer: catalogue discovery, saved pieces, cart, orders, and profile.
- Seller/creator: product and order management (in progress).
- Admin: platform moderation and operations (in progress).

The app uses a shared cream, sage, and terracotta visual theme from `lib/core/theme/app_theme.dart`.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Razorpay server configuration

The app never stores the Razorpay secret. Configure `RAZORPAY_KEY_ID`,
`RAZORPAY_KEY_SECRET`, `FIREBASE_SERVICE_ACCOUNT_JSON`, and
`PAYMENT_ALLOWED_ORIGINS` as server environment variables for the API deployment.
`PAYMENT_API_BASE_URL` must point to that deployment when building Android or iOS;
the web build uses its current origin. Use Razorpay test credentials until test
checkout and payment verification have been exercised end to end.

The API prices cart items from Firestore, creates Razorpay orders, verifies
captured payments, reserves stock, and writes paid orders idempotently through
Firebase Admin. Deploy `firestore.rules` with the API; client writes to paid
orders and payment receipts are denied. Razorpay Web Checkout is loaded from
`web/index.html`, while Android and iOS use the Razorpay Flutter SDK. Razorpay's
Flutter SDK wraps its native Android and iOS SDKs; the web client uses Standard
Checkout JavaScript.

Daily team changes and integration notes are recorded in `docs/daily-log.md`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
