# Shared Firestore schema

This contract is shared by the buyer, creator and admin panels and by the
payment API (`api/` + `server/`). Firestore is schemaless, so the app models,
repository mappers and `firestore.rules` enforce these fields. All amounts are
**integer rupees**; paise exist only at the Razorpay boundary.

## Users — `users/{uid}`

`uid`, `email`, `name`, `phone`, `role`, `isVerified`, `isSuspended`,
`createdAt`, `updatedAt`.

- `role`: `buyer`, `creator` (`seller` is a legacy alias), `manager`,
  `super_admin` (legacy `admin` is a manager unless the email is on the root
  super-admin list in `firestore.rules`).
- Users may change only `name`, `phone`, `email`, `updatedAt` on their own
  document. Managers may suspend/verify but never change roles; only super
  admins change roles.
- Subcollections: `favorites/{productId}` and `addresses/{addressId}` (owner only).

## Creator profiles — `creator_profiles/{uid}` (public)

`uid`, `name`, `businessName`, `profileImage`, `bio`, `location`,
`socialLinks[]`, `portfolio[]`, `story`, `verificationStatus`,
`verificationNote`, `createdAt`, `updatedAt`.

Profiles are not asked for a craft category at sign-up or anywhere else;
older docs may still carry a stale `category` string from before this was
removed, but nothing reads it.

- `verificationStatus`: `Unverified` → `In-Process` (documents submitted) →
  `Verified` or `Rejected` (with `verificationNote`). Creators can only set
  `Unverified`/`In-Process`; admins decide.
- Profile edits merge the editable fields only, so they never reset the
  verification status.

## Verification documents — `creator_verifications/{uid}` (private)

`uid`, `businessName`, `address`, `latestPhoto`, `idCard`, `submittedAt`.
Readable by the creator and admins only. Older profiles kept these fields on
the public profile; the admin review screen falls back to them.

## Payout details — `creator_bank_accounts/{uid}` (private)

`accountHolderName`, `accountNumber`, `accountType`, `bankName`, `branchName`,
`ifscCode`, `upiId?`, `panNumber?`, `createdAt`, `updatedAt`. Written by the
creator; readable by the creator and super admins (Finance).

## Products — `products/{productId}`

`name`, `description`, `images[]`, `category` (display string),
`categories[]` (1–2 names from the `categories` collection), `price`, `stock`,
`materials`, `dimensions`, `weight`, `shippingInfo`, `creatorUid`,
`creatorName`, `status`, `isActive`, `isCustomizable`, `isFramed?`,
`customizations[]`, `predefinedCustomizations[]`, `orderCount`,
`wishlistCount`, `approvedBy`, `approvedByEmail`, `approvedAt`,
`rejectionReason`, `editHistory`, `createdAt`, `updatedAt`.

- Only verified creators may create products; new and edited listings are
  `status: 'Pending Approval'`, `isActive: false` until an admin approves.
- Creators may publish/unpublish an approved listing (`isActive`) and change
  `stock` without another review.
- `orderCount` is incremented by the payment API; `wishlistCount` moves by ±1
  when shoppers save/unsave. The home feed ranks "Popular picks" by
  `orderCount × 3 + wishlistCount`.
- Each customization: `name`, `description`, `additionalPrice`, `images[]`,
  `isMultipleSelection`, `options[]` (empty options = free-text input).
- Reviews: `products/{productId}/reviews/{buyerId}` with `rating` (1–5),
  `comment`, `buyerName`, `createdAt`/`updatedAt`; only buyers with a
  delivered purchase can review.

## Categories — `categories/{slug}`

`name`. Managed by admins; seeded from `kProductCategories`
(`lib/core/constants/product_categories.dart`) on first admin load. Buyers and
creators fall back to the same default list.

## Orders — `orders/{orderId}`

Created **only** by `/api/finalize-payment` (Admin SDK). One document per
creator; all documents from one checkout share `checkoutId`.

- `checkoutId` (the Razorpay order id), `paymentId`, `buyerId`, `buyerName`,
  `buyerEmail`, `buyerPhone`, `creatorId`, `creatorName`
- `items[]`: `productId`, `name`, `category`, `image`, `creatorId`,
  `creatorName`, `quantity`, `baseUnitPrice`, `customizationPrice`,
  `unitPrice`, `customizations` (map of name → values)
- `shippingAddress`: `recipientName`, `phone`, `addressLine`, `city`, `state`,
  `postalCode`
- `subtotal`, `flatFee`, `commissionRate`, `commissionAmount`, `platformFee`,
  `creatorNetAmount`, `buyerPayableAmount`
- `status`: `Placed` → `Confirmed` → `Processing` → `In-Transit` → `Shipped`
  → `Out for Delivery` → `Delivered`, or `Rejected`. Older records may hold
  `pending`, `Accepted`, `Completed`; always compare through `OrderStatus`.
- `carrierName`, `consignmentNumber` (set when moving to In-Transit),
  `deliveredAt`, `rejectionReason`, `rejectedBy`
- `paymentStatus`: `paid`; `payoutStatus`: `pending` → `paid` (recorded by a
  super admin in Finance after delivery) or `cancelled`; `payoutReleasedAt`
- `refundStatus`: `processing`, `refunded` or `failed` (+ `refundId`,
  `refundedAmount`) after a rejection
- `stockReserved`, `isSample`, `createdAt`, `updatedAt`

Fees are snapshotted when the order is placed (`server/fees.js`, mirrored by
`PlatformFeeCalculator`):

```text
commission       = subtotal > commissionThreshold ? round(subtotal × percentFee / 100) : 0
buyer pays       = subtotal + flatFee          (flatFee per creator)
platformFee      = flatFee + commission
creatorNetAmount = subtotal - commission
```

`commissionThreshold` defaults to 999 but, like `flatFee`/`percentFee`, is
admin-configurable (see Platform settings below).

Creators may update only `status` (forward fulfilment values),
`consignmentNumber`, `carrierName`, `deliveredAt`, `updatedAt`. Rejections go
through `/api/reject-order`, which restores stock and refunds the buyer.

## Payment records (API only)

- `paymentIntents/{razorpayOrderId}`: priced cart snapshot, status
  `pending` → `paid` / `refunded`.
- `paymentReceipts/{paymentId}`: idempotency key for finalize.

Both are `allow read, write: if false` for clients.

## Notifications — `notifications/{id}`

`type`, `title`, `message`, `createdAt`, `isRead`, plus `creatorUid` (creator
inbox), `userId` (buyer inbox) or neither with `type: 'admin'` (admin bell;
`category`, `targetId`). Owners may only flip `isRead` or delete their own.

## Support tickets — `support_tickets/{ticketId}`

`userId`, `userRole`, `userName`, `subject`, `type`, `status` (`open` /
`resolved`), `lastMessage`, `createdAt`, `updatedAt`. Messages live in
`support_tickets/{ticketId}/messages/{messageId}` with `senderId` (the real
uid), `senderRole`, `message`, `createdAt`.

## Platform settings — `settings/platform_economics`

`flatFee`, `percentFee`, `commissionThreshold`, `updatedAt`. Written by super
admins only; read by checkout and the payment API (defaults 50, 5, and 999
respectively). All three are editable from Admin → Settings → Platform
economics.

## Deployment note

`firestore.rules` is load-bearing. Deploy it together with the API:
`firebase deploy --only firestore:rules`.
