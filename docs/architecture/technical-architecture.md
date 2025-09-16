# Technical Architecture Documentation

This document outlines the technical architecture of the JengaMate application.

## 1. Overview

JengaMate is a Flutter-based mobile application that connects buyers and suppliers of construction materials. The application uses Firebase as its backend for authentication, database, and storage.

## 2. Frontend

- **Framework:** Flutter
- **State Management:** Provider
- **Routing:** Custom routing solution using `AppRoutes` class
- **UI Components:** Material Design

## 3. Backend

- **Authentication:** Firebase Authentication (Phone, Email/Password)
- **Database:** Cloud Firestore
- **Storage:** Firebase Storage (for identity documents, product images, etc.)
- **Cloud Functions:** (Not yet implemented) for server-side logic such as sending notifications, processing payments, etc.

## 4. Admin Panel

The admin panel is a set of screens within the main application that are only accessible to users with the `admin` role. The admin panel provides the following features:

- **Enhanced Analytics Dashboard:** Provides a comprehensive overview of the platform's performance.
- **Advanced User Management:** Allows administrators to manage users, including their roles, status, and identity verification.
- **Withdrawal Management:** Allows administrators to manage withdrawal requests from suppliers.
- **System Configuration:** Allows administrators to manage system-wide settings.
- **Content Moderation:** Allows administrators to review and moderate user-generated content.
- **Financial Oversight:** Allows administrators to view and manage financial transactions.
- **Advanced Reporting:** Allows administrators to generate and view various reports.

## 5. Database Schema

### `users`

- `uid` (String)
- `name` (String)
- `email` (String)
- `phone` (String)
- `role` (String: `buyer`, `supplier`, `admin`)
- `createdAt` (Timestamp)
- `updatedAt` (Timestamp)
- `lastLoginAt` (Timestamp)
- `isOnline` (bool)
- `isActive` (bool)
- `isVerified` (bool)
- `identityDocumentUrl` (String)
- `fcmToken` (String)

### `products`

- `id` (String)
- `name` (String)
- `description` (String)
- `price` (double)
- `imageUrl` (String)
- `categoryId` (String)
- `supplierId` (String)
- `createdAt` (Timestamp)
- `updatedAt` (Timestamp)

### `categories`

- `id` (String)
- `name` (String)
- `imageUrl` (String)

### `orders`

- `id` (String)
- `userId` (String)
- `supplierId` (String)
- `productId` (String)
- `quantity` (int)
- `totalPrice` (double)
- `status` (String: `pending`, `processing`, `shipped`, `delivered`, `cancelled`)
- `createdAt` (Timestamp)
- `updatedAt` (Timestamp)

### `withdrawals`

- `id` (String)
- `userId` (String)
- `amount` (double)
- `status` (String: `pending`, `approved`, `rejected`)
- `createdAt` (Timestamp)
- `processedAt` (Timestamp)

### `config`

- `system` (Document)
  - `commissionRate` (double)
  - `minimumWithdrawal` (double)
  - `maxRfqsPerDay` (int)
  - `requireApprovalForNewUsers` (bool)

### `moderation`

- `id` (String)
- `contentId` (String)
- `contentType` (String: `product`, `review`, `profile`)
- `content` (String)
- `userId` (String)
- `status` (String: `pending`, `approved`, `rejected`)
- `createdAt` (Timestamp)

### `transactions`

- `id` (String)
- `amount` (double)
- `type` (String: `purchase`, `withdrawal`, `commission`, `refund`)
- `userId` (String)
- `relatedId` (String)
- `createdAt` (Timestamp)