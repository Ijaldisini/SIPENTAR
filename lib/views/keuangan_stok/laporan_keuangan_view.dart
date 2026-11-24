import 'package:flutter/material.dart';

class LaporanKeuanganView extends StatelessWidget {
  const LaporanKeuanganView({super.key});

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color secondaryColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFDFE5D7);
  static const Color expenseColor = Color(0xFFC8AF86);

  static const List<Map<String, dynamic>> dailyCashflow = [
    {'date': '01 Nov', 'income': 36.0, 'expense': 12.0},
    {'date': '02 Nov', 'income': 48.0, 'expense': 16.0},
    {'date': '03 Nov', 'income': 60.0, 'expense': 24.0},
    {'date': '04 Nov', 'income': 72.0, 'expense': 9.0},
    {'date': '05 Nov', 'income': 24.0, 'expense': 35.0},
  ];

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
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPeriodSelector(),

                          const SizedBox(height: 16),

                          _buildSurplusCard(),

                          const SizedBox(height: 12),

                          _buildCashflowChart(),

                          const SizedBox(height: 16),

                          _buildReportDetails(),
                        ],
                      ),
                    ),
                  ),

                  _buildDownloadButton(context),
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
            onTap: () {
              Navigator.pop(context);
            },
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
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: primaryColor, size: 19),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'November 2026',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryColor,
            size: 21,
          ),
        ],
      ),
    );
  }

  Widget _buildSurplusCard() {
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
            'Surplus kas',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'Rp7.200.000',
            style: TextStyle(
              color: textColor,
              fontSize: 29,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          const Divider(color: borderColor, height: 1),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildCashSummary(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: primaryColor,
                  label: 'Masuk',
                  amount: 'Rp12.000.000',
                ),
              ),

              Expanded(
                child: _buildCashSummary(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFAE4E3D),
                  label: 'Keluar',
                  amount: 'Rp4.800.000',
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
                style: const TextStyle(color: secondaryColor, fontSize: 11),
              ),

              const SizedBox(height: 2),

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

  Widget _buildCashflowChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arus kas harian',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              _buildChartLegend(color: primaryColor, label: 'Pemasukan'),

              const SizedBox(width: 18),

              _buildChartLegend(color: expenseColor, label: 'Pengeluaran'),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 102,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyCashflow.map((data) {
                return Expanded(
                  child: _buildChartBar(
                    date: data['date'] as String,
                    income: data['income'] as double,
                    expense: data['expense'] as double,
                  ),
                );
              }).toList(),
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
            color: secondaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChartBar({
    required String date,
    required double income,
    required double expense,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 14,
                height: income,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              Container(
                width: 14,
                height: expense,
                decoration: BoxDecoration(
                  color: expenseColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 7),

        Text(
          date,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: secondaryColor,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReportDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rincian laporan',
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        _buildReportRow(label: 'Penjualan hasil panen', amount: 'Rp12.000.000'),

        const Divider(color: borderColor, height: 16),

        _buildReportRow(label: 'Kas Operasional', amount: 'Rp4.800.000'),

        const Divider(color: borderColor, height: 16),

        _buildReportRow(
          label: 'Surplus kas',
          amount: 'Rp7.200.000',
          isHighlight: true,
        ),
      ],
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
              color: isHighlight ? textColor : secondaryColor,
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
            color: isHighlight ? primaryColor : textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Fitur unduh laporan PDF akan tersedia '
                    'setelah implementasi ekspor laporan.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.file_download_outlined, size: 20),
            label: const Text(
              'Unduh laporan PDF',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
