import 'app_localizations.dart';

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([super.locale = 'ne']);

  @override
  String get appTitle => 'हाम्रो OZ';

  @override
  String get home => 'गृहपृष्ठ';

  @override
  String get messages => 'सन्देशहरू';

  @override
  String get calendar => 'पात्रो';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get settings => 'सेटिङ्स';

  @override
  String get adminDashboard => 'एडमिन ड्यासबोर्ड';

  @override
  String get logout => 'लग आउट';

  @override
  String get notifications => 'सूचनाहरू';

  @override
  String get privacy => 'गोपनीयता';

  @override
  String get appPreferences => 'एप प्राथमिकताहरू';

  @override
  String get theme => 'थिम';

  @override
  String get language => 'भाषा';

  @override
  String get autoDownloadImages => 'तस्विरहरू स्वचालित डाउनलोड';

  @override
  String get clearCache => 'क्यास खाली गर्नुहोस्';

  @override
  String get clearCacheConfirm => 'यसले सबै क्यास गरिएका तस्विरहरू र डाटा खाली गर्नेछ। जारी राख्ने?';

  @override
  String get adzunaApi => 'Adzuna API (जागिरहरू)';

  @override
  String get save => 'बचत गर्नुहोस्';

  @override
  String get clear => 'खाली गर्नुहोस्';

  @override
  String get exportData => 'मेरो डाटा निर्यात गर्नुहोस्';

  @override
  String get deleteAccount => 'खाता मेटाउनुहोस्';

  @override
  String get aboutApp => 'एप बारेमा';

  @override
  String get termsOfService => 'सेवाका सर्तहरू';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get helpSupport => 'मद्दत र समर्थन';

  @override
  String get version => 'संस्करण';

  @override
  String get light => 'उज्यालो';

  @override
  String get dark => 'अँध्यारो';

  @override
  String get systemDefault => 'प्रणाली पूर्वनिर्धारित';

  @override
  String get english => 'English';

  @override
  String get nepali => 'नेपाली';

  @override
  String themeChanged(Object themeName) => 'थिम $themeName मा परिवर्तन भयो';

  @override
  String languageChanged(Object languageName) => 'भाषा $languageName मा परिवर्तन भयो';

  @override
  String tooManyFailedLoginAttempts(Object minutes) => 'धेरै असफल लगइन प्रयासहरू। कृपया $minutes मिनेट पछि पुन: प्रयास गर्नुहोस्।';

  @override
  String get passwordResetSent => 'पासवर्ड रिसेट लिङ्क तपाईंको इमेलमा पठाइयो';

  @override
  String welcomeBack(Object name) => 'फेरि स्वागत छ, $name!';

  @override
  String loginError(Object error) => 'लगइन त्रुटि: $error';

  @override
  String get invalidCredentials => 'अमान्य इमेल वा पासवर्ड';

  @override
  String welcome(Object name) => 'स्वागत छ, $name!';

  @override
  String get googleSignInFailed => 'Google साइन-इन असफल भयो वा रद्द गरियो';

  @override
  String get appleSignInFailed => 'Apple साइन-इन असफल भयो वा रद्द गरियो';

  @override
  String get signIn => 'साइन इन';

  @override
  String get newUser => 'नयाँ प्रयोगकर्ता?';

  @override
  String get createAccount => 'खाता बनाउनुहोस्';

  @override
  String get or => 'वा';

  @override
  String get continueWithGoogle => 'Google सँग जारी राख्नुहोस्';

  @override
  String get continueWithApple => 'Apple सँग जारी राख्नुहोस्';

  @override
  String get pleaseAgreeTerms => 'कृपया सर्तहरू र सर्तहरूमा सहमत हुनुहोस्';

  @override
  String get registrationSuccess => 'दर्ता सफल! कृपया लगइन गर्नुहोस्।';

  @override
  String get emailAlreadyRegistered => 'इमेल पहिले नै दर्ता भइसकेको छ। कृपया लगइन गर्नुहोस्।';

  @override
  String get emailLabel => 'इमेल ठेगाना *';

  @override
  String get emailHint => 'your.email@example.com';

  @override
  String get passwordLabel => 'पासवर्ड *';

  @override
  String get passwordHint => 'आफ्नो पासवर्ड प्रविष्ट गर्नुहोस्';

  @override
  String passwordTooShort(Object min) => 'पासवर्ड कम्तिमा $min वर्णको हुनुपर्छ';
}
