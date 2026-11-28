import 'package:flutter/material.dart';

import '../../controllers/budidaya/budidaya_controller.dart';
import '../../controllers/budidaya/meja_tanam_controller.dart';
import '../../models/budidaya/budidaya_model.dart';

class TambahSemaiView extends StatefulWidget {
  const TambahSemaiView({super.key});

  @override
  State<TambahSemaiView> createState() => _TambahSemaiViewState();
}

class _TambahSemaiViewState extends State<TambahSemaiView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFB7C4A5);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();
  final BudidayaController _budidayaController = BudidayaController();
  final MejaTanamController _mejaController = MejaTanamController();

  DateTime _tanggalSemai = DateTime.now();
  int? _selectedMejaId;

  BudidayaMejaModel? get _selectedMeja {
    for (final meja in _mejaController.mejaTanams) {
      if (meja.id == _selectedMejaId) return meja;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMeja());
  }

  Future<void> _loadMeja() async {
    final loaded = await _mejaController.loadMejaTanams();
    if (!mounted || !loaded) return;

    final available = _mejaController.mejaTersedia;
    setState(() {
      if (_selectedMejaId == null && available.isNotEmpty) {
        _selectedMejaId = available.first.id;
      }
    });
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _budidayaController.dispose();
    _mejaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: _buildHeader(context),
          ),
          Positioned(
            top: 104,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMejaField(),
                            const SizedBox(height: 16),
                            _buildTanggalField(),
                            const SizedBox(height: 16),
                            _buildJumlahField(),
                            const SizedBox(height: 16),
                            _buildStatusCard(),
                            const SizedBox(height: 12),
                            _buildInformationCard(),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: primaryColor,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 28,
        24,
        0,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: const Padding(
              padding: EdgeInsets.only(right: 12, top: 4, bottom: 4),
              child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Tambah data semai',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: textColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: const TextStyle(color: mutedColor, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildMejaField() {
    return AnimatedBuilder(
      animation: _mejaController,
      builder: (context, _) {
        final available = _mejaController.mejaTersedia;
        final selectedExists = available.any((item) => item.id == _selectedMejaId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Meja tanam'),
            const SizedBox(height: 8),
            if (_mejaController.isLoading)
              _buildLoadingField('Memuat daftar meja tanam...')
            else if (_mejaController.errorMessage != null)
              _buildErrorField(_mejaController.errorMessage!)
            else if (available.isEmpty)
              _buildEmptyTableField()
            else
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedExists ? _selectedMejaId : null,
                    isExpanded: true,
                    hint: const Text('Pilih meja tanam'),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: primaryColor,
                    ),
                    items: available.map((meja) {
                      return DropdownMenuItem<int>(
                        value: meja.id,
                        child: Text(
                          'Meja ${meja.nomorMeja} • ${meja.kapasitasLubang} lubang',
                          style: const TextStyle(color: textColor, fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedMejaId = value),
                  ),
                ),
              ),
            if (_selectedMeja != null) ...[
              const SizedBox(height: 6),
              Text(
                'Kapasitas meja: ${_selectedMeja!.kapasitasLubang} lubang',
                style: const TextStyle(color: mutedColor, fontSize: 10),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLoadingField(String message) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
          ),
          const SizedBox(width: 10),
          Text(message, style: const TextStyle(color: mutedColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildErrorField(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F2),
        border: Border.all(color: const Color(0xFFF0D4CA)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Color(0xFF8E4135), fontSize: 11)),
          TextButton.icon(
            onPressed: () => _mejaController.refreshMejaTanams(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba lagi'),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTableField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        border: Border.all(color: const Color(0xFFE9D9B6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Belum ada meja yang tersedia untuk budidaya baru.',
        style: TextStyle(color: Color(0xFF80662D), fontSize: 11),
      ),
    );
  }

  Widget _buildTanggalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tanggal semai'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTanggalSemai,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(_tanggalSemai), style: const TextStyle(color: textColor, fontSize: 14)),
                const Icon(Icons.calendar_month_outlined, color: primaryColor, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTanggalSemai() async {
    final today = DateTime.now();
    final lastDate = DateTime(today.year, today.month, today.day);
    final initialDate = _tanggalSemai.isAfter(lastDate) ? lastDate : _tanggalSemai;

    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: textColor,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (result != null && mounted) {
      setState(() => _tanggalSemai = DateTime(result.year, result.month, result.day));
    }
  }

  Widget _buildJumlahField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Jumlah tanaman'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _jumlahController,
          keyboardType: TextInputType.number,
          cursorColor: primaryColor,
          style: const TextStyle(color: textColor, fontSize: 14),
          decoration: _inputDecoration(hintText: 'Masukkan jumlah tanaman'),
          validator: (value) {
            final number = int.tryParse((value ?? '').trim());
            if (number == null || number < 1) return 'Jumlah tanaman minimal 1.';
            final meja = _selectedMeja;
            if (meja != null && number > meja.kapasitasLubang) {
              return 'Melebihi kapasitas meja (${meja.kapasitasLubang} lubang).';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: softColor, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Icon(Icons.spa_outlined, color: primaryColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status awal budidaya', style: TextStyle(color: mutedColor, fontSize: 10)),
                SizedBox(height: 2),
                Text('Berjalan', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline_rounded, color: primaryColor, size: 19),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8FAF5), borderRadius: BorderRadius.circular(16)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryColor, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data yang dicatat mengikuti field backend: meja tanam, tanggal semai, jumlah tanaman, dan status. Nama batch serta jenis tanaman belum tersedia pada endpoint budidaya.',
              style: TextStyle(color: mutedColor, fontSize: 10, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedBuilder(
                animation: _budidayaController,
                builder: (context, _) {
                  return SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _budidayaController.isSubmitting ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryColor.withValues(alpha: 0.55),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _budidayaController.isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Simpan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final meja = _selectedMeja;
    if (meja == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih meja tanam yang tersedia terlebih dahulu.')),
      );
      return;
    }

    final jumlahTanaman = int.parse(_jumlahController.text.trim());
    final success = await _budidayaController.createBudidaya(
      mejaId: meja.id,
      tanggalSemai: _tanggalSemai,
      jumlahTanaman: jumlahTanaman,
      status: BudidayaModel.statusBerjalan,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data budidaya berhasil disimpan.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_budidayaController.submitErrorMessage ?? 'Gagal menyimpan data budidaya.')),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
