# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project shape

MadeByHands is a handmade-goods marketplace. One repo holds **two deployables**:

1. **Flutter client** (`lib/`, `pubspec.yaml`) — Android, iOS, and web.
2. **Vercel Node serverless API** (`api/` + `server/`, `package.json`) — CommonJS `module.exports = async (req, res) => {}` handlers. Its dependencies (`razorpay`, `firebase-admin`) are tracked in `package.json`, entirely separate from pubspec.

Firestore is the shared database. The client reads it directly; anything financial is written only by the API through the Firebase Admin SDK.

## Commands

```sh
flutter pub get
flutter analyze
flutter test
flutter test test/platform_fee_calculator_test.dart            # single file
flutter test --plain-name "applies flat and percentage fees"   # single test
flutter run
flutter run -t lib/features/buyer/buyer_preview.dart           # buyer UI, no Firebase
firebase deploy --only firestore:rules
```

Web/production build (what Vercel runs via `vercel-build.sh`):

```sh
flutter build web --release --no-tree-shake-icons --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
```

Toolchain notes:

- On Windows, `flutter analyze` and `flutter run` need Developer Mode enabled (plugin builds require symlink support) or they abort with "Building with plugins requires symlink support".
- `flutter analyze` runs an implicit pub step that may rewrite `analysis_options.yaml` (adding an `analyzer.exclude` block) and `pubspec.lock`. Check `git status` afterwards and revert if you did not intend those changes.
- `lib/firebase_options.dart`, `android/app/google-services.json`, and the iOS/macOS plist equivalents are **gitignored**. A fresh clone will not compile until `flutterfire configure` is run against Firebase project `madebyhands-77f87`.
- `extract.ps1`, `extract_schema.ps1`, `generate_launcher_icons.ps1` and the `*_extracted.txt` files are one-off PowerShell helpers with hardcoded absolute paths. They are not part of any build.
- Android `applicationId` is still `com.example.madebyhands`.

## Client architecture

### Routing lives in `main.dart`

There is no route table or router package. `lib/main.dart` renders a `BlocBuilder<AuthBloc, AuthState>` and switches on `state.user.role` to pick the root widget: `AdminDashboardPage`, `CreatorFlowWrapper`, or `BuyerDashboardPage`. Navigation inside each panel is `Navigator.push` plus a nav-index cubit. Changing top-level entry conditions means editing `main.dart`.

Roles: `buyer`, `creator` (`seller` is tolerated as an alias), `admin`. `firestore.rules` adds `super_admin` and `manager`, plus a hardcoded super-admin email allowlist.

### Two repository conventions coexist — match the feature you are in

- **`auth`, `creator`, `admin`** — full clean-architecture stack: `domain/repositories/` interface, `data/datasources/` (Firestore/Storage calls), `data/repositories/` impl. Returns `Either<Failure, T>` (fpdart).
- **`buyer`, `orders`, `support`** — a single `data/firestore_*_repository.dart` implements the domain interface directly, with no datasource layer. Returns bare `Stream`/`Future` and **throws** on error instead of returning `Failure`.

`lib/core/usecase/usecase.dart` declares a `UseCase` abstraction that **nothing implements**. Blocs call repositories directly. Do not add usecases assuming an existing pattern.

### Dependency injection

`get_it` via `serviceLocator` in `lib/init_dependencies.dart`, with a `_initX()` function per feature. Blocs are lazy singletons; auth/creator/admin datasources and repositories are factories, while buyer/orders/support repositories are lazy singletons. Every bloc is provided globally in `main.dart`'s `MultiBlocProvider`, so feature widgets assume they are already in scope.

`AdminCubit` and `BuyerCubit` are both just `Cubit<int>` holding a bottom-nav index — not domain state.

### Presentation layout

`presentation/pages/` are full screens, `presentation/views/` are tab bodies hosted inside a dashboard shell, `presentation/widgets/` are shared components.

Styling: light theme only (`AppTheme.lightThemeMode`). Take colors from `AppColors` in `lib/core/theme/app_theme.dart` (cream / sage / terracotta) rather than literals; fonts are Playfair Display + Montserrat via `google_fonts`. `flutter_screenutil` is initialized with `designSize: Size(360, 690)`, so sizes use `.sp`/`.h`/`.w`.

Cart contents and quantities are **buyer UI state backed by SharedPreferences**, never Firestore. Checkout re-sends the whole cart to the API.

## Payment flow

This is the most intricate path in the codebase and spans Dart, Node, and Firestore rules. Entry point: `lib/features/buyer/presentation/pages/checkout_page.dart` driving `lib/core/services/razorpay_service.dart`.

1. **Create order** — client POSTs `/api/create-order` with a Firebase ID token and cart lines of `{productId, quantity, customizations}`. **The client never sends prices.**
2. **Server prices the cart** — `server/checkout.js` `priceCart()` re-reads each product from Firestore, rejects inactive/out-of-stock products and unknown customization options, and computes unit prices. `api/create-order.js` then adds a flat fee per *distinct creator*, creates the Razorpay order, and writes `paymentIntents/{razorpayOrderId}` with the priced snapshot.
3. **Checkout UI** — on web, `RazorpayService` calls `window.openMadeByHandsRazorpay` (defined in `web/razorpay_checkout.js`, loaded from `web/index.html`) through the conditional import `razorpay_checkout_stub.dart` / `razorpay_checkout_web.dart`. On Android/iOS it uses the `razorpay_flutter` SDK.
4. **Finalize** — client POSTs `/api/finalize-payment`. The server verifies the HMAC-SHA256 signature with `crypto.timingSafeEqual`, re-fetches the order and payment from Razorpay's REST API (`server/razorpay.js`), and confirms status `captured`, matching amounts, and `notes.buyer_id == uid`. Then, in one Firestore transaction: decrement product stock, write **one `orders/{orderId}` document per creator** (all sharing `checkoutId`), mark the intent `paid`, and `create` `paymentReceipts/{paymentId}`. Creator/buyer notifications are a best-effort batch afterwards.
5. **Failure after capture** — the handler refunds through Razorpay and returns HTTP 409 with `refunded: true`, which the client surfaces as a distinct error.

Key invariants:

- **The idempotency key is `paymentReceipts/{paymentId}`.** A retry finds the existing receipt and returns the original `orderIds`. `RazorpayService.finalizePaidOrder` retries once on network timeouts, so finalize must stay idempotent.
- **`/api/verify-payment` is currently unused by the client** — `finalize-payment` performs its own verification. Do not treat it as a required step in the flow.
- Every handler repeats the same CORS preamble driven by `PAYMENT_ALLOWED_ORIGINS`; new endpoints should copy it.

## Money and status conventions

- **All Firestore amounts are integer rupees.** Paise exist only at the Razorpay boundary (`× 100`).
- The buyer pays `subtotal + flatFee`. The percentage commission applies **only when `subtotal > 999`** and is deducted from the creator's subtotal, so `creatorNetAmount` can never go negative.
- Rates come from `settings/platform_economics` (`flatFee`, `percentFee`), defaulting to 50 and 5.
- This fee math is **duplicated**: `PlatformFeeCalculator` in `lib/features/orders/domain/entities/marketplace_order.dart` (covered by `test/platform_fee_calculator_test.dart`) and inline in `api/finalize-payment.js`. Change both together.
- Fees are snapshotted onto each order (`flatFee`, `commissionRate`, `commissionAmount`, `platformFee`, `creatorNetAmount`); Admin Finance derives balances from those stored values, so never recompute historical orders.
- **Order status strings are mixed-case in the database** — the API writes `'Placed'`, and older records use `'Accepted'`, `'pending'`, `'Completed'`. Always compare through `OrderStatus.normalize()` / `.label()` / `.shipmentStep()` in `lib/features/orders/domain/order_status.dart` instead of raw string equality.

## Security model (`firestore.rules`)

The rules are load-bearing, not advisory — deploy them alongside API changes.

- `paymentIntents` and `paymentReceipts` are `allow read, write: if false` — Admin SDK only.
- Clients cannot create paid orders: only a super admin may create an order document, and only when `paymentStatus != 'paid'`. **Any feature that produces a real order must go through the API**, not a client Firestore write.
- Creators may update orders only via a key whitelist: `status`, `updatedAt`, `rejectionReason`, `consignmentNumber`, `carrierName`, `payoutStatus`. Adding a creator-editable order field requires a rules change.
- Users may self-update only `name`, `phone`, `email`.
- Product ownership is checked against **either** `creatorUid` **or** `creatorId`; both spellings exist in the data, and `server/checkout.js` falls back the same way.

## Environment variables

Server (Vercel): `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `PAYMENT_ALLOWED_ORIGINS`. The service account must belong to project `madebyhands-77f87`, and allowed origins must include the deployed web origin, or ID-token verification and CORS will fail in confusing ways.

Client (`--dart-define`): `PAYMENT_API_BASE_URL` (required for Android/iOS; web falls back to its own origin) and `GOOGLE_CLIENT_ID` (web Google Sign-In). The Razorpay secret never reaches the client — the public key id is returned by `/api/create-order`.

Use Razorpay **test** credentials until checkout and verification have been exercised end to end.

## Tests

`test/` holds three files and does not initialize Firebase. Widget tests inject `MockBuyerRepository` (`lib/features/buyer/data/mock_buyer_repository.dart`) and call `SharedPreferences.setMockInitialValues({})` in `setUp`. Keep new tests off live Firebase by depending on repository interfaces.

## Docs conventions

- `docs/firestore-schema.md` — shared collection/field contract across panels.
- `docs/buyer-firestore-schema.md` — buyer-facing contract.
- `docs/daily-log.md` — dated sections per workday recording per-role ownership and integration notes. The team convention is to append a new dated section rather than edit history; the file currently contains some duplicated sections from branch merges.
