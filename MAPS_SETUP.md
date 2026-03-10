# Google Maps Setup Instructions

## Prerequisites
You need a Google Maps API key to use the map features in this app.

## Getting Your API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geolocation API
4. Go to "Credentials" and create an API key
5. Restrict your API key (recommended):
   - For Android: Add your app's package name and SHA-1 fingerprint
   - For iOS: Add your app's bundle identifier

## Adding the API Key to Your App

### Android
1. Open `android/app/src/main/AndroidManifest.xml`
2. Find this line:
   ```xml
   android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
   ```
3. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key

### iOS
1. Open `ios/Runner/AppDelegate.swift`
2. Add this import at the top:
   ```swift
   import GoogleMaps
   ```
3. Add this line in the `application` function before `GeneratedPluginRegistrant.register`:
   ```swift
   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
   ```

## Testing

### Get SHA-1 Fingerprint (Android)
```bash
cd android
./gradlew signingReport
```

### Run the app
```bash
flutter run
```

## Features Implemented

### In Create Room Page:
- "Add Current Location" button to get GPS coordinates
- Shows a small map preview when location is added
- Displays latitude and longitude
- Option to remove location before posting

### In Room Detail Page:
- Displays interactive Google Map if location was shared
- Shows marker at the property location
- Includes zoom controls and map toolbar
- Disclaimer about approximate location

## Privacy Note
Location sharing is optional. Users can post rooms without sharing map location.
