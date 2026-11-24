import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/bottom_navigation.dart';
import 'akun_karyawan_tambah_view.dart';
import 'akun_karyawan_detail_view.dart';
import 'akun_pribadi_detail_view.dart';

class AkunView extends StatefulWidget {
  const AkunView({super.key});

  @override
  State<AkunView> createState() => _AkunViewState();
}

class _AkunViewState extends State<AkunView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color darkColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color borderColor = Color(0xFFD5DECB);
  static const Color dangerColor = Color(0xFFAB3D32);

  final Map<String, String> owner = {
    'name': 'Budi Santoso',
    'username': 'budi.santoso',
    'role': 'Pemilik',
    'status': 'Aktif',
  };

  final List<Map<String, String>> employees = [
    {'name': 'Rina Maulida', 'username': 'rina.maulida', 'status': 'Aktif'},
    {'name': 'Andi Pratama', 'username': 'andi.pratama', 'status': 'Aktif'},
    {'name': 'Lestari Wati', 'username': 'lestari.wati', 'status': 'Aktif'},
  ];

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushNamed(context, '/keuangan-stok');
        break;
      case 2:
        Navigator.pushNamed(context, '/budidaya');
        break;
      case 3:
        Navigator.pushNamed(context, '/kesehatan');
        break;
      case 4:
        break;
    }
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Keluar dari akun?',
            style: GoogleFonts.inter(
              color: darkColor,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          content: Text(
            'Apakah kamu yakin ingin keluar dari aplikasi Sipentar?',
            style: GoogleFonts.inter(color: mutedColor, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                'Logout',
                style: GoogleFonts.inter(
                  color: dangerColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (result == true) {
      _showMessage('Fitur logout akan dihubungkan dengan autentikasi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(width: double.infinity, height: 190, color: primaryColor),

          Positioned.fill(
            top: 136,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPersonalAccount(),

                    const SizedBox(height: 22),

                    _buildEmployeeHeader(),

                    const SizedBox(height: 12),

                    _buildAddEmployeeButton(),

                    const SizedBox(height: 12),

                    ...employees.map(
                      (employee) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildEmployeeItem(employee),
                      ),
                    ),

                    const SizedBox(height: 4),

                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Akun & karyawan',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola profil dan akses tim usahamu.',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () {
                          _showMessage('Belum ada notifikasi baru.');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        right: 5,
                        top: 4,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4D58A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const BottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildPersonalAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Akun pribadi',
          style: GoogleFonts.inter(
            color: darkColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        Material(
          color: softColor,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AkunPribadiDetailView(owner: owner),
                ),
              );

              if (mounted) {
                setState(() {});
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner['name'] ?? 'Budi Santoso',
                          style: GoogleFonts.inter(
                            color: darkColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${owner['username']}, ${owner['role']}',
                          style: GoogleFonts.inter(
                            color: mutedColor,
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Lihat akun pribadi',
                          style: GoogleFonts.inter(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Akun karyawan',
          style: GoogleFonts.inter(
            color: darkColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        TextButton(
          onPressed: () {
            _showMessage('Semua akun karyawan sudah ditampilkan.');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Semua Akun',
            style: GoogleFonts.inter(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddEmployeeButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () async {
          final newEmployee = await Navigator.push<Map<String, String>>(
            context,
            MaterialPageRoute(
              builder: (context) => const AkunKaryawanTambahView(),
            ),
          );

          if (newEmployee != null && mounted) {
            setState(() {
              employees.add(newEmployee);
            });

            _showMessage('${newEmployee['name']} berhasil ditambahkan.');
          }
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 19),
        label: Text(
          'Tambah akun karyawan',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeItem(Map<String, String> employee) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AkunKaryawanDetailView(employee: employee),
            ),
          );

          if (mounted) {
            setState(() {});
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee['name'] ?? '-',
                      style: GoogleFonts.inter(
                        color: darkColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${employee['username']}, ${employee['status']}',
                      style: GoogleFonts.inter(
                        color: mutedColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout_rounded, color: dangerColor, size: 16),
        label: Text(
          'Logout',
          style: GoogleFonts.inter(
            color: dangerColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: dangerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
