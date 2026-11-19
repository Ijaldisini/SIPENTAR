import 'package:flutter/material.dart';

class KalkulasiHppView extends StatefulWidget {
  const KalkulasiHppView({super.key});

  @override
  State<KalkulasiHppView> createState() => _KalkulasiHppViewState();
}

class _KalkulasiHppViewState extends State<KalkulasiHppView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color borderColor = Color(0xFFB7C4A5);

  final TextEditingController holeController = TextEditingController(
    text: '1200',
  );

  // Dummy biaya produksi
  final List<Map<String, dynamic>> productionCosts = const [
    {'name': 'Benih', 'amount': 600000},
    {'name': 'Nutrisi', 'amount': 1800000},
    {'name': 'Media tanam', 'amount': 1200000},
    {'name': 'Listrik & air', 'amount': 900000},
    {'name': 'Kemasan', 'amount': 300000},
  ];

  // Total biaya produksi
  int get totalProductionCost {
    return productionCosts.fold<int>(
      0,
      (total, item) => total + (item['amount'] as int),
    );
  }

  // Jumlah lubang tanam
  int get totalHoles {
    return int.tryParse(
          holeController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
  }

  // HPP per lubang tanam
  int get hppPerHole {
    if (totalHoles <= 0) return 0;

    return (totalProductionCost / totalHoles).round();
  }

  @override
  void dispose() {
    holeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: primaryColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: _buildHeader(context),
          ),

          // White content panel
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
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCycleSelector(),

                          const SizedBox(height: 16),

                          _buildHoleInput(),

                          const SizedBox(height: 16),

                          _buildProductionCostCard(),

                          const SizedBox(height: 16),

                          _buildHppResultCard(),

                          const SizedBox(height: 12),

                          const Text(
                            'HPP belum memperhitungkan tanaman gagal '
                            'atau susut panen.',
                            style: TextStyle(
                              color: Color(0xFF70786B),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Fixed calculate button
                  _buildCalculateButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HEADER
  // =========================

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

  // =========================
  // CYCLE SELECTOR
  // =========================

  Widget _buildCycleSelector() {
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDFE5D7)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: primaryColor,
            size: 18,
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Siklus Tanam November 2026',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryColor,
            size: 21,
          ),
        ],
      ),
    );
  }

  // =========================
  // HOLE INPUT
  // =========================

  Widget _buildHoleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Jumlah lubang tanam'),

        const SizedBox(height: 8),

        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: holeController,
                  keyboardType: TextInputType.number,
                  cursorColor: primaryColor,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),

              const Text(
                'lubang',
                style: TextStyle(color: Color(0xFF70786B), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // PRODUCTION COST CARD
  // =========================

  Widget _buildProductionCostCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biaya produksi',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'Dari pengeluaran siklus terpilih',
            style: TextStyle(color: Color(0xFF70786B), fontSize: 11),
          ),

          const SizedBox(height: 12),

          ...productionCosts.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCostRow(
                name: item['name'] as String,
                amount: item['amount'] as int,
              ),
            ),
          ),

          const Divider(color: Color(0xFFDFE5D7), height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total biaya',
                style: TextStyle(
                  color: Color(0xFF70786B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              Text(
                _formatRupiah(totalProductionCost),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow({required String name, required int amount}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFF70786B),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),

        Text(
          _formatRupiah(amount),
          style: const TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================
  // HPP RESULT CARD
  // =========================

  Widget _buildHppResultCard() {
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
            'HPP per lubang tanam',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            _formatRupiah(hppPerHole),
            style: const TextStyle(
              color: textColor,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${_formatRupiah(totalProductionCost)} ÷ '
            '${_formatNumber(totalHoles)} lubang tanam',
            style: const TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // COMMON WIDGETS
  // =========================

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

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  String _formatRupiah(int value) {
    return 'Rp${_formatNumber(value)}';
  }

  // =========================
  // CALCULATE BUTTON
  // =========================

  Widget _buildCalculateButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              final holes = totalHoles;

              if (holes <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jumlah lubang tanam harus lebih dari 0.'),
                  ),
                );
                return;
              }

              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'HPP berhasil dihitung: '
                    '${_formatRupiah(hppPerHole)} per lubang tanam.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Hitung HPP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
