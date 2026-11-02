import 'package:flutter/material.dart';

import '../welcome/welcome_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcome();
  }

  Future<void> _navigateToWelcome() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6E8649),
      body: Center(
        child: Image.asset(
          'assets/images/logo_sipentar.png',
          width: MediaQuery.sizeOf(context).width * 0.5,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
