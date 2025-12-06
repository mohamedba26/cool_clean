import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/result_screen.dart';
import 'models/product.dart';

class Routes {
  static const home = '/';
  static const scan = '/scan';
  static const result = '/result';
}

final Map<String, WidgetBuilder> appRoutes = {
  Routes.home: (_) => HomeScreen(),
  Routes.scan: (_) => ScanScreen(),
  Routes.result: (ctx) {
    final args = ModalRoute.of(ctx)!.settings.arguments;
    if (args is Product) {
      return ResultScreen(product: args);
    }
    return ResultScreen.mock();
  },
};
