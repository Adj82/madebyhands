# MADEBYHANDS shared Firestore contract (v1)

Status: **proposed for team approval**  
Consumers: buyer, creator, admin, Firestore rules, and trusted backend services  
Schema version: `1`

This is the single data contract for all three panels. Firestore is schemaless,
but the application is not: every panel must use these exact collection names,
field names, types, and enum values.

## Team rules

1. Use `lowerCamelCase` fields and plural `snake_case` collection names.
2. Store enum values in lowercase `snake_case`; UI labels are presentation only.
3. Store MVP money as whole INR integers, not formatted strings.
4. Store dates as Firestore `Timestamp`, never formatted strings.
5. Store addresses as maps, never as one string.
6. Represent a missing optional value with `null`/omission, not `"N/A"`.
7. New writes use only this schema; legacy names are read only during migration.
8. All panels share the same typed model/repository mapper. Screens must not cast
   raw Firestore maps independently.
9. Shared documents contain `schemaVersion: 1`.

## Canonical enums

- User role: `buyer`, `creator`, `manager`, `super_admin`
- Creator verification: `unverified`, `pending`, `verified`, `rejected`
- Product approval: `pending`, `approved`, `rejected`
- Order status: `placed`, `confirmed`, `processing`, `shipped`, `in_transit`,
  `out_for_delivery`, `delivered`, `rejected`, `cancelled`
- Payment status: `skipped`, `pending`, `paid`, `failed`, `refunded`
- Payout status: `pending`, `eligible`, `paid`, `cancelled`
- Support status: `open`, `resolved`

`delivered`, `rejected`, and `cancelled` are terminal order states. Payout
completion is represented by `payoutStatus`, not another order status.

## `users/{userId}`

| Field | Type | Required | Notes |
|---|---|---:|---|
| `schemaVersion` | integer | yes | Always `1` |
| `uid` | string | yes | Same as document ID |
| `name` | string | yes | Display name |
| `email` | string | yes | Lowercase where possible |
| `phone` | string | yes | Ten digits for buyer/creator |
| `role` | enum string | yes | Canonical role |
| `isVerified` | boolean | yes | Creator verification shortcut |
| `isSuspended` | boolean | yes | Canonical account restriction field |
| `createdAt` | timestamp | yes | Server timestamp |
| `updatedAt` | timestamp | yes | Server timestamp |

Do not use `isActive` for user suspension. `isActive` is reserved for products.
The legacy role `admin` must be migrated to `manager` or `super_admin`.

## `creator_profiles/{creatorId}`

Required fields are `schemaVersion`, `uid`, `name`, `businessName`, `bio`,
`category`, `location`, `socialLinks` (array), `portfolio` (URL array), `story`,
`verificationStatus`, `createdAt`, and `updatedAt`.

Optional fields are `profileImage`, `address`, `latestPhoto`, and `idCard`.
Private verification files must not be exposed by public-profile queries.

## `products/{productId}`

| Field | Type | Required | Notes |
|---|---|---:|---|
| `schemaVersion` | integer | yes | Always `1` |
| `name` | string | yes | Product name |
| `description` | string | yes | Product description |
| `images` | URL array | yes | First image is cover |
| `category` | string | yes | Matches a category |
| `price` | integer | yes | Base INR price |
| `stock` | integer | yes | Must be `>= 0` |
| `materials` | string | no | Product materials |
| `dimensions` | string | no | Human-readable |
| `weight` | string | no | Human-readable |
| `shippingInfo` | string | no | Estimate/details |
| `creatorId` | string | yes | Canonical creator UID |
| `creatorName` | string | yes | Display snapshot |
| `approvalStatus` | enum string | yes | Product approval |
| `isActive` | boolean | yes | Catalogue visibility |
| `isCustomizable` | boolean | yes | Defaults to `false` |
| `customizations` | map array | yes | Empty when unsupported |
| `ratingAverage` | number | yes | Defaults to `0` |
| `ratingCount` | integer | yes | Defaults to `0` |
| `wishlistCount` | integer | yes | Defaults to `0` |
| `orderCount` | integer | yes | Defaults to `0` |
| `approvedBy` | string | no | Admin UID |
| `approvedAt` | timestamp | no | Approval time |
| `createdAt` | timestamp | yes | Server timestamp |
| `updatedAt` | timestamp | yes | Server timestamp |

Each `customizations` map contains `name`, `description`, `additionalPrice`
(integer), `images` (URL array), `isMultipleSelection`, and `options` (array).

Do not use `creatorUid`, `sellerId`, `sellerName`, `artisan`, or product `status`
in new writes. Use `creatorId`, `creatorName`, and `approvalStatus`.

## `orders/{orderId}`

One checkout may contain multiple creators. Write one order per creator and use
the same `checkoutId` for all orders created by that checkout.

### Identity snapshots

| Field | Type | Required |
|---|---|---:|
| `schemaVersion` | integer | yes |
| `checkoutId` | string | yes |
| `buyerId` | string | yes |
| `buyerName` | string | yes |
| `buyerEmail` | string | yes |
| `buyerPhone` | string | yes |
| `creatorId` | string | yes |
| `creatorName` | string | yes |
| `creatorEmail` | string | no |
| `creatorPhone` | string | no |

### Items

`items` is an array of immutable purchase snapshots:

```text
productId: string
name: string
imageUrl: string | null
creatorId: string
creatorName: string
quantity: integer (> 0)
baseUnitPrice: integer
customizationUnitAmount: integer
unitPrice: integer
lineTotal: integer
customizations: array<map>
```

`unitPrice = baseUnitPrice + customizationUnitAmount`  
`lineTotal = unitPrice * quantity`

### Shipping address

`shippingAddress` is always a map:

```text
label: string | null
recipientName: string
phone: string
addressLine: string
city: string
state: string
postalCode: string
```

### Amounts and finance

| Field | Type | Required | Meaning |
|---|---|---:|---|
| `subtotal` | integer | yes | Sum of item line totals |
| `shippingAmount` | integer | yes | `0` until applicable |
| `buyerPayableAmount` | integer | yes | Amount shown/charged to buyer |
| `flatFee` | integer | yes | Snapshotted flat fee |
| `commissionRate` | number | yes | Percentage such as `5` |
| `commissionAmount` | integer | yes | Calculated commission |
| `platformFee` | integer | yes | Flat fee plus commission |
| `creatorNetAmount` | integer | yes | Pending creator payout |

Current approved MVP calculation:

```text
subtotal = sum(items.lineTotal)
buyerPayableAmount = subtotal + shippingAmount
commissionAmount = subtotal > 999 ? round(subtotal * commissionRate / 100) : 0
platformFee = min(subtotal, flatFee + commissionAmount)
creatorNetAmount = subtotal - platformFee
```

Before payment integration, the product owner must confirm whether the ₹50 fee
is deducted from creator proceeds, as above, or added to the buyer payable
amount. All panels must follow one approved interpretation.

### Lifecycle and tracking

| Field | Type | Required |
|---|---|---:|
| `status` | order-status enum | yes |
| `paymentStatus` | payment-status enum | yes |
| `payoutStatus` | payout-status enum | yes |
| `rejectionReason` | string | no |
| `carrierName` | string | no |
| `consignmentNumber` | string | no |
| `trackingUrl` | string URL | no |
| `lastLocation` | string | no |
| `trackingUpdatedAt` | timestamp | no |
| `createdAt` | timestamp | yes |
| `updatedAt` | timestamp | yes |
| `paidAt` | timestamp | no |
| `deliveredAt` | timestamp | no |
| `isSample` | boolean | yes |

### Example order

```text
schemaVersion: 1
checkoutId: "CHK-abc123"
buyerId: "buyerUid"
buyerName: "Suhani"
buyerEmail: "buyer@example.com"
buyerPhone: "9876543210"
creatorId: "creatorUid"
creatorName: "Asha Weaves"
items: [
  {
    productId: "productId",
    name: "Handwoven Basket",
    imageUrl: null,
    creatorId: "creatorUid",
    creatorName: "Asha Weaves",
    quantity: 1,
    baseUnitPrice: 1200,
    customizationUnitAmount: 0,
    unitPrice: 1200,
    lineTotal: 1200,
    customizations: []
  }
]
shippingAddress: {
  label: "Home",
  recipientName: "Suhani",
  phone: "9876543210",
  addressLine: "21 Craft Lane",
  city: "Jaipur",
  state: "Rajasthan",
  postalCode: "302001"
}
subtotal: 1200
shippingAmount: 0
buyerPayableAmount: 1200
flatFee: 50
commissionRate: 5
commissionAmount: 60
platformFee: 110
creatorNetAmount: 1090
status: "placed"
paymentStatus: "skipped"
payoutStatus: "pending"
isSample: false
createdAt: <server timestamp>
updatedAt: <server timestamp>
```

### Order field ownership

| Actor | Allowed responsibility |
|---|---|
| Buyer | Create identity, items, address, immutable totals, `placed`, and permitted payment status |
| Creator | Allowed fulfillment transitions and rejection/tracking fields |
| Manager | Fulfillment/support operations allowed by role |
| Super admin | Corrections and payout fields |
| Trusted payment backend | Payment identifiers, status, and timestamps |

No panel may recalculate historical order totals after creation. Prices and fees
are immutable snapshots.

## Buyer subcollections

### `users/{userId}/favorites/{productId}`

```text
schemaVersion: 1
productId: string
createdAt: timestamp
```

Use the product ID as the document ID for idempotent writes.

### `users/{userId}/addresses/{addressId}`

```text
schemaVersion: 1
label: string
recipientName: string
phone: string
addressLine: string
city: string
state: string
postalCode: string
isDefault: boolean
createdAt: timestamp
updatedAt: timestamp
```

Only one address per user may have `isDefault: true`.

## Support tickets

`support_tickets/{ticketId}` contains `schemaVersion`, `userId`, `userRole`,
`userName`, `subject`, `status`, `lastMessage`, `createdAt`, and `updatedAt`.

`support_tickets/{ticketId}/messages/{messageId}` contains `schemaVersion`,
`senderId`, `senderRole`, `message`, and `createdAt`.

## Categories and settings

Use a lowercase category slug as `categories/{categoryId}`, for example
`home_decor`. Each document contains `schemaVersion`, `name`, `slug`,
`isActive`, `sortOrder`, `createdAt`, and `updatedAt`.

`settings/platform_economics` contains:

```text
schemaVersion: 1
flatFee: integer
commissionRate: number
updatedAt: timestamp
updatedBy: string
```

Use `commissionRate`, not `percentFee`, in new writes.

## Reserved SRS collections

These names are reserved but need a separately approved detailed contract:

- `products/{productId}/reviews/{reviewId}`
- `users/{userId}/notifications/{notificationId}`
- `conversations/{conversationId}/messages/{messageId}`

## Legacy compatibility map

Readers may temporarily accept these aliases. Writers must not create them.

| Legacy | Canonical |
|---|---|
| product `creatorUid` | `creatorId` |
| `sellerId` | `creatorId` |
| `sellerName`, `artisan` | `creatorName` |
| product `status` | `approvalStatus` |
| order `totalAmount`, `total` | `buyerPayableAmount`, then fall back to `subtotal` |
| `payoutAmount` | `creatorNetAmount` |
| `deliveryAddress` string | `shippingAddress` map |
| `Placed`, `Pending` | `placed` |
| `Accepted`, `Confirmed` | `confirmed` |
| `Processing` | `processing` |
| `Shipped` | `shipped` |
| `In Transit`, `In-transit` | `in_transit` |
| `Out for Delivery` | `out_for_delivery` |
| `Delivered`, `Completed` | `delivered` |
| `Rejected` | `rejected` |
| `Cancelled` | `cancelled` |
| settings `percentFee` | `commissionRate` |

## Adoption plan

1. All three developers approve this contract before changing code.
2. Freeze new Firestore field names until approval is complete.
3. Create one shared model/mapper and enum helpers under `features/orders`.
4. Add temporary legacy read fallbacks from the compatibility table.
5. Update all writers to write canonical fields only.
6. Update all screens to consume typed shared models, not raw maps.
7. Backfill existing documents using a reviewed migration script.
8. Separately approve/deploy updated Firestore rules and indexes.
9. Remove legacy fallbacks only after production data is verified.

This document does not deploy rules, migrate data, or change Firebase access.
Financial calculations and payment state should eventually move to a trusted
backend instead of running exclusively in client applications.
