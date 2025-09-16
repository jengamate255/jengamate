# Priority Feature Technical Specifications

This document provides detailed technical specifications for the high-priority features outlined in the `implementation_plan.md`.

## 1. Fix Chat Navigation Bug

-   **File to Modify:** `lib/config/app_routes.dart`
-   **Problem:** The `ChatConversationScreen` route is defined without accepting the necessary `chatId` and `recipientId` arguments.
-   **Solution:**
    1.  Modify the `AppRoutes.routes` map.
    2.  Change the route definition for `ChatConversationScreen` to extract arguments from `settings.arguments`.
    3.  The arguments will be passed as a `Map<String, String>`.
    4.  Update the `onGenerateRoute` logic to handle this change.

    ```dart
    // Example of the corrected route definition
    case AppRoutes.chatConversation:
      final args = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          chatId: args['chatId']!,
          recipientId: args['recipientId']!,
        ),
      );
    ```

## 2. Implement Core Screens (Settings & Help)

### 2.1 Settings Screen

-   **File to Create/Modify:** `lib/screens/settings_screen.dart`
-   **Task:**
    1.  Create a stateful widget `SettingsScreen`.
    2.  Implement a simple UI with a switch for theme toggling (light/dark).
    3.  Use the existing `ThemeService` to manage and persist the theme state.
    4.  Add a section for "Account Settings" which will navigate to the `EditProfileScreen`.
    5.  Add a "Logout" button that triggers the logout functionality.

### 2.2 Help Screen

-   **File to Create/Modify:** `lib/screens/help_screen.dart`
-   **Task:**
    1.  Create a stateless widget `HelpScreen`.
    2.  Display a simple FAQ section with common questions and answers.
    3.  Include a "Contact Support" button that opens the user's email client with a pre-filled support email address.

## 3. Implement Logout Functionality

-   **Files to Modify:** `lib/services/auth_service.dart`, `lib/widgets/navigation_helper.dart`, and all files with a "Logout" button.
-   **Task:**
    1.  In `AuthService`, create a `signOut` method that calls `FirebaseAuth.instance.signOut()`.
    2.  In `NavigationHelper`, create a `logout` method that calls `AuthService.signOut()` and then navigates the user to the `LoginScreen`, clearing the navigation stack.
    3.  Connect this `logout` method to all logout buttons in the UI.

---

These specifications should be sufficient for a developer to begin implementation. Do you approve this plan?