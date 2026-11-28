import 'package:flutter/material.dart';

import '../../controllers/keuangan/hpp_controller.dart';
import '../../models/keuangan/hpp_model.dart';

class KalkulasiHppView extends StatefulWidget {
  const KalkulasiHppView({super.key});

  @override
  State<KalkulasiHppView> createState() => _KalkulasiHppViewState();
}

class _KalkulasiHppViewState extends State<KalkulasiHppView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color secondaryColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFDFE5D7);

  late final HppController _hppController;
  final TextEditingController _holeController = TextEditingController();
  final FocusNode _holeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _hppController = HppController();
  }

  @override
  void dispose() {
    _holeController.dispose();
    _holeFocusNode.dispose();
    _hppController.dispose();
    super.dispose();
  }

  Future<void> _calculateHpp() async {
    FocusScope.of(context).unfocus();

    final input = _holeController.text.trim();
    int? holes;

    if (input.isNotEmpty) {
      final normalized = input.replaceAll(RegExp(r'[.,\s]'), '');
      holes = int.tryParse(normalized);

      if (holes == null || holes < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah lubang tanam harus berupa angka lebih dari 0.'),
          ),
        );
        return;
      }
    }

    final succeeded = await _hppController.calculateHpp(lubang: holes);

    if (!mounted) return;

    if (succeeded) {
      final result = _hppController.hasilHpp;
      if (result != null && input.isEmpty) {
        _holeController.text = _formatNumber(result.lubang);
      }
    }
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
              child: AnimatedBuilder(
                animation: _hppController,
                builder: (context, child) {
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCalculationBasisCard(),
                              const SizedBox(height: 16),
                              _buildHoleInput(),
                              const SizedBox(height: 16),
                              _buildResultCard(_hppController.hasilHpp),
                              if (_hppController.errorMessage != null) ...[
                                const SizedBox(height: 12),
                                _buildErrorCard(_hppController.errorMessage!),
                              ],
                              const SizedBox(height: 12),
                              const Text(
                                'Nilai HPP per lubang mengikuti konfigurasi '
                                'server. Total HPP dihitung oleh backend '
                                'berdasarkan jumlah lubang yang digunakan.',
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildCalculateButton(),
                    ],
                  );
                },
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
            'Kalkulasi HPP',
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

  Widget _buildCalculationBasisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.calculate_outlined,
            color: primaryColor,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basis perhitungan HPP',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Jumlah lubang yang dimasukkan atau total kapasitas meja tanam',
                  style: TextStyle(color: secondaryColor, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Jumlah lubang tanam (opsional)'),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFB7C4A5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _holeController,
                  focusNode: _holeFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  cursorColor: primaryColor,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Kosongkan untuk semua meja tanam',
                    hintStyle: TextStyle(
                      color: Color(0xFF9AA291),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: (_) {
                    if (!_hppController.isLoading) {
                      _calculateHpp();
                    }
                  },
                ),
              ),
              const Text(
                'lubang',
                style: TextStyle(color: secondaryColor, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kosongkan kolom untuk memakai total kapasitas lubang dari seluruh meja tanam.',
          style: TextStyle(color: secondaryColor, fontSize: 10, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildResultCard(HppModel? result) {
    final isLoading = _hppController.isLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil kalkulasi',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Column(
                  children: [
                    SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Menghitung HPP dari server...',
                      style: TextStyle(color: secondaryColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
            )
          else if (result == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada hasil. Masukkan jumlah lubang atau biarkan kosong, lalu tekan Hitung HPP.',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            )
          else ...[
            _buildResultRow(
              label: 'Jumlah lubang tanam',
              value: '${_formatNumber(result.lubang)} lubang',
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              label: 'HPP per lubang',
              value: _formatRupiah(result.hppPerLubang),
            ),
            const Divider(color: Color(0xFFD7E0CC), height: 24),
            const Text(
              'Total HPP',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatRupiah(result.totalHpp),
              style: const TextStyle(
                color: textColor,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: secondaryColor, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        border: Border.all(color: const Color(0xFFF0D0C8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFAE4E3D),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8F3F32),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tutup pesan',
            onPressed: _hppController.clearError,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF8F3F32),
              size: 17,
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

  Widget _buildCalculateButton() {
    final isLoading = _hppController.isLoading;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _calculateHpp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              disabledBackgroundColor: const Color(0xFFB7C4A5),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Hitung HPP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  String _formatRupiah(double value) {
    final isNegative = value < 0;
    final rounded = value.abs().round();
    final formatted = _formatNumber(rounded);
    return '${isNegative ? '−' : ''}Rp$formatted';
  }
}
