# eventbridge1

A new Flutter project.

## Social Login Setup (Google + Facebook)

### 1) Firebase Google Sign-In (Android)

1. Open Firebase Console > Authentication > Sign-in method and enable Google.
2. Open Firebase Console > Project settings > Android app `com.example.eventbridge1`.
3. Add SHA-1 and SHA-256 for both debug and release keys.
4. Download the new `google-services.json` and replace `android/app/google-services.json`.
5. Find your Web OAuth client ID in Firebase/Google Cloud (ends with `.apps.googleusercontent.com`).
6. Run the app with:

```bash
flutter clean
flutter pub get
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

### 2) Facebook Login (Android)

Update these values in `android/app/src/main/res/values/strings.xml`:

- `facebook_app_id`: your numeric Meta App ID
- `facebook_client_token`: your Meta client token
- `fb_login_protocol_scheme`: `fb` + your Meta App ID

Then update this authorities value in `android/app/src/main/AndroidManifest.xml`:

- `com.facebook.app.FacebookContentProvider000000000000000`
	replace trailing digits with your Meta App ID.

Meta console checklist:

1. Enable Facebook Login product.
2. Add Android package name `com.example.eventbridge1`.
3. Add Android key hashes for debug/release.
4. Make sure app is in Live mode (or your test user is added).

### 3) Admin Users Page (Firestore Permission-Denied Fix)

The admin panel now uses Firebase Authentication (email/password), not local demo-only checks.

1. In Firebase Console > Authentication > Users, create an admin account (example: `admin@eventbridge.app`).
2. Ensure your Firestore rules are deployed after the update in `firestore.rules`.

```bash
firebase deploy --only firestore:rules
```

3. Login from Admin Login screen with that Firebase admin account.

Note: The current rules treat `admin@eventbridge.app` as admin for reading/updating user documents.

### 4) Firestore Database Setup

1. Deploy the Firestore rules from [firestore.rules](firestore.rules).
2. Add the event documents from [scripts/events_seed.json](scripts/events_seed.json) to the `events` collection.
3. Make sure each new Firebase Auth user gets a matching document in `users/{uid}`. The app now creates that document automatically with `walletBalance`, `totalSpent`, and `eventsAttended` defaults.
4. For booking and wallet flows, the app writes to `users/{uid}/tickets` and `users/{uid}/wallet_transactions`.

Recommended rule deploy command:

```bash
firebase deploy --only firestore:rules
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
