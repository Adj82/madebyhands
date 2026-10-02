# MadeByHands daily development log

Use one dated section per workday so the three role-based branches can be merged with a clear record of ownership and integration points.

## 17 September 2026 — Buyer side (Suhani)

### Added

- Buyer dashboard with Home, Explore, Saved, Cart, and Profile navigation.
- Product catalogue mock model and six sample handmade products.
- Search by product, craft category, or artisan, plus category filters.
- Product detail screen with artisan details, delivery information, save action, and add-to-cart action.
- In-memory saved-items and cart flows, quantity controls, subtotal, and empty states.
- Shared beige, sage, terracotta, and cream theme tokens for cross-team visual consistency.
- Buyer widget tests for catalogue search and saved products.
- Buyer-only preview entry point for running the UI without Firebase during frontend development.

### Integration notes

- Product data is intentionally behind `mock_products.dart`; replace it with a repository/API source without changing the buyer UI contract.
- Cart and saved-item state is local UI state for the initial screen milestone. Move it to Bloc/repositories when backend collections are agreed.
- Checkout currently shows an informational message. Payment selection and order creation should be integrated jointly by the team.
- Existing authentication accepts `buyer`, `creator`, and `admin`; the dashboard router also tolerates `seller` for future role naming alignment.
- Run `flutter run -t lib/features/buyer/buyer_preview.dart` to preview only the buyer UI; this does not initialize Firebase or replace the production app entry point.

### Next buyer tasks

- Connect product catalogue and favourites to Firestore.
- Add order history/detail and saved-address screens.
- Agree cart/order schema with the seller and admin implementations.
- Integrate payment only after the shared order lifecycle is finalized.

## 18 September 2026 — Buyer data and account screens (Suhani)

### Added

- Firestore-backed live product catalogue and per-user favourites.
- Buyer repository contract with Firestore and in-memory preview implementations.
- Order history and order detail screens.
- Saved-address list plus add, edit, delete, and make-default actions.
- Buyer Firestore collection/field contract in `docs/buyer-firestore-schema.md`.
- Widget coverage for order history/details and saved addresses.

### Integration notes

- Cart and checkout remain local and unchanged.
- The seller/admin teams should write products and orders using the documented buyer contract.
- Firestore security rules must enforce user ownership for favourites, addresses, and orders.

## 22 September 2026 — Cross-panel order synchronization

### Added

- Required buyer/creator phone collection plus completion for existing accounts.
- Payment-skipped checkout that groups cart items by creator and places real Firestore orders.
- Shared fee snapshots with platform fee, commission, and creator net payout.
- Real admin order management, platform balance, pending payouts, and payout release.
- Real creator earnings sourced from the same order documents.
- Buyer and creator ticket creation/conversations plus admin reply and resolution.
- Debug-only, idempotent sample-order generation for registered creators.
- Shared Firestore schema documentation and local security-rules proposal.

### Safety notes

- No Firebase rules were deployed and no live sample records were created.
- Sample seeding requires an explicit admin confirmation and is available only in debug builds.
- Production payment processing should move financial calculation to a trusted backend.

## 1 October 2026 — MVP hardening and cleanup

### Payments and API

- Server auth now verifies Firebase ID tokens only (no unverified fallback); Razorpay keys come from environment variables only.
- Shared helpers in `server/` (`http.js`, `fees.js`, `checkout.js`, `razorpay.js`); the cart is always priced server-side, including free-text customizations.
- `finalize-payment` stays idempotent and refunds automatically if order creation fails after capture. Web checkout no longer loses payments when the modal reports an interim failure.
- New `/api/reject-order` for creators and admins: restores stock, marks the order Rejected and refunds the buyer; admins can retry failed refunds. `/api/verify-payment` was removed (unused).
- Node unit tests: `npm test`.

### Firebase

- `firestore.rules` rewritten: no self role escalation, no client-created orders, creator order updates limited to forward fulfilment, product edits return to review, payout fields super-admin only, private `creator_verifications` and `creator_bank_accounts`.
- Verification documents moved off the public creator profile; profile edits no longer reset verification status.
- Product uploads fail loudly instead of falling back to placeholder images.

### Panels

- Buyer: Popular picks feed, category tiles and stories open filtered Shop, filters use the shared category list, product photo gallery, order cost breakdown, refund status and courier tracking links.
- Creator: streamed products/orders/notifications, delete/publish/unpublish/stock actions, reject & refund, dispatch details, analytics (sales, earnings, new/in-progress orders, best seller) and storefront preview.
- Admin: Finance shows payout details from the creator's bank record and releases only delivered orders; orders show correct totals and refund state; settings keep only working fee controls; the unused account-deletion request flow was removed (users delete their own accounts).

### Deploy checklist

- `firebase deploy --only firestore:rules`
- Vercel env: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `PAYMENT_ALLOWED_ORIGINS`
- Rotate the Razorpay test key that previously appeared in git history.
