import 'package:flutter/material.dart';

import '../../controllers/keuangan/alokasi_kas_controller.dart';
import '../../models/keuangan/alokasi_kas_model.dart';

class PembagianKasView extends StatefulWidget {
  const PembagianKasView({super.key});

  @override
  State<PembagianKasView> createState() => _PembagianKasViewState();
}

class _PembagianKasViewState extends State<PembagianKasView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color secondaryColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFDFE5D7);
  static const Color expenseColor = Color(0xFFAE4E3D);

  static const List<String> _monthNames = [
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

  late final AlokasiKasController _alokasiKasController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _alokasiKasController = AlokasiKasController();
    _loadSelectedDate();
  }

  @override
  void dispose() {
    _alokasiKasController.dispose();
    super.dispose();
  }

  String _toApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _displayDate(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _loadSelectedDate() async {
    await _alokasiKasController.loadAlokasiKas(
      tanggal: _toApiDate(_selectedDate),
    );
  }

  Future<void> _selectDate() async {
    if (_alokasiKasController.isLoading) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal alokasi kas',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (!mounted || pickedDate == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });

    await _loadSelectedDate();
  }

  String _formatRupiah(double value) {
    final rounded = value.abs().round().toString();
    final grouped = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '${value < 0 ? '−' : ''}Rp$grouped';
  }

  String _formatPercentage(double value) {
    return '${value.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
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
                animation: _alokasiKasController,
                builder: (context, child) {
                  final result = _alokasiKasController.alokasiKas;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateSelector(),
                        const SizedBox(height: 16),
                        if (_alokasiKasController.isLoading && result == null)
                          _buildLoadingState()
                        else if (_alokasiKasController.errorMessage != null &&
                            result == null)
                          _buildErrorState(_alokasiKasController.errorMessage!)
                        else if (result != null) ...[
                          _buildSummaryCard(result),
                          const SizedBox(height: 14),
                          _buildAllocationBreakdown(result),
                          const SizedBox(height: 14),
                          _buildInformationNote(),
                          if (_alokasiKasController.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            _buildInlineError(
                              _alokasiKasController.errorMessage!,
                            ),
                          ],
                        ] else
                          _buildEmptyState(),
                        if (_alokasiKasController.isLoading && result != null)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              color: primaryColor,
                              backgroundColor: softColor,
                            ),
                          ),
                      ],
                    ),
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
            'Pembagian kas',
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

  Widget _buildDateSelector() {
    final isLoading = _alokasiKasController.isLoading;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : _selectDate,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: primaryColor,
                size: 19,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _displayDate(_selectedDate),
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isLoading ? secondaryColor : primaryColor,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AlokasiKasModel result) {
    final remaining = result.totalPemasukan - result.totalKasOperasional;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total pemasukan',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _formatRupiah(result.totalPemasukan),
            style: const TextStyle(
              color: textColor,
              fontSize: 29,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCashSummary(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: primaryColor,
                  label: 'Kas operasional',
                  amount: _formatRupiah(result.totalKasOperasional),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCashSummary(
                  icon: Icons.swap_horiz_rounded,
                  iconColor: const Color(0xFF6E8649),
                  label: 'Sisa setelah kas operasional',
                  amount: _formatRupiah(remaining),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashSummary({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 19),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: secondaryColor, fontSize: 10),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationBreakdown(AlokasiKasModel result) {
    final percentage = result.totalPemasukan > 0
        ? result.totalKasOperasional / result.totalPemasukan * 100
        : 0.0;
    final progress = (percentage / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan alokasi kas',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bagian pemasukan yang tercatat sebagai kas operasional',
            style: TextStyle(color: secondaryColor, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Porsi kas operasional',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatPercentage(percentage),
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: primaryColor,
              backgroundColor: softColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Kas operasional',
                  style: TextStyle(color: secondaryColor, fontSize: 11),
                ),
              ),
              Text(
                _formatRupiah(result.totalKasOperasional),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: primaryColor,
            size: 18,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Data ini merupakan ringkasan pemasukan dan kas operasional '
              'pada tanggal yang dipilih. Pengaturan persentase atau '
              'penyimpanan pembagian kas belum tersedia pada backend.',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: const Column(
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 14),
          Text(
            'Memuat data alokasi kas...',
            style: TextStyle(color: secondaryColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1D4CE)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: expenseColor,
            size: 30,
          ),
          const SizedBox(height: 8),
          const Text(
            'Data alokasi kas gagal dimuat',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            message,
            style: const TextStyle(color: secondaryColor, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _loadSelectedDate,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Coba lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(color: expenseColor, fontSize: 11),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: const Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: primaryColor, size: 32),
          SizedBox(height: 10),
          Text(
            'Belum ada data alokasi kas',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pilih tanggal lain atau coba muat ulang data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
