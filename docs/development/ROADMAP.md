# Jengamate Application Roadmap

This document outlines the features and tasks required to bring the Jengamate application to a fully functional state.

## Phase 1: Foundational Features

### 1.1. Role-Based Access Control (RBAC)
- [ ] Implement UI changes based on user roles (`Engineer`, `Supplier`, `Admin`).
- [ ] Secure Firestore rules to restrict data access based on roles.
- [ ] Show/hide navigation items and screen elements (e.g., Admin Tools) dynamically.

### 1.2. Dynamic Data Integration
- [ ] Replace mock data in the `Orders` screen with real data from Firestore.
- [ ] Replace mock data in the `Products` screen with real data from Firestore.
- [ ] Replace mock data in the `Categories` screen with real data from Firestore.
- [ ] Replace mock data in the `Commission` screen with real data from Firestore.
- [ ] Fetch and display real-time order/commission stats on the `Dashboard`.

## Phase 2: Core Functionality

### 2.1. Order Management
- [ ] Implement "Pay Now" functionality on orders.
- [ ] Implement order status updates (e.g., `Pending` -> `In Progress` -> `Completed`).
- [ ] Allow users to view order details.

### 2.2. Product Management
- [ ] Implement product search and filtering on the `Products` screen.
- [ ] Create a screen to view detailed product information.

### 2.3. Withdrawals
- [ ] Implement the "Withdrawals" feature, allowing users to request payouts.
- [ ] Connect the feature to the backend to record withdrawal requests.

## Phase 3: Admin Features

### 3.1. User Management
- [ ] Create an admin screen to view and manage all users.
- [ ] Allow admins to assign roles to users.

### 3.2. Product Catalog Management
- [ ] Enable admins to add, edit, and delete products from the `Admin Tools` screen.
- [ ] Enable admins to manage product categories.

### 3.3. Order and Inquiry Management
- [ ] Create an admin view to see all orders and inquiries in the system.
- [ ] Allow admins to update order statuses.

## Phase 4: Finalization

### 4.1. Testing
- [ ] Write unit and widget tests for critical services and UI components.
- [ ] Conduct end-to-end testing of all user flows.

### 4.2. Bug Fixing and Polishing
- [ ] Address any remaining bugs.
- [ ] Polish the UI and UX for a smooth and professional feel. 

### Future Enhancements

- **Real-time Notifications:** Implement real-time notifications for inquiries, orders, and approvals.
- **Advanced Analytics:** Provide more detailed analytics and reporting for suppliers and admins.
- **Offline Support:** Cache essential data to allow for limited functionality when the user is offline.
- **Multi-language Support:** Add support for multiple languages to cater to a diverse user base.
- **Re-implement Approval Logic:** The user approval and error handling logic was temporarily removed to resolve a login issue. This needs to be re-implemented in a more robust way. 