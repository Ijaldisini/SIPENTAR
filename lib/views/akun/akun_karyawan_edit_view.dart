import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AkunKaryawanEditView extends StatefulWidget {
  const AkunKaryawanEditView({super.key, required this.employee});

  final Map<String, String> employee;

  @override
  State<AkunKaryawanEditView> createState() => _AkunKaryawanEditViewState();
}

class _AkunKaryawanEditViewState extends State<AkunKaryawanEditView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color darkColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFB4C49F);
  static const Color softColor = Color(0xFFF1F5E9);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _status;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.employee['name'] ?? '',
    );

    _usernameController = TextEditingController(
      text: widget.employee['username'] ?? '',
    );

    _status = widget.employee['status'] ?? 'Aktif';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    String? hint,
    Widget? suffixIcon,
    bool filled = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: mutedColor, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: filled ? softColor : Colors.white,
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
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: darkColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.inter(color: darkColor, fontSize: 13),
          decoration: _inputDecoration(hint: hint, suffixIcon: suffixIcon),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Status akun'),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: _inputDecoration(),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryColor,
          ),
          dropdownColor: Colors.white,
          style: GoogleFonts.inter(color: darkColor, fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
            DropdownMenuItem(value: 'Nonaktif', child: Text('Nonaktif')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _status = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    String hint = 'Minimal 8 karakter',
  }) {
    return _buildTextField(
      label: label,
      controller: controller,
      hint: hint,
      obscureText: obscureText,
      validator: validator,
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: mutedColor,
          size: 19,
        ),
      ),
    );
  }

  void _saveAccount() {
    if (!_formKey.currentState!.validate()) return;

    final updatedEmployee = <String, String>{
      ...widget.employee,
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'status': _status,
    };

    Navigator.pop(context, updatedEmployee);
  }

  Widget _buildInfoNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: primaryColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubah data dan akses akun',
                  style: GoogleFonts.inter(
                    color: darkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kosongkan kolom kata sandi jika tidak ingin mengubah kata sandi karyawan.',
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
                        _buildTextField(
                          label: 'Nama lengkap',
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama lengkap wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Username',
                          controller: _usernameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Username wajib diisi';
                            }

                            if (value.contains(' ')) {
                              return 'Username tidak boleh memakai spasi';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildStatusDropdown(),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'Kata sandi baru (opsional)',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onToggle: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null;
                            }

                            if (value.length < 8) {
                              return 'Kata sandi minimal 8 karakter';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'Konfirmasi kata sandi baru',
                          hint: 'Ulangi kata sandi baru',
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          onToggle: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          validator: (value) {
                            final password = _passwordController.text;

                            if (password.isEmpty &&
                                (value == null || value.isEmpty)) {
                              return null;
                            }

                            if (password.isEmpty) {
                              return 'Isi kata sandi baru terlebih dahulu';
                            }

                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi kata sandi wajib diisi';
                            }

                            if (value != password) {
                              return 'Kata sandi tidak cocok';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildInfoNotice(),
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
                        'Edit akun karyawan',
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
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        _buildBottomButton(
                          label: 'Simpan',
                          isPrimary: true,
                          onPressed: _saveAccount,
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
