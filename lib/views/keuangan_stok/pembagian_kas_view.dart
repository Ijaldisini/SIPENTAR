import 'package:flutter/material.dart';

class PembagianKasView extends StatefulWidget {
  const PembagianKasView({super.key});

  @override
  State<PembagianKasView> createState() => _PembagianKasViewState();
}

class _PembagianKasViewState extends State<PembagianKasView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);

  // Dummy omzet penjualan
  static const int totalRevenue = 12000000;

  // Persentase awal sesuai Figma
  final List<int> percentages = [40, 30, 10, 20];

  // Data alokasi kas
  final List<Map<String, String>> allocations = const [
    {'title': 'Kas operasional', 'description': 'Untuk kebutuhan rutin'},
    {'title': 'Modal tanam berikutnya', 'description': 'Persiapan siklus baru'},
    {'title': 'Dana cadangan', 'description': 'Antisipasi kebutuhan darurat'},
    {
      'title': 'Bagian keuntungan',
      'description': 'Hasil usaha yang disisihkan',
    },
  ];

  // Total persentase
  int get totalPercentage {
    return percentages.fold(0, (total, value) => total + value);
  }

  // Total nominal pembagian
  int get totalAllocated {
    return percentages.fold(
      0,
      (total, value) => total + (totalRevenue * value ~/ 100),
    );
  }

  // Menghitung nominal tiap alokasi
  int getAllocationAmount(int index) {
    return totalRevenue * percentages[index] ~/ 100;
  }

  // Mengatur persentase
  void _changePercentage(int index, int change) {
    setState(() {
      final newValue = percentages[index] + change;

      if (newValue < 0 || newValue > 100) return;

      percentages[index] = newValue;
    });
  }

  // Format rupiah
  String _formatRupiah(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // Green header
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
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Revenue card
                          _buildRevenueCard(),

                          const SizedBox(height: 16),

                          // Section heading
                          _buildSectionHeading(),

                          const SizedBox(height: 12),

                          // Allocation cards
                          ...List.generate(
                            allocations.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: index == allocations.length - 1 ? 0 : 6,
                              ),
                              child: _buildAllocationCard(index),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Total allocation
                          _buildTotalCard(),

                          const SizedBox(height: 10),

                          // Information
                          const Text(
                            'Ini adalah rencana alokasi kas, bukan '
                            'pencatatan pengeluaran baru. '
                            'Total pembagian harus 100%.',
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

                  // Fixed bottom button
                  _buildBottomButton(context),
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

  // =========================
  // REVENUE CARD
  // =========================

  Widget _buildRevenueCard() {
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
            'Omzet Penjualan November 2026',
            style: TextStyle(
              color: Color(0xFF70786B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _formatRupiah(totalRevenue),
            style: const TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SECTION HEADING
  // =========================

  Widget _buildSectionHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atur pembagian kas',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: 2),

        Text(
          'Nominal dihitung dari persentase × omzet.',
          style: TextStyle(
            color: Color(0xFF70786B),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // =========================
  // ALLOCATION CARD
  // =========================

  Widget _buildAllocationCard(int index) {
    final item = allocations[index];
    final percentage = percentages[index];
    final amount = getAllocationAmount(index);

    return Container(
      width: double.infinity,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDFE5D7), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Allocation information
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  item['description']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF70786B),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Percentage controller and nominal
          SizedBox(
            width: 112,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildPercentageButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        _changePercentage(index, -5);
                      },
                    ),

                    Container(
                      width: 36,
                      height: 23,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFCAD5BE)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: Color(0xFF40552B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    _buildPercentageButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        _changePercentage(index, 5);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatRupiah(amount),
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // PERCENTAGE BUTTON
  // =========================

  Widget _buildPercentageButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 23,
      height: 23,
      child: Material(
        color: softColor,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Icon(icon, color: const Color(0xFF506733), size: 14),
        ),
      ),
    );
  }

  // =========================
  // TOTAL CARD
  // =========================

  Widget _buildTotalCard() {
    final isValid = totalPercentage == 100;

    return Container(
      width: double.infinity,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isValid
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: isValid ? primaryColor : const Color(0xFFB7791F),
            size: 19,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Total $totalPercentage%',
              style: const TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Text(
            _formatRupiah(totalAllocated),
            style: const TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SAVE BUTTON
  // =========================

  Widget _buildBottomButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              if (totalPercentage != 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Total pembagian saat ini $totalPercentage%. '
                      'Sesuaikan menjadi 100% terlebih dahulu.',
                    ),
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembagian kas berhasil disimpan (dummy).'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Simpan pembagian kas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
