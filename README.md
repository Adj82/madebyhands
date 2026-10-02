# MadeByHands

A Flutter marketplace connecting buyers with independent artisans and handmade products.

## App areas

- Buyer: home feed with popular picks, search and category filters, creator
  storefronts, wishlist, cart, Razorpay checkout, order tracking, reviews,
  notifications, support tickets and account deletion.
- Creator: onboarding, verification, product listing (photos, customizations,
  publish/unpublish, stock), order fulfilment with dispatch details,
  reject-and-refund, earnings, payout details and notifications.
- Admin: creator verification, product approval, orders (reject & refund,
  refund retry), users, categories and support; super admins also manage
  finance (payout release), platform fees and admin roles.

The app uses a shared cream, sage, and terracotta visual theme from `lib/core/theme/app_theme.dart`.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run

npm install
npm test          # payment API unit tests (node:test, no network)
firebase deploy --only firestore:rules
```

## Razorpay server configuration

The app never stores the Razorpay secret. Configure `RAZORPAY_KEY_ID`,
`RAZORPAY_KEY_SECRET`, `FIREBASE_SERVICE_ACCOUNT_JSON`, and
`PAYMENT_ALLOWED_ORIGINS` as server environment variables for the API deployment.
`PAYMENT_API_BASE_URL` must point to that deployment when building Android or iOS;
the web build uses its current origin. Use Razorpay test credentials until test
checkout and payment verification have been exercised end to end.

For the current Firebase app, the service account in
`FIREBASE_SERVICE_ACCOUNT_JSON` must belong to project `madebyhands-77f87`, and
`PAYMENT_ALLOWED_ORIGINS` must include `https://madebyhands.vercel.app`. Use the
Razorpay API Key ID and Key Secret from Account & Settings → API Keys; the
`razorpay.me/@madebyhands` payment handle is not an API credential.

The API prices cart items from Firestore, creates Razorpay orders, verifies
captured payments, reserves stock, and writes paid orders idempotently through
Firebase Admin (`/api/create-order`, `/api/finalize-payment`). Creators and
admins reject orders through `/api/reject-order`, which restores stock and
refunds the buyer. Deploy `firestore.rules` with the API; client writes to
paid orders and payment records are denied. Razorpay Web Checkout is loaded
from `web/index.html`, while Android and iOS use the Razorpay Flutter SDK.

The Firestore data contract is in `docs/firestore-schema.md`. Daily team
changes and integration notes are recorded in `docs/daily-log.md`.
