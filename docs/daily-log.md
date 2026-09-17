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
