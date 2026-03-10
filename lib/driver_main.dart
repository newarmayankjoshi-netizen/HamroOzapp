import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  // ignore: avoid_print
  print('DRIVER MODE START');
  // If you see the normal app/login screen, then the driver target isn't
  // being used. This makes it obvious when running the driver entrypoint.
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'DRIVER MODE',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
}
