# Firebase Setup (Business Booster)

This app already includes Firebase packages and a best-effort bootstrap init.
To actually use Firestore across devices + enforce ownership server-side, you must add Firebase config files and deploy Firestore rules.

## 1) Create Firebase project
- Go to Firebase Console → create/select a project.

## 2) Add Android config
- Firebase Console → Project settings → Your apps → Android → Register app
- Use your Android applicationId (from `android/app/build.gradle.kts`).
- Download `google-services.json`
- Place it at:
  - `android/app/google-services.json`

Note: Android is already configured to apply the Google Services Gradle plugin.

## 3) Add iOS config
- Firebase Console → Project settings → Your apps → iOS → Register app
- Use your iOS bundle id (from Xcode Runner target).
- Download `GoogleService-Info.plist`
- Place it at:
  - `ios/Runner/GoogleService-Info.plist`

## 3b) Generate `firebase_options.dart` (recommended)
This project supports FlutterFire options for both Android and iOS.

Run:
- `dart pub global activate flutterfire_cli`
- `flutterfire configure --platforms=android,ios`

This will generate/overwrite:
- `lib/firebase_options.dart`

## 4) Deploy Firestore security rules
This repo contains Firestore rules at:
- `firestore.rules`

Deploy using Firebase CLI:
1. Install:
   - `npm i -g firebase-tools`
2. Login:
   - `firebase login`
3. Initialize (one-time):
   - `firebase init firestore`
   - When prompted, choose **existing project** and point rules file to `firestore.rules`
4. Deploy:
   - `firebase deploy --only firestore:rules`

## Ownership rule
The owner-only access is enforced by the `ownerUserId` field stored on each document in the `owner_restaurants` collection.

Rules allow access if:
- `ownerUserId == request.auth.uid` (preferred), OR
- `ownerUserId == request.auth.token.email` (temporary bridge while the app is still using the existing login identity)

## Recommended next improvement
To make ownership robust, the app should authenticate using Firebase Auth and store `ownerUserId = request.auth.uid` for all Firestore writes.
