import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/splash/splash_view.dart';
import 'views/welcome/welcome_view.dart';
import 'views/register/register_view.dart';
import 'views/login/login_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sipentar',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      routes: {
        '/welcome': (context) => const WelcomeView(),
        '/register': (context) => const RegisterView(),
        '/login': (context) => const LoginView(),
      },
      home: const SplashView(),
    );
  }
}
