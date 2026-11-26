import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/akun/karyawan_controller.dart';
import 'akun_karyawan_edit_view.dart';

class AkunKaryawanDetailView extends StatefulWidget {
  const AkunKaryawanDetailView({
    super.key,
    required this.employee,
    required this.controller,
  });

  final Map<String, String> employee;
  final KaryawanController controller;

  @override
  State<AkunKaryawanDetailView> createState() => _AkunKaryawanDetailViewState();
}

class _AkunKaryawanDetailViewState extends State<AkunKaryawanDetailView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color darkColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color borderColor = Color(0xFFD5DECB);

  Map<String, String> get employee {
    final user = widget.controller.selectedEmployee;

    if (user == null || user.id.toString() != widget.employee['id']) {
      return widget.employee;
    }

    return {
      ...widget.employee,
      'id': user.id.toString(),
      'name': user.nama,
      'username': user.username,
      'role': user.role,
      'status': '-',
    };
  }

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadEmployeeDetail();
    });
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadEmployeeDetail() async {
    final id = int.tryParse(widget.employee['id'] ?? '');

    if (id == null) {
      return;
    }

    await widget.controller.loadEmployeeDetail(id: id);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  Widget _buildInformationRow({
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    color: darkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE7ECDD)),
      ],
    );
  }

  Widget _buildBottomButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Expanded(
      child: SizedBox(
        height: 52,
        child: isPrimary
            ? ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDetailState() {
    if (widget.controller.isDetailLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(
          color: primaryColor,
          backgroundColor: softColor,
        ),
      );
    }

    if (widget.controller.detailErrorMessage != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5DF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.controller.detailErrorMessage!,
              style: GoogleFonts.inter(
                color: const Color(0xFF8C5B16),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _loadEmployeeDetail,
              child: Text(
                'Coba lagi',
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _openEditPage() async {
    final updatedEmployee = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AkunKaryawanEditView(
          employee: employee,
          controller: widget.controller,
        ),
      ),
    );

    if (!mounted || updatedEmployee == null) {
      return;
    }

    setState(() {
      widget.employee
        ..clear()
        ..addAll(updatedEmployee);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = employee['name'] ?? '-';
    final username = employee['username'] ?? '-';
    final status = employee['status'] ?? '-';

    return Scaffold(
      backgroundColor: primaryColor,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              top: 104,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailState(),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: softColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Akun karyawan',
                                    style: GoogleFonts.inter(
                                      color: mutedColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      color: darkColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    username,
                                    style: GoogleFonts.inter(
                                      color: mutedColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.inter(
                                  color: primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'Informasi akun',
                        style: GoogleFonts.inter(
                          color: darkColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildInformationRow(
                              label: 'Nama lengkap',
                              value: name,
                            ),
                            _buildInformationRow(
                              label: 'Username',
                              value: username,
                            ),
                            _buildInformationRow(
                              label: 'Peran',
                              value: 'Karyawan',
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: softColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kata sandi tidak ditampilkan',
                                    style: GoogleFonts.inter(
                                      color: darkColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Untuk mengubah data atau kata sandi karyawan, pilih Edit akun.',
                                    style: GoogleFonts.inter(
                                      color: mutedColor,
                                      fontSize: 10,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 26, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Detail akun karyawan',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                    child: Row(
                      children: [
                        _buildBottomButton(
                          label: 'Kembali',
                          isPrimary: false,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        _buildBottomButton(
                          label: 'Edit akun',
                          isPrimary: true,
                          onPressed: widget.controller.isSubmitting
                              ? () {}
                              : _openEditPage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
