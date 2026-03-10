import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'services/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.instance.load();
  runApp(const LocalizationTestApp());
}

class LocalizationTestApp extends StatelessWidget {
  const LocalizationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.instance.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Localization Test',
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LocalizationHome(),
        );
      },
    );
  }
}

class LocalizationHome extends StatelessWidget {
  const LocalizationHome({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.appTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.settings),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => LocaleController.instance.setLocale(const Locale('en')),
              child: const Text('English'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => LocaleController.instance.setLocale(const Locale('ne')),
              child: const Text('नेपाली (Nepali)'),
            ),
          ],
        ),
      ),
    );
  }
}
