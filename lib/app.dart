import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes.dart';
import 'theme.dart';

class BoycottApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boycott Scanner',
      theme: buildTheme(),
      initialRoute: Routes.home,
      routes: appRoutes,
      debugShowCheckedModeBanner: false,
    );
  }
}
