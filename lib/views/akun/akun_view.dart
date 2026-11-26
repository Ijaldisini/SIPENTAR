import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../controllers/akun/karyawan_controller.dart';
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
  @override
  void initState() {
    super.initState();

    _authController = AuthController();
    _authController.addListener(_onAuthChanged);

    _karyawanController = KaryawanController();
    _karyawanController.addListener(_onKaryawanChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadUserProfile();
    });
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    final status = await _authController.restoreSession();

    if (!mounted) return;

    if (_isOwner) {
      await _karyawanController.loadEmployees();
    }

    if (!mounted) return;

    switch (status) {
      case SessionRestoreStatus.authenticated:
        setState(() {
          _isLoadingProfile = false;
          _profileError = null;
        });
        break;

      case SessionRestoreStatus.unauthenticated:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
        break;

      case SessionRestoreStatus.unavailable:
        setState(() {
          _isLoadingProfile = false;
          _profileError = _authController.errorMessage;
        });
        break;
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    _authController.dispose();
    _karyawanController.removeListener(_onKaryawanChanged);
    _karyawanController.dispose();

    super.dispose();
  }

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color darkColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color borderColor = Color(0xFFD5DECB);
  static const Color dangerColor = Color(0xFFAB3D32);

  late final AuthController _authController;

  late final KaryawanController _karyawanController;

  void _onKaryawanChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _isLoadingProfile = true;
  String? _profileError;

  bool _isLoggingOut = false;

  Map<String, String> get owner {
    final user = _authController.user;

    String roleLabel;

    switch (user?.role) {
      case 'pemilik':
        roleLabel = 'Pemilik';
        break;
      case 'pegawai':
        roleLabel = 'Pegawai';
        break;
      default:
        roleLabel = '-';
    }

    return {
      'name': user?.nama ?? (_isLoadingProfile ? 'Memuat profil...' : '-'),
      'username': user?.username ?? '-',
      'role': roleLabel,
      'status': user != null ? 'Login' : '-',
    };
  }

  bool get _isOwner => _authController.user?.role == 'pemilik';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      setState(() {
        _isLoggingOut = true;
      });

      final messenger = ScaffoldMessenger.of(context);

      final success = await _authController.logout();

      if (!mounted) return;

      final errorMessage = _authController.errorMessage;

      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);

      if (!success && errorMessage != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

                    if (_profileError != null) ...[
                      const SizedBox(height: 12),
                      _buildProfileError(),
                    ],

                    if (_isOwner) ...[
                      const SizedBox(height: 22),

                      _buildEmployeeHeader(),

                      const SizedBox(height: 12),

                      _buildAddEmployeeButton(),

                      const SizedBox(height: 12),

                      _buildEmployeeContent(),
                    ],

                    const SizedBox(height: 16),

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

              if (!mounted) return;

              await _loadUserProfile();
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
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AkunKaryawanTambahView(controller: _karyawanController),
            ),
          );

          if (created == true && mounted) {
            _showMessage('Karyawan berhasil ditambahkan.');
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
              builder: (context) => AkunKaryawanDetailView(
                employee: employee,
                controller: _karyawanController,
              ),
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
                      employee['username'] ?? '-',
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
        onPressed: _isLoggingOut ? null : _confirmLogout,
        icon: _isLoggingOut
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: dangerColor,
                ),
              )
            : const Icon(Icons.logout_rounded, color: dangerColor, size: 16),
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

  Widget _buildProfileError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5DF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _profileError ?? 'Gagal mengambil profil.',
            style: GoogleFonts.inter(
              color: const Color(0xFF8C5B16),
              fontSize: 12,
            ),
          ),

          TextButton(
            onPressed: _isLoadingProfile ? null : _loadUserProfile,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeContent() {
    if (_karyawanController.isLoading &&
        _karyawanController.employees.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (_karyawanController.errorMessage != null &&
        _karyawanController.employees.isEmpty) {
      return Column(
        children: [
          Text(
            _karyawanController.errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _karyawanController.loadEmployees,
            child: Text(
              'Coba lagi',
              style: GoogleFonts.inter(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (_karyawanController.employees.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Belum ada akun karyawan.',
            style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '${_karyawanController.employees.length} dari '
            '${_karyawanController.totalEmployees} karyawan ditampilkan',
            style: GoogleFonts.inter(color: mutedColor, fontSize: 11),
          ),
        ),

        ..._karyawanController.employees.map((user) {
          final employee = <String, String>{
            'id': user.id.toString(),
            'name': user.nama,
            'username': user.username,
            'role': user.role,
            'status': '-',
          };

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildEmployeeItem(employee),
          );
        }),

        if (_karyawanController.loadMoreErrorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _karyawanController.loadMoreErrorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11),
          ),
          TextButton(
            onPressed: _karyawanController.isLoadingMore
                ? null
                : _karyawanController.loadMoreEmployees,
            child: const Text('Coba muat lagi'),
          ),
        ],

        if (_karyawanController.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_karyawanController.hasMoreEmployees)
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _karyawanController.loadMoreEmployees,
              icon: const Icon(Icons.expand_more_rounded, size: 19),
              label: Text(
                'Muat lainnya',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'Semua karyawan sudah ditampilkan.',
                style: GoogleFonts.inter(color: mutedColor, fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}
