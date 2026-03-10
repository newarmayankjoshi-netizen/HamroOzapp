import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([super.locale = 'en']);

  @override
  String get appTitle => 'HamroOZ';

  @override
  String get home => 'Home';

  @override
  String get messages => 'Messages';

  @override
  String get calendar => 'Calendar';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get logout => 'Logout';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get autoDownloadImages => 'Auto-download Images';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheConfirm => 'This will clear all cached images and data. Continue?';

  @override
  String get adzunaApi => 'Adzuna API (Jobs)';

  @override
  String get save => 'Save';

  @override
  String get clear => 'Clear';

  @override
  String get exportData => 'Export My Data';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get aboutApp => 'About App';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get version => 'Version';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get systemDefault => 'System Default';

  @override
  String get english => 'English';

  @override
  String get nepali => 'नेपाली (Nepali)';

  @override
  String themeChanged(Object themeName) => 'Theme changed to $themeName';

  @override
  String languageChanged(Object languageName) => 'Language changed to $languageName';

  @override
  String tooManyFailedLoginAttempts(Object minutes) => 'Too many failed login attempts. Please try again in $minutes minutes.';

  @override
  String get passwordResetSent => 'Password reset link sent to your email';

  @override
  String welcomeBack(Object name) => 'Welcome back, $name!';

  @override
  String loginError(Object error) => 'Login error: $error';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String welcome(Object name) => 'Welcome, $name!';

  @override
  String get googleSignInFailed => 'Google sign-in failed or was cancelled';

  @override
  String get appleSignInFailed => 'Apple sign-in failed or was cancelled';

  @override
  String get signIn => 'Sign In';

  @override
  String get newUser => 'New User?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get or => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get pleaseAgreeTerms => 'Please agree to Terms and Conditions';

  @override
  String get registrationSuccess => 'Registration successful! Please login.';

  @override
  String get emailAlreadyRegistered => 'Email already registered. Please login.';

  @override
  String get emailLabel => 'Email Address *';

  @override
  String get emailHint => 'your.email@example.com';

  @override
  String get passwordLabel => 'Password *';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String passwordTooShort(Object min) => 'Password must be at least $min characters';
}
