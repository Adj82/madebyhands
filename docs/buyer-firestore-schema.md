# Buyer Firestore contract

> The canonical cross-panel order, finance, user, and support contract is documented in `docs/firestore-schema.md`. This file retains buyer-specific catalogue and address notes.

The buyer feature reads and writes the following collections. Field names should stay aligned with the seller/admin implementations.

## `products/{productId}`

- `name`: string
- `creatorName` (legacy `artisan` / `sellerName`): string
- `categories`: up to two category names; legacy listings only have `category`
- `description`: string
- `price`: number (whole INR amount)
- `images`: photo URLs; the first is used on cards
- `stock`, `orderCount`, `wishlistCount`: integers
- `isActive`: boolean; the buyer feed queries `isActive == true`, which admins
  set on approval and creators toggle when publishing
- `colorValue`: optional ARGB integer for the placeholder shown without photos

Ratings are computed from `products/{productId}/reviews`.

## `users/{userId}/favorites/{productId}`

- `productId`: string
- `savedAt`: server timestamp

The product ID is also used as the favourite document ID, making save/remove idempotent.

## `orders/{orderId}`

Written only by the payment API; see `docs/firestore-schema.md` for the full
contract. The buyer app reads `buyerId`, `createdAt`, `updatedAt`, `status`,
`subtotal`, `flatFee`, `buyerPayableAmount` (what was paid), `items`,
`shippingAddress`, `carrierName`, `consignmentNumber`, `rejectionReason` and
`refundStatus`.

The buyer client filters orders by `buyerId` and sorts them newest-first locally, avoiding a required composite index.

## `users/{userId}/addresses/{addressId}`

- `label`: string
- `recipientName`: string
- `phone`: string
- `addressLine`: string
- `city`: string
- `state`: string
- `postalCode`: string
- `isDefault`: boolean
- `updatedAt`: server timestamp

When a new default address is saved, the buyer repository clears `isDefault` on the user's other addresses in the same batch.

## Required security behaviour

- Signed-in users may read products; the feed shows active ones only.
- A user may read and modify only their own favourites and addresses.
- A buyer may read only orders whose `buyerId` equals their authenticated user ID.
- Clients can never create orders; checkout goes through `/api/create-order` and `/api/finalize-payment`.
