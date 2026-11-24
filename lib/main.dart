import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'views/splash/splash_view.dart';
import 'views/welcome/welcome_view.dart';
import 'views/register/register_view.dart';
import 'views/login/login_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/keuangan_stok/keuangan_stok_view.dart';
import 'views/keuangan_stok/stock_form_view.dart';
import 'views/budidaya/budidaya_view.dart';
import 'views/budidaya/riwayat_budidaya_view.dart';
import 'views/budidaya/tambah_semai_view.dart';
import 'views/budidaya/edit_semai_view.dart';
import 'views/budidaya/edit_rotasi_panen_view.dart';
import 'views/kesehatan/kesehatan_view.dart';
import 'views/akun/akun_view.dart';

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
        '/dashboard': (context) => const DashboardView(),
        '/keuangan-stok': (context) => const KeuanganStokView(),
        '/stok/tambah': (context) => const StockFormView(),
        '/budidaya': (context) => const BudidayaView(),
        '/budidaya/riwayat': (context) => const RiwayatBudidayaView(),
        '/budidaya/tambah': (context) => const TambahSemaiView(),
        '/budidaya/edit': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          final data = arguments is Map
              ? Map<String, dynamic>.from(arguments)
              : null;

          return EditSemaiView(initialData: data);
        },
        '/panen/edit': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          final data = arguments is Map
              ? Map<String, dynamic>.from(arguments)
              : null;

          return EditRotasiPanenView(initialData: data);
        },
        '/kesehatan': (context) => const KesehatanView(),
        '/akun': (context) => const AkunView(),
      },
      home: const SplashView(),
    );
  }
}
