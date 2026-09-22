# Shared Firestore schema

This contract is shared by the buyer, creator, and admin panels. Firestore is schemaless, so the application models and repository mappers enforce these fields.

## Users

`users/{userId}` stores `uid`, `email`, `name`, `phone`, `role`, `isVerified`, and `isSuspended`.

Buyer and creator registration requires a 10-digit phone number. Existing non-admin users with no phone number are routed through profile completion.

## Products

`products/{productId}` must include `creatorUid` and `creatorName` in addition to the catalogue fields. Checkout refuses products that do not identify their creator.

## Orders

The buyer cart is grouped by creator. One document is written to `orders/{orderId}` for each creator, and all documents from the same checkout share `checkoutId`.

Required fields:

- `checkoutId`, `buyerId`, `buyerName`, `buyerPhone`
- `creatorId`, `creatorName`
- `items`: product ID, name, creator ID/name, quantity, and captured unit price
- `shippingAddress`: recipient, phone, address line, city, state, and postal code
- `subtotal`
- `flatFee`, `commissionRate`, `commissionAmount`, `platformFee`
- `creatorNetAmount`
- `status`: `Placed`, `Accepted`, `Rejected`, `Shipped`, `Delivered`, `Completed`, or `Cancelled`
- `paymentStatus`: currently `skipped`
- `payoutStatus`: `pending`, `paid`, or `cancelled`
- `createdAt`, `updatedAt`, and `isSample`

Fee calculation is snapshotted when the order is placed:

```text
commission = subtotal > 999 ? subtotal × percentFee : 0
platformFee = flatFee + commission
creatorNetAmount = subtotal - platformFee
```

The fee is capped at the subtotal, so creator payout cannot become negative. Admin Finance derives platform balance and pending creator payouts directly from these order records.

## Support tickets

`support_tickets/{ticketId}` stores `userId`, `userRole`, `userName`, `subject`, `status`, `lastMessage`, `createdAt`, and `updatedAt`.

Conversation messages are stored at `support_tickets/{ticketId}/messages/{messageId}` with `senderId`, `senderRole`, `message`, and `createdAt`.

## Platform settings

`settings/platform_economics` stores `flatFee`, `percentFee`, and `updatedAt`.

## Sample data

The admin Orders panel exposes an action only in debug builds. It creates deterministic `sample-{creatorId}-{index}` order IDs with `isSample: true`. It never runs automatically.

## Deployment note

The repository includes `firestore.rules`, but code changes do not deploy those rules. Deployment must be reviewed and run separately. For a production payment system, trusted financial calculations should be moved from the client into a Cloud Function or another trusted backend.
