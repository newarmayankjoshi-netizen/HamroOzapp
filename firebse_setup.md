# Firebase setup (copy)

This file was added at the user's request. It duplicates the existing Firebase setup documentation (FIREBASE_SETUP.md) to provide a lowercase/alternate filename.

See the canonical instructions in FIREBASE_SETUP.md for full steps to configure Android/iOS, generate `firebase_options.dart`, and deploy Firestore rules.

Quick checklist:

- Create/select a Firebase project in the Console.
- Add Android app and place `google-services.json` into `android/app/`.
- Add iOS app and place `GoogleService-Info.plist` into `ios/Runner/`.
- Optionally run `flutterfire configure` to generate `lib/firebase_options.dart`.
- Install `firebase-tools`, run `firebase login`, then deploy rules with `firebase deploy --only firestore:rules`.

Note: There is already a file named FIREBASE_SETUP.md in the project root; this file is an intentionally duplicated copy (per request).
