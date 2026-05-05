# Project Context

## App Summary

This is a Flutter app named `tpm_ta` / `T-Shirt Studio`. The app theme is a T-shirt design, catalog, store, checkout, and production helper application.

## Features Already Working Correctly

- Login with hashed password authentication.
- Register new account.
- Session management using `flutter_secure_storage` with the `session_token` key.
- Biometric login using `local_auth`.
- Profile page with user email, phone, address, photo/avatar, profile editing, and biometric registration.
- Bottom navigation shell with Home, Stores, Minigame, Checkout, Feedback, Profile, and Logout.
- Logout flow that clears only the secure session token and returns to login.
- Home tab with external apparel products, product images, search, trending list, featured grid, and design preview.
- T-shirt canvas/design screen with template search, color/template selection, draggable sticker, shake color change, gyroscope tilt, AI slogan button, save snackbar, and 3D parallax preview navigation.
- Feedback screen for `Saran & Kesan Mata Kuliah TPM`.
- Checkout screen with currency display, delivery time estimates, mini-game discount flow, and order confirmation notification.
- Currency converter screen using static rates for IDR, USD, EUR, and GBP.
- Time zone converter screen with WIB, WITA, WIT, and London including UK daylight saving handling.
- Web service/API integration via Fake Store API apparel feed.
- Store locator map using `flutter_map` and OpenStreetMap tiles.
- GPS/LBS nearest branch screen using `geolocator`.
- Sensor integration using accelerometer and gyroscope in the canvas, parallax preview, and sensor print-check screen.
- AI/LLM feature via Gemini-powered design assistant screen using runtime API key input.
- Mini game: catch falling T-shirts for score/discount.
- Search/filter plus local notification screen for T-shirt drops.
- Local notification service initialized at app startup and used by checkout/search alert flows.

## Features Still Missing Based On Assignment Criteria

- No major assignment feature appears missing from the listed criteria. Implemented coverage exists for:
  - Bottom navigation bar.
  - Currency converter.
  - Time zone converter.
  - Web service/API integration.
  - LBS/location-based service.
  - Minimum two sensors.
  - AI/ML or LLM feature.
  - Mini game.
  - Search/filter and notifications.
- Possible polish/testing items still worth checking manually:
  - Real-device test for GPS permissions and location accuracy.
  - Real-device test for accelerometer/gyroscope behavior.
  - Real-device test for local notifications on Android/iOS permission behavior.
  - Real Gemini API key test for AI screens.
  - UI overflow check because the AppBar now has many action icons.

## Architecture Details

- Framework: Flutter / Dart.
- Dart SDK constraint: `^3.11.0`.
- Android namespace/applicationId: `com.example.tpm_ta`.
- Android minSdk: `flutter.minSdkVersion` from Flutter Gradle config.
- Android targetSdk/compileSdk: Flutter Gradle defaults via `flutter.targetSdkVersion` and `flutter.compileSdkVersion`.
- Java/Kotlin target: Java 17 / Kotlin JVM 17.
- State management: local `StatefulWidget` state with `setState`; no Provider/Riverpod/GetX/BLoC package is used.
- Database: SQLite via `sqflite`.
- Database file: `tshirt_app.db`.
- Database version: `3`.
- Tables:
  - `users`: id, username, email, password_hash, biometric_registered, phone, address.
  - `saved_designs`: id, user_id, design_name, layout_json_data, created_at.
- Password handling: SHA-256 hashing via `crypto`.
- Session storage: `flutter_secure_storage`, key `session_token`, value is the user id as string.
- Biometric auth: `local_auth`.
- Maps: `flutter_map` with `latlong2` and OpenStreetMap tile URLs.
- GPS/location: `geolocator`.
- Sensors: `sensors_plus`.
- HTTP/API: `http`.
- AI/LLM: `google_generative_ai` and an older HTTP-based `AIChatService` placeholder.
- Notifications: `flutter_local_notifications`.
- Android permissions currently include:
  - `USE_BIOMETRIC`
  - `USE_FINGERPRINT`
  - `ACCESS_FINE_LOCATION`
  - `ACCESS_COARSE_LOCATION`
- iOS permission currently includes:
  - `NSLocationWhenInUseUsageDescription`

## Packages Used

- `cupertino_icons`
- `sqflite`
- `path`
- `local_auth`
- `sensors_plus`
- `http`
- `flutter_map`
- `latlong2`
- `geolocator`
- `crypto`
- `flutter_secure_storage`
- `google_generative_ai`
- `flutter_local_notifications`
- Dev dependency: `flutter_lints`

## Key File Structure

### Root / Config

- `pubspec.yaml`: app metadata, Dart SDK constraint, dependencies.
- `lib/main.dart`: initializes Flutter bindings, initializes notifications, reads secure session token, chooses `MainScreen` or `LoginScreen`.
- `android/app/src/main/AndroidManifest.xml`: Android app manifest and permissions.
- `android/app/build.gradle.kts`: Android app Gradle config, SDK values, Java 17, desugaring.

### Services

- `lib/services/database_helper.dart`: SQLite singleton, schema creation/upgrades, user CRUD, saved design CRUD, biometric status update.
- `lib/services/auth_service.dart`: register/login, SHA-256 password hashing, secure session write, biometric login helpers.
- `lib/services/notification_service.dart`: local notification initialization and `showNotification`.
- `lib/services/apparel_api_service.dart`: Fake Store API apparel fetching and parsing.
- `lib/services/ai_chat_service.dart`: HTTP Gemini chat service placeholder with `YOUR_GEMINI_API_KEY`; currently separate from the runtime-key AI assistant screen.
- `lib/services/network_service.dart`: currently empty.

### Screens

- `lib/screens/login_screen.dart`: login/register UI, biometric login visibility, navigation to main app.
- `lib/screens/main_screen.dart`: app shell, AppBar shortcuts, bottom navigation, logout flow, embedded profile tab/profile screen.
- `lib/screens/home_tab.dart`: home catalog, external product fetch, search, product card, design preview.
- `lib/screens/tshirt_canvas_screen.dart`: design canvas, template search, sensor-driven color/tilt, draggable sticker, AI slogan generation.
- `lib/screens/parallax_preview_screen.dart`: accelerometer/gyroscope 3D parallax preview.
- `lib/screens/checkout_screen.dart`: order summary, currency display, delivery time, mini-game discount, notification on payment.
- `lib/screens/feedback_screen.dart`: TPM course feedback form.
- `lib/screens/store_locator_screen.dart`: branch map and store status/local time list.
- `lib/screens/mini_game_screen.dart`: falling T-shirt catch game.
- `lib/screens/currency_converter_screen.dart`: standalone currency converter.
- `lib/screens/time_zone_converter_screen.dart`: standalone time zone converter.
- `lib/screens/api_catalog_screen.dart`: live apparel API UI.
- `lib/screens/location_service_screen.dart`: GPS nearest branch feature.
- `lib/screens/sensor_quality_screen.dart`: accelerometer/gyroscope print stability check.
- `lib/screens/ai_design_assistant_screen.dart`: Gemini-powered design recommendation screen with runtime API key.
- `lib/screens/search_filter_notification_screen.dart`: searchable/filterable T-shirt drops with local notification action.

## Strict Rules To Follow

- Never modify, refactor, or rewrite code that is already working correctly.
- Before making any change, read and understand the full context of relevant files.
- Always re-read the current state of a file before editing it.
- Prefer adding new isolated files/widgets for new features.
- Existing code may be modified only under these conditions:
  - The code is broken: runtime error, crash, exception, compile/build failure, or integration break.
  - The code is dead/useless: unreachable code, duplicate code already handled elsewhere, or unused import/variable/function.
- Before modifying existing code under those exceptions:
  - Show the exact line(s) to change.
  - Explain why it qualifies as broken or dead code.
  - Wait for user confirmation.
  - After fixing, confirm nothing outside the fix was touched.
- If a feature requires integration with existing code, ask for approval before editing that existing file.
- Do not refactor because it looks cleaner or "better".
- Do not assume future risk is enough reason to change working code.
- Work one feature at a time and wait for user confirmation before moving to the next feature.
- If unsure whether a change might break something, ask first.

## Current Progress Status

- Feature 1, Bottom Navigation Bar: implemented and user-confirmed working.
- Feature 2, Currency Converter: implemented and user-confirmed working.
- Feature 3, Time Zone Converter: implemented and wired.
- Feature 4, Web Service/API Integration: implemented and wired.
- Feature 5, LBS/Location-Based Service: implemented and wired.
- Feature 6, Sensor Integration: implemented and wired.
- Feature 7, AI/ML or LLM Feature: implemented and wired.
- Feature 8, Mini Game: already existed and analyzer-verified.
- Feature 9, Search & Filter + Notifications: implemented and wired.
- Latest analyzer result for `lib`: no errors, only deprecation info in two new dropdown usages:
  - `currency_converter_screen.dart`
  - `time_zone_converter_screen.dart`
- Those deprecation notes are not build-breaking and were not changed under the strict rules.

## Notes For Next Work

- Continue preserving login/register/biometric/profile/session behavior.
- The AppBar has many shortcut icons; if UI overflow occurs, ask before changing `main_screen.dart`.
- `network_service.dart` is empty; do not remove or repurpose it without approval.
- `AIChatService` contains a placeholder API key and is not the same as the runtime-key AI assistant screen.
- Generated plugin files changed after adding `geolocator` through `flutter pub get`.
