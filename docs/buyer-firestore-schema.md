# Buyer Firestore contract

> The canonical cross-panel order, finance, user, and support contract is now documented in `docs/firestore-schema.md`. This file retains buyer-specific catalogue and address notes.

The buyer feature reads and writes the following collections. Field names should stay aligned with the seller/admin implementations.

## `products/{productId}`

- `name`: string
- `artisan` or `sellerName`: string
- `category`: string
- `description`: string
- `price`: number (whole INR amount)
- `rating`: number
- `isActive`: boolean; missing values are treated as active
- `colorValue`: optional ARGB integer used by the temporary icon artwork
- `iconCodePoint`: optional Material icon code point

## `users/{userId}/favorites/{productId}`

- `productId`: string
- `savedAt`: server timestamp

The product ID is also used as the favourite document ID, making save/remove idempotent.

## `orders/{orderId}`

- `buyerId`: string
- `createdAt`: timestamp
- `status`: string
- `total`: number (whole INR amount)
- `items`: array of maps containing `productId`, `name`, `quantity`, and `unitPrice`
- `shippingAddress`: string or a map containing `addressLine`, `city`, `state`, and `postalCode`

The buyer client filters orders by `buyerId` and sorts them newest-first locally, avoiding a required composite index for the initial version.

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

- Anyone allowed to shop may read active products.
- A user may read and modify only their own favourites and addresses.
- A buyer may read only orders whose `buyerId` equals their authenticated user ID.
- Order creation/status permissions must be agreed with the seller/admin work before checkout is connected.
