import 'package:flutter/material.dart';

import '../../controllers/stok/stok_controller.dart';
import '../../models/stok/stok_model.dart';

class StockFormView extends StatefulWidget {
  final StokController stokController;
  final StokModel? stok;

  const StockFormView({
    super.key,
    required this.stokController,
    this.stok,
  });

  @override
  State<StockFormView> createState() => _StockFormViewState();
}

class _StockFormViewState extends State<StockFormView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color borderColor = Color(0xFFB7C4A5);

  final List<String> categories = ['Nutrisi', 'Media tanam', 'Benih'];
  final List<String> units = ['Liter', 'Lembar', 'Pak'];

  late final TextEditingController nameController;
  late final TextEditingController quantityController;
  late final TextEditingController minimumController;

  late String selectedCategory;
  late String selectedUnit;

  bool get isEdit => widget.stok != null;

  double get quantityValue => _parseNumber(quantityController.text) ?? 0;
  double get minimumValue => _parseNumber(minimumController.text) ?? 0;
  bool get isBelowMinimum => quantityValue <= minimumValue;

  @override
  void initState() {
    super.initState();

    final stok = widget.stok;

    if (stok != null && !categories.contains(stok.kategori)) {
      categories.add(stok.kategori);
    }

    if (stok != null && !units.contains(stok.satuan)) {
      units.add(stok.satuan);
    }

    nameController = TextEditingController(text: stok?.namaBahan ?? '');
    quantityController = TextEditingController(
      text: stok == null ? '' : _formatNumber(stok.jumlahStok),
    );
    minimumController = TextEditingController(
      text: stok == null ? '' : _formatNumber(stok.batasMinimum),
    );

    selectedCategory = stok?.kategori ?? categories.first;
    selectedUnit = stok?.satuan ?? units.last;

    widget.stokController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant StockFormView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stokController != widget.stokController) {
      oldWidget.stokController.removeListener(_onControllerChanged);
      widget.stokController.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.stokController.removeListener(_onControllerChanged);
    nameController.dispose();
    quantityController.dispose();
    minimumController.dispose();
    super.dispose();
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);

    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return null;
    }

    return parsed;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveStock() async {
    if (widget.stokController.isSubmitting) return;

    final namaBahan = nameController.text.trim();
    final jumlahStok = _parseNumber(quantityController.text);
    final batasMinimum = _parseNumber(minimumController.text);

    if (namaBahan.isEmpty) {
      _showMessage('Nama stok wajib diisi.');
      return;
    }

    if (jumlahStok == null) {
      _showMessage('Jumlah tersedia harus berupa angka nol atau lebih.');
      return;
    }

    if (batasMinimum == null) {
      _showMessage('Batas minimum harus berupa angka nol atau lebih.');
      return;
    }

    widget.stokController.clearError();

    if (isEdit) {
      await widget.stokController.updateStok(
        id: widget.stok!.id,
        namaBahan: namaBahan,
        kategori: selectedCategory,
        satuan: selectedUnit,
        jumlahStok: jumlahStok,
        batasMinimum: batasMinimum,
      );
    } else {
      await widget.stokController.createStok(
        namaBahan: namaBahan,
        kategori: selectedCategory,
        satuan: selectedUnit,
        jumlahStok: jumlahStok,
        batasMinimum: batasMinimum,
      );
    }

    if (!mounted) return;

    final errorMessage = widget.stokController.submitErrorMessage;
    if (errorMessage != null && errorMessage.trim().isNotEmpty) {
      _showMessage(errorMessage);
      return;
    }

    Navigator.of(context).pop(true);
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
                          _buildTextField(
                            label: 'Nama stok',
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Kategori',
                            value: selectedCategory,
                            items: categories,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => selectedCategory = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Jumlah tersedia',
                                  controller: quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Satuan',
                                  value: selectedUnit,
                                  items: units,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => selectedUnit = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Batas minimum stok',
                            controller: minimumController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _buildStockNotice(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButtons(context),
                ],
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
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isEdit ? 'Edit stok' : 'Tambah stok',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: primaryColor,
            style: const TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: _inputDecoration(),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: primaryColor,
              size: 23,
            ),
            decoration: _inputDecoration(),
            style: const TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildStockNotice() {
    final isLow = isBelowMinimum;
    final unit = selectedUnit.toLowerCase();

    final backgroundColor = isLow
        ? const Color(0xFFFFF5DF)
        : const Color(0xFFF1F5E9);
    final noticeColor = isLow ? const Color(0xFF8C5B16) : primaryColor;
    final title = isLow
        ? 'Stok berada di bawah batas minimum'
        : 'Notifikasi stok otomatis';
    final description = isLow
        ? 'Tersedia ${quantityController.text.isEmpty ? '0' : quantityController.text} $unit dari batas minimum ${minimumController.text.isEmpty ? '0' : minimumController.text} $unit. Segera lakukan pengadaan.'
        : 'Peringatan muncul saat jumlah tersedia mencapai atau di bawah ${minimumController.text.isEmpty ? '0' : minimumController.text} $unit.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: noticeColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isLow ? noticeColor : textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isLow ? noticeColor : const Color(0xFF70786B),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
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

  Widget _buildBottomButtons(BuildContext context) {
    final isSubmitting = widget.stokController.isSubmitting;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _saveStock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
