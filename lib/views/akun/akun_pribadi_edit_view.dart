import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AkunPribadiEditView extends StatefulWidget {
  const AkunPribadiEditView({super.key, required this.owner});

  final Map<String, String> owner;

  @override
  State<AkunPribadiEditView> createState() => _AkunPribadiEditViewState();
}

class _AkunPribadiEditViewState extends State<AkunPribadiEditView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color darkColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFB4C49F);
  static const Color softColor = Color(0xFFF1F5E9);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.owner['name'] ?? 'Budi Santoso',
    );

    _usernameController = TextEditingController(
      text: widget.owner['username'] ?? 'budi.santoso',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isChangingPassword {
    return _currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
  }

  InputDecoration _inputDecoration({
    String? hint,
    Widget? suffixIcon,
    Color fillColor = Colors.white,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: mutedColor, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
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
    Color fillColor = Colors.white,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          style: GoogleFonts.inter(color: darkColor, fontSize: 13),
          decoration: _inputDecoration(
            hint: hint,
            suffixIcon: suffixIcon,
            fillColor: fillColor,
          ),
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
          size: 19,
          color: mutedColor,
        ),
      ),
    );
  }

  Widget _buildRoleField() {
    return _buildTextField(
      label: 'Peran',
      controller: TextEditingController(
        text: widget.owner['role'] ?? 'Pemilik',
      ),
      fillColor: softColor,
      readOnly: true,
      suffixIcon: const Icon(
        Icons.lock_outline_rounded,
        color: primaryColor,
        size: 17,
      ),
    );
  }

  Widget _buildSecurityNotice() {
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
                  'Jaga keamanan akun pemilik',
                  style: GoogleFonts.inter(
                    color: darkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Peran pemilik tidak dapat diubah. Isi kata sandi saat ini hanya jika ingin mengganti kata sandi.',
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

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final updatedOwner = <String, String>{
      ...widget.owner,
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'role': 'Pemilik',
    };

    Navigator.pop(context, updatedOwner);
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

                        _buildRoleField(),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'Kata sandi saat ini',
                          hint: 'Isi untuk mengganti kata sandi',
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          onToggle: () {
                            setState(() {
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword;
                            });
                          },
                          validator: (value) {
                            if (_isChangingPassword &&
                                (value == null || value.isEmpty)) {
                              return 'Kata sandi saat ini wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'Kata sandi baru (opsional)',
                          hint: 'Minimal 8 karakter',
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          onToggle: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                          validator: (value) {
                            if (_isChangingPassword &&
                                (value == null || value.isEmpty)) {
                              return 'Kata sandi baru wajib diisi';
                            }

                            if (value != null &&
                                value.isNotEmpty &&
                                value.length < 8) {
                              return 'Minimal 8 karakter';
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
                            if (_isChangingPassword &&
                                (value == null || value.isEmpty)) {
                              return 'Konfirmasi kata sandi wajib diisi';
                            }

                            if (_isChangingPassword &&
                                value != _newPasswordController.text) {
                              return 'Kata sandi tidak cocok';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildSecurityNotice(),
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
                        'Edit akun pribadi',
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
                          onPressed: _saveProfile,
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
