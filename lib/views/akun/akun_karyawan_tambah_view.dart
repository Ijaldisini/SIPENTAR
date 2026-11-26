import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/akun/karyawan_controller.dart';

class AkunKaryawanTambahView extends StatefulWidget {
  const AkunKaryawanTambahView({super.key, required this.controller});

  final KaryawanController controller;

  @override
  State<AkunKaryawanTambahView> createState() => _AkunKaryawanTambahViewState();
}

class _AkunKaryawanTambahViewState extends State<AkunKaryawanTambahView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color darkColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFB4C49F);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
    widget.controller.removeListener(_onControllerChanged);
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final employee = await widget.controller.createEmployee(
      nama: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Gagal menambahkan karyawan.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    Navigator.pop(context, true);
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: mutedColor,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: darkColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          style: GoogleFonts.inter(color: darkColor, fontSize: 13),
          decoration: _inputDecoration(hint: hint, suffixIcon: suffixIcon),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return _buildField(
      label: label,
      hint: hint,
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 19,
          color: mutedColor,
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
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
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      resizeToAvoidBottomInset: true,
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
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          label: 'Nama lengkap',
                          hint: 'Masukkan nama lengkap',
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama lengkap wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildField(
                          label: 'Username',
                          hint: 'contoh: nama.karyawan',
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Username wajib diisi';
                            }

                            if (value.contains(' ')) {
                              return 'Username tidak boleh mengandung spasi';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'Kata sandi',
                          hint: 'Minimal 8 karakter',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onToggle: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kata sandi wajib diisi';
                            }

                            if (value.length < 8) {
                              return 'Kata sandi minimal 8 karakter';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'Konfirmasi kata sandi',
                          hint: 'Ulangi kata sandi',
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          onToggle: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi kata sandi wajib diisi';
                            }

                            if (value != _passwordController.text) {
                              return 'Kata sandi tidak cocok';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
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
                        'Tambah akun karyawan',
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
                          label: 'Batal',
                          isPrimary: false,
                          onPressed: widget.controller.isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        _buildBottomButton(
                          label: 'Simpan',
                          isPrimary: true,
                          isLoading: widget.controller.isSubmitting,
                          onPressed: widget.controller.isSubmitting
                              ? null
                              : _saveAccount,
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
