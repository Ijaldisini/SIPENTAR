import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controllers/transaksi_keuangan/transaksi_keuangan_controller.dart';
import '../../models/transaksi_keuangan/laporan_keuangan_model.dart';

/// Halaman laporan keuangan untuk role pemilik.
///
/// Data laporan diambil dari endpoint GET /keuangan/laporan melalui
/// TransaksiKeuanganController. Halaman ini mengelola controller terpisah agar
/// filter laporan tidak mengubah ringkasan pada halaman Keuangan & Stok.
class LaporanKeuanganView extends StatefulWidget {
  const LaporanKeuanganView({super.key});

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color secondaryColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFDFE5D7);
  static const Color expenseColor = Color(0xFFAE4E3D);

  @override
  State<LaporanKeuanganView> createState() => _LaporanKeuanganViewState();
}

class _LaporanKeuanganViewState extends State<LaporanKeuanganView> {
  late DateTime _from;
  late DateTime _to;

  late final TransaksiKeuanganController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TransaksiKeuanganController();

    final today = DateUtils.dateOnly(DateTime.now());
    _from = DateTime(today.year, today.month, 1);
    _to = DateTime(today.year, today.month + 1, 0);

    _controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadReport();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadReport() async {
    await _controller.loadLaporanKeuangan(from: _from, to: _to);
  }

  Future<void> _selectPeriod() async {
    if (_controller.isReportLoading) return;

    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      helpText: 'Pilih periode laporan',
      cancelText: 'BATAL',
      confirmText: 'TERAPKAN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: LaporanKeuanganView.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: LaporanKeuanganView.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || selectedRange == null) return;

    setState(() {
      _from = DateUtils.dateOnly(selectedRange.start);
      _to = DateUtils.dateOnly(selectedRange.end);
    });

    await _loadReport();
  }

  bool get _hasReportForSelectedPeriod {
    final report = _controller.laporanKeuangan;
    if (report == null) return false;

    return DateUtils.isSameDay(report.tanggalMulai, _from) &&
        DateUtils.isSameDay(report.tanggalAkhir, _to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaporanKeuanganView.primaryColor,
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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPeriodSelector(),
                          const SizedBox(height: 16),
                          _buildReportBody(),
                        ],
                      ),
                    ),
                  ),
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
      color: LaporanKeuanganView.primaryColor,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 28,
        24,
        0,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
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
            'Laporan keuangan',
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

  Widget _buildPeriodSelector() {
    return InkWell(
      onTap: _controller.isReportLoading ? null : _selectPeriod,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: LaporanKeuanganView.borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: LaporanKeuanganView.primaryColor,
              size: 19,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_formatDate(_from)} – ${_formatDate(_to)}',
                style: const TextStyle(
                  color: LaporanKeuanganView.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_controller.isReportLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: LaporanKeuanganView.primaryColor,
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: LaporanKeuanganView.primaryColor,
                size: 21,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportBody() {
    final report = _hasReportForSelectedPeriod
        ? _controller.laporanKeuangan
        : null;

    if (report != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSurplusCard(report),
          const SizedBox(height: 12),
          _buildCashflowComparison(report),
          const SizedBox(height: 16),
          _buildReportDetails(report),
          const SizedBox(height: 14),
          _buildPeriodNote(),
        ],
      );
    }

    if (_controller.isReportLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 72),
        child: Center(
          child: CircularProgressIndicator(
            color: LaporanKeuanganView.primaryColor,
          ),
        ),
      );
    }

    final errorMessage = _controller.reportErrorMessage;
    if (errorMessage != null) {
      return _buildErrorState(errorMessage);
    }

    return _buildEmptyState();
  }

  Widget _buildSurplusCard(LaporanKeuanganModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaporanKeuanganView.softColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selisih pemasukan - pengeluaran',
            style: TextStyle(
              color: LaporanKeuanganView.secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatRupiah(report.selisih),
            style: const TextStyle(
              color: LaporanKeuanganView.textColor,
              fontSize: 29,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(
            color: LaporanKeuanganView.borderColor,
            height: 1,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCashSummary(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: LaporanKeuanganView.primaryColor,
                  label: 'Pemasukan',
                  amount: _formatRupiah(report.totalPemasukan),
                ),
              ),
              Expanded(
                child: _buildCashSummary(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: LaporanKeuanganView.expenseColor,
                  label: 'Pengeluaran',
                  amount: _formatRupiah(report.totalPengeluaran),
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
      children: [
        Icon(icon, color: iconColor, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: LaporanKeuanganView.secondaryColor,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: const TextStyle(
                    color: LaporanKeuanganView.textColor,
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

  Widget _buildCashflowComparison(LaporanKeuanganModel report) {
    final maximum = math.max(
      report.totalPemasukan,
      report.totalPengeluaran,
    );
    final incomeHeight = maximum <= 0
        ? 4.0
        : 82 * report.totalPemasukan / maximum;
    final expenseHeight = maximum <= 0
        ? 4.0
        : 82 * report.totalPengeluaran / maximum;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: LaporanKeuanganView.borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perbandingan arus kas',
            style: TextStyle(
              color: LaporanKeuanganView.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChartLegend(
                color: LaporanKeuanganView.primaryColor,
                label: 'Pemasukan',
              ),
              const SizedBox(width: 18),
              _buildChartLegend(
                color: LaporanKeuanganView.expenseColor,
                label: 'Pengeluaran',
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _buildComparisonBar(
                    label: 'Pemasukan',
                    amount: report.totalPemasukan,
                    color: LaporanKeuanganView.primaryColor,
                    barHeight: incomeHeight.toDouble(),
                  ),
                ),
                Expanded(
                  child: _buildComparisonBar(
                    label: 'Pengeluaran',
                    amount: report.totalPengeluaran,
                    color: LaporanKeuanganView.expenseColor,
                    barHeight: expenseHeight.toDouble(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: LaporanKeuanganView.secondaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonBar({
    required String label,
    required double amount,
    required Color color,
    required double barHeight,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _formatRupiah(amount),
            style: const TextStyle(
              color: LaporanKeuanganView.textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LaporanKeuanganView.secondaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReportDetails(LaporanKeuanganModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: LaporanKeuanganView.borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian laporan',
            style: TextStyle(
              color: LaporanKeuanganView.textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildReportRow(
            label: 'Total pemasukan',
            amount: _formatRupiah(report.totalPemasukan),
          ),
          const Divider(
            color: LaporanKeuanganView.borderColor,
            height: 18,
          ),
          _buildReportRow(
            label: 'Total pengeluaran',
            amount: _formatRupiah(report.totalPengeluaran),
          ),
          const Divider(
            color: LaporanKeuanganView.borderColor,
            height: 18,
          ),
          _buildReportRow(
            label: 'Kas operasional',
            amount: _formatRupiah(report.totalKasOperasional),
          ),
          const Divider(
            color: LaporanKeuanganView.borderColor,
            height: 18,
          ),
          _buildReportRow(
            label: 'Laba bersih',
            amount: _formatRupiah(report.totalLabaBersih),
          ),
          const Divider(
            color: LaporanKeuanganView.borderColor,
            height: 18,
          ),
          _buildReportRow(
            label: 'Selisih periode',
            amount: _formatRupiah(report.selisih),
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow({
    required String label,
    required String amount,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isHighlight
                  ? LaporanKeuanganView.textColor
                  : LaporanKeuanganView.secondaryColor,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: isHighlight
                ? LaporanKeuanganView.primaryColor
                : LaporanKeuanganView.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LaporanKeuanganView.softColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: LaporanKeuanganView.primaryColor,
            size: 17,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selisih merupakan total pemasukan dikurangi total pengeluaran '
              'selama periode yang dipilih, bukan saldo kas berjalan.',
              style: TextStyle(
                color: LaporanKeuanganView.secondaryColor,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LaporanKeuanganView.borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: LaporanKeuanganView.secondaryColor,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LaporanKeuanganView.secondaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _controller.isReportLoading ? null : _loadReport,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: LaporanKeuanganView.primaryColor,
              side: const BorderSide(color: LaporanKeuanganView.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LaporanKeuanganView.borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            color: LaporanKeuanganView.secondaryColor,
            size: 36,
          ),
          SizedBox(height: 10),
          Text(
            'Laporan belum tersedia untuk periode ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LaporanKeuanganView.secondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(double value) {
    final rounded = value.abs().round().toString();
    final grouped = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '${value < 0 ? '−' : ''}Rp$grouped';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }
}
