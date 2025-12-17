// lib/routes.dart
import 'package:cool_clean/screens/home_screen.dart';
import 'package:cool_clean/screens/result_screen.dart';
import 'package:cool_clean/screens/scan_screen.dart';
import 'package:flutter/material.dart';

import 'models/product.dart';

class Routes {
  static const home = '/';
  static const scan = '/scan';
  static const result = '/result';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      scan: (context) => const ScanScreen(),
      result: (context) => const ResultScreen(),
    };
  }
}

final Map<String, WidgetBuilder> appRoutes = {
  Routes.home: (_) => const HomeScreen(),
  Routes.scan: (_) => const ScanScreen(),
  Routes.result: (ctx) {
    final args = ModalRoute.of(ctx)!.settings.arguments;
    if (args is Product) {
      return const ResultScreen();
    }
    // If no product, go back to home
    return const HomeScreen();
  },
};
