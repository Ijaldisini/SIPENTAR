import 'package:flutter/material.dart';

import '../../controllers/auth/auth_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late final AuthController _authController;

  bool _isCheckingSession = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();

    _authController = AuthController();

    _checkSession(showSplashDelay: true);
  }

  Future<void> _checkSession({bool showSplashDelay = false}) async {
    if (_isCheckingSession) return;

    _isCheckingSession = true;

    if (!showSplashDelay && mounted) {
      setState(() {
        _connectionError = null;
      });
    }

    if (showSplashDelay) {
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;

    final status = await _authController.restoreSession();

    if (!mounted) return;

    if (status == SessionRestoreStatus.authenticated) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );

      return;
    }

    if (status == SessionRestoreStatus.unauthenticated) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);

      return;
    }

    setState(() {
      _isCheckingSession = false;
      _connectionError =
          _authController.errorMessage ??
          'Tidak dapat memeriksa sesi pengguna.';
    });
  }

  void _goToWelcome() {
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6E8649),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo_sipentar.png',
                width: MediaQuery.sizeOf(context).width * 0.5,
                fit: BoxFit.contain,
              ),
            ),

            if (_connectionError != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 30,
                child: Column(
                  children: [
                    Text(
                      _connectionError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isCheckingSession
                            ? null
                            : () => _checkSession(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6E8649),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isCheckingSession
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF6E8649),
                                ),
                              )
                            : const Text(
                                'Coba lagi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: _isCheckingSession ? null : _goToWelcome,
                      child: const Text(
                        'Lanjut ke halaman awal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
