import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/upload_screen.dart';
import 'package:flutter_application_1/screens/cleaning_screen.dart';
import 'package:flutter_application_1/screens/report_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );

    // refined theme with consistent cards, buttons and transitions
    final theme = base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: base.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.grey[900],
        displayColor: Colors.grey[900],
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    return MaterialApp(
      title: 'Data Report Flow',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: UploadScreen.routeName,
      routes: {
        UploadScreen.routeName: (_) => const UploadScreen(),
        CleaningScreen.routeName: (_) => const CleaningScreen(),
        ReportScreen.routeName: (_) => const ReportScreen(),
      },
    );
  }
}
