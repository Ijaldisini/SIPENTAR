import 'package:flutter/material.dart';

import '../../controllers/transaksi_keuangan/transaksi_keuangan_controller.dart';

enum TransactionType { income, expense }

class TransactionFormView extends StatefulWidget {
  final TransactionType initialType;
  final TransaksiKeuanganController? controller;

  const TransactionFormView({
    super.key,
    this.initialType = TransactionType.income,
    this.controller,
  });

  @override
  State<TransactionFormView> createState() => _TransactionFormViewState();
}

class _TransactionFormViewState extends State<TransactionFormView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color borderColor = Color(0xFFB7C4A5);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TransaksiKeuanganController _controller;
  late final bool _ownsController;

  late TransactionType selectedType;
  late TextEditingController amountController;
  late TextEditingController percentageController;
  late TextEditingController descriptionController;
  late DateTime selectedDate;

  bool get isIncome => selectedType == TransactionType.income;

  @override
  void initState() {
    super.initState();

    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TransaksiKeuanganController();
    _controller.addListener(_onControllerChanged);

    selectedType = widget.initialType;
    selectedDate = DateTime.now();
    amountController = TextEditingController();
    percentageController = TextEditingController(
      text: widget.initialType == TransactionType.income ? '35' : '',
    );
    descriptionController = TextEditingController();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _changeTransactionType(TransactionType type) {
    if (selectedType == type) return;

    setState(() {
      selectedType = type;
      percentageController.text = type == TransactionType.income ? '35' : '';
    });
    _controller.clearSubmitError();
  }

  double? _parseAmount(String value) {
    var normalized = value.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (normalized.isEmpty) return null;

    if (normalized.contains(',') && normalized.contains('.')) {
      // Format Indonesia: 1.250.000,50
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(normalized)) {
      // Format ribuan tanpa angka desimal: 1.250.000
      normalized = normalized.replaceAll('.', '');
    }

    final result = double.tryParse(normalized);
    if (result == null || !result.isFinite) return null;
    return result;
  }

  double? _parsePercentage(String value) {
    final result = double.tryParse(value.trim().replaceAll(',', '.'));
    if (result == null || !result.isFinite) return null;
    return result;
  }

  Future<void> _saveTransaction() async {
    if (_controller.isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(amountController.text);
    if (amount == null) return;

    final percentage = isIncome
        ? _parsePercentage(percentageController.text)
        : null;

    final saved = await _controller.createTransaksiKeuangan(
      jenis: isIncome ? 'pemasukan' : 'pengeluaran',
      tanggal: selectedDate,
      jumlah: amount,
      // panen_id bersifat opsional; belum ada pemilihan data panen di form ini.
      panenId: null,
      persentaseKas: percentage,
      keterangan: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();

    amountController.dispose();
    percentageController.dispose();
    descriptionController.dispose();
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
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTransactionSelector(),
                            const SizedBox(height: 16),
                            _buildNominalField(),
                            const SizedBox(height: 16),
                            _buildDateField(),
                            if (isIncome) ...[
                              const SizedBox(height: 16),
                              _buildAllocationField(),
                            ],
                            const SizedBox(height: 16),
                            _buildDescriptionField(),
                            const SizedBox(height: 12),
                            Text(
                              'Transaksi akan masuk ke laporan '
                              '${_getMonthName(selectedDate.month)} '
                              '${selectedDate.year}.',
                              style: const TextStyle(
                                color: Color(0xFF70786B),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (_controller.submitErrorMessage != null) ...[
                              const SizedBox(height: 14),
                              _buildErrorMessage(
                                _controller.submitErrorMessage!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomButtons(),
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
          const Text(
            'Catat transaksi',
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

  Widget _buildTransactionSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTransactionTab(
              title: 'Pemasukan',
              type: TransactionType.income,
            ),
          ),
          Expanded(
            child: _buildTransactionTab(
              title: 'Pengeluaran',
              type: TransactionType.expense,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTab({
    required String title,
    required TransactionType type,
  }) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: _controller.isSubmitting ? null : () => _changeTransactionType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF70786B),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNominalField() {
    return FormField<String>(
      validator: (_) {
        final amount = _parseAmount(amountController.text);
        if (amount == null || amount <= 0) {
          return 'Nominal transaksi harus lebih dari 0.';
        }
        return null;
      },
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 104,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(16),
                border: fieldState.hasError
                    ? Border.all(color: const Color(0xFFAE4E3D))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nominal (Rp)',
                    style: TextStyle(
                      color: Color(0xFF70786B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      enabled: !_controller.isSubmitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        fieldState.didChange(amountController.text);
                        _controller.clearSubmitError();
                      },
                      cursorColor: primaryColor,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (fieldState.hasError) ...[
              const SizedBox(height: 5),
              Text(
                fieldState.errorText!,
                style: const TextStyle(
                  color: Color(0xFFAE4E3D),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tanggal transaksi'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _controller.isSubmitting ? null : _selectDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(color: textColor, fontSize: 14),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null && mounted) {
      setState(() => selectedDate = result);
    }
  }

  Widget _buildAllocationField() {
    return FormField<String>(
      validator: (_) {
        final percentage = _parsePercentage(percentageController.text);
        if (percentage == null || percentage <= 0 || percentage > 100) {
          return 'Persentase kas harus berupa angka antara 0 dan 100.';
        }
        return null;
      },
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Persentase alokasi kas (%)'),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: TextField(
                controller: percentageController,
                enabled: !_controller.isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  fieldState.didChange(percentageController.text);
                  _controller.clearSubmitError();
                },
                cursorColor: primaryColor,
                style: const TextStyle(color: textColor, fontSize: 14),
                decoration: _inputDecoration().copyWith(
                  hintText: 'Contoh: 35',
                  errorText: fieldState.errorText,
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Batas persentase mengikuti pengaturan backend.',
              style: TextStyle(
                color: Color(0xFF70786B),
                fontSize: 10,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Keterangan (opsional)'),
        const SizedBox(height: 8),
        SizedBox(
          height: 68,
          child: TextField(
            controller: descriptionController,
            enabled: !_controller.isSubmitting,
            maxLines: 2,
            maxLength: 255,
            cursorColor: primaryColor,
            onChanged: (_) => _controller.clearSubmitError(),
            style: const TextStyle(color: textColor, fontSize: 14),
            decoration: _inputDecoration().copyWith(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFAE4E3D),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFAE4E3D),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _buildBottomButtons() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _controller.isSubmitting
                      ? null
                      : () => Navigator.pop(context),
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
                  onPressed: _controller.isSubmitting ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.65),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _controller.isSubmitting
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
