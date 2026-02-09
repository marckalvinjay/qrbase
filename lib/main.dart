import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final themeController = await ThemeController.load();
  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ThemeControllerProvider(
      notifier: themeController,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'Entry Grid',
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFB9EB7),
                secondary: Color(0xFF3C3C3C),
                surface: Colors.white,
              ),
              scaffoldBackgroundColor: const Color(0xFFFB9EB7),
              textTheme: GoogleFonts.manropeTextTheme().apply(
                bodyColor: Colors.black,
                displayColor: Colors.black,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(color: Colors.black),
                hintStyle: TextStyle(color: Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.black,
                iconTheme: IconThemeData(color: Colors.black),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF2A8CFF),
                secondary: Color(0xFF4AD9C6),
                surface: Color(0xFF0E1426),
              ),
              visualDensity: VisualDensity.adaptivePlatformDensity,
              scaffoldBackgroundColor: const Color(0xFF0E1426),
              textTheme: GoogleFonts.manropeTextTheme().apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(color: Color(0xFF9ADFE0)),
                hintStyle: TextStyle(color: Color(0xFF7FB8C9)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2C4A4E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4AD9C6)),
                ),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Color(0xFFEAF7FF),
                iconTheme: IconThemeData(color: Color(0xFFEAF7FF)),
              ),
            ),
            themeMode:
                themeController.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
