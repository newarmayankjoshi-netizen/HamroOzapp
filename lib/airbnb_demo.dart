import 'package:flutter/material.dart';
import 'screens/listings_home.dart';

void main() {
  runApp(const AirbnbDemoApp());
}

class AirbnbDemoApp extends StatelessWidget {
  const AirbnbDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Airbnb-style Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFDC2626)),
      home: const ListingsHome(),
    );
  }
}
