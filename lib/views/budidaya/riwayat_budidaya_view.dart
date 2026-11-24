import 'package:flutter/material.dart';

import '../widgets/bottom_navigation.dart';

class RiwayatBudidayaView extends StatefulWidget {
  const RiwayatBudidayaView({super.key});

  @override
  State<RiwayatBudidayaView> createState() => _RiwayatBudidayaViewState();
}

class _RiwayatBudidayaViewState extends State<RiwayatBudidayaView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFDFE5D7);

  int selectedTab = 1;

  String selectedPeriod = 'Semua periode';

  final DateTime referenceDate = DateTime(2026, 11, 5);

  final List<_BatchRecord> activeRecords = [
    _BatchRecord(
      name: 'Batch 03',
      plant: 'Selada',
      holes: 24,
      sowDate: DateTime(2026, 10, 5),
      harvestDate: DateTime(2026, 11, 9),
    ),
    _BatchRecord(
      name: 'Batch 04',
      plant: 'Selada',
      holes: 12,
      sowDate: DateTime(2026, 10, 18),
      harvestDate: DateTime(2026, 11, 22),
    ),
    _BatchRecord(
      name: 'Batch 05',
      plant: 'Selada',
      holes: 12,
      sowDate: DateTime(2026, 10, 25),
      harvestDate: DateTime(2026, 11, 29),
    ),
  ];

  final List<_BatchRecord> completedRecords = [
    _BatchRecord(
      name: 'Batch 02',
      plant: 'Selada',
      holes: 12,
      sowDate: DateTime(2026, 9, 7),
      harvestDate: DateTime(2026, 10, 12),
      hssAtHarvest: 35,
    ),
    _BatchRecord(
      name: 'Batch 01',
      plant: 'Selada',
      holes: 12,
      sowDate: DateTime(2026, 8, 24),
      harvestDate: DateTime(2026, 9, 28),
      hssAtHarvest: 35,
    ),
  ];

  List<_BatchRecord> get currentRecords {
    return selectedTab == 0 ? activeRecords : completedRecords;
  }

  List<_BatchRecord> get filteredRecords {
    return currentRecords.where((record) {
      if (selectedPeriod == 'Semua periode') {
        return true;
      }

      final month = record.sowDate.month;
      final year = record.sowDate.year;

      switch (selectedPeriod) {
        case 'Agustus 2026':
          return month == 8 && year == 2026;

        case 'September 2026':
          return month == 9 && year == 2026;

        case 'Oktober 2026':
          return month == 10 && year == 2026;

        default:
          return true;
      }
    }).toList();
  }

  int get totalHoles {
    return filteredRecords.fold<int>(
      0,
      (total, record) => total + record.holes,
    );
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusTabs(),

                    const SizedBox(height: 12),

                    _buildPeriodSelector(),

                    const SizedBox(height: 12),

                    _buildSummaryCard(),

                    const SizedBox(height: 12),

                    if (filteredRecords.isEmpty)
                      _buildEmptyState()
                    else
                      ...filteredRecords.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRecordCard(record),
                        ),
                      ),

                    if (selectedTab == 1 && filteredRecords.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'Umur pada riwayat berhenti dihitung saat tanggal panen.',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2),
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
            'Riwayat budidaya',
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

  Widget _buildStatusTabs() {
    return Row(
      children: [
        _buildStatusButton(title: 'Aktif (${activeRecords.length})', index: 0),

        const SizedBox(width: 8),

        _buildStatusButton(
          title: 'Selesai (${completedRecords.length})',
          index: 1,
        ),
      ],
    );
  }

  Widget _buildStatusButton({required String title, required int index}) {
    final isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
          selectedPeriod = 'Semua periode';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: index == 0 ? 108 : 120,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : softColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : mutedColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const periods = [
      'Semua periode',
      'Agustus 2026',
      'September 2026',
      'Oktober 2026',
    ];

    return Container(
      height: 44,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: primaryColor,
            size: 18,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPeriod,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primaryColor,
                ),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                items: periods.map((period) {
                  return DropdownMenuItem<String>(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedPeriod = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final isCompleted = selectedTab == 1;

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
          Text(
            isCompleted
                ? '${filteredRecords.length} batch selesai dipanen'
                : '${filteredRecords.length} batch masih aktif',
            style: const TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '$totalHoles lubang tanam',
            style: const TextStyle(
              color: mutedColor,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(_BatchRecord record) {
    final isCompleted = selectedTab == 1;

    final age = isCompleted
        ? record.hssAtHarvest
        : referenceDate.difference(record.sowDate).inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${record.name} • ${record.plant}',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Selesai' : 'Aktif',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            '${record.holes} lubang',
            style: const TextStyle(color: mutedColor, fontSize: 10),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildDateInfo(
                  label: 'Tanggal semai',
                  date: record.sowDate,
                ),
              ),

              Expanded(
                child: _buildDateInfo(
                  label: 'Tanggal panen',
                  date: record.harvestDate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Divider(color: borderColor, height: 1),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_outline_rounded
                    : Icons.eco_outlined,
                color: primaryColor,
                size: 16,
              ),

              const SizedBox(width: 8),

              Text(
                isCompleted ? '$age HSS saat panen' : '$age HSS saat ini',
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo({required String label, required DateTime date}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: mutedColor, fontSize: 10)),

        const SizedBox(height: 4),

        Text(
          _formatDate(date),
          style: const TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, color: primaryColor, size: 38),

          SizedBox(height: 10),

          Text(
            'Tidak ada riwayat budidaya',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 4),

          Text(
            'Belum ada batch pada periode ini.',
            style: TextStyle(color: mutedColor, fontSize: 11),
          ),
        ],
      ),
    );
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

class _BatchRecord {
  final String name;
  final String plant;
  final int holes;
  final DateTime sowDate;
  final DateTime harvestDate;
  final int hssAtHarvest;

  const _BatchRecord({
    required this.name,
    required this.plant,
    required this.holes,
    required this.sowDate,
    required this.harvestDate,
    this.hssAtHarvest = 0,
  });
}
