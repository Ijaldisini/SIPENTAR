import 'package:flutter/material.dart';

import '../widgets/bottom_navigation.dart';
import 'tambah_rotasi_panen_view.dart';

class BudidayaView extends StatefulWidget {
  const BudidayaView({super.key});

  @override
  State<BudidayaView> createState() => _BudidayaViewState();
}

class _BudidayaViewState extends State<BudidayaView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFDFE5D7);

  int selectedTab = 0;

  final DateTime harvestReferenceDate = DateTime(2026, 11, 5);

  DateTime selectedCalendarMonth = DateTime(2026, 11, 1);

  int selectedCalendarDay = 5;

  final List<Map<String, dynamic>> batches = [
    {
      'name': 'Batch 03',
      'plant': 'Selada',
      'date': DateTime(2026, 10, 5),
      'holes': 24,
      'harvestDate': DateTime(2026, 11, 9),
    },
    {
      'name': 'Batch 04',
      'plant': 'Selada',
      'date': DateTime(2026, 10, 18),
      'holes': 12,
      'harvestDate': DateTime(2026, 11, 22),
    },
    {
      'name': 'Batch 05',
      'plant': 'Selada',
      'date': DateTime(2026, 10, 25),
      'holes': 12,
      'harvestDate': DateTime(2026, 11, 29),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final today = harvestReferenceDate;

    final totalHoles = batches.fold<int>(
      0,
      (sum, item) => sum + (item['holes'] as int),
    );

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
            top: 136,
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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTabSelector(),

                    const SizedBox(height: 12),

                    if (selectedTab == 0) ...[
                      _buildSummary(today, totalHoles),

                      const SizedBox(height: 12),

                      _buildAddButton(),

                      const SizedBox(height: 12),

                      _buildSectionHeader(),

                      const SizedBox(height: 10),

                      ...batches.map(
                        (batch) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildBatchCard(batch, today),
                        ),
                      ),
                    ] else ...[
                      _buildHarvestContent(),
                    ],
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
        20,
        MediaQuery.paddingOf(context).top + 24,
        20,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budidaya & Panen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Pantau usia tanaman dan rencana panen.',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 24,
              ),

              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4D58A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [_buildTabButton('Budidaya', 0), _buildTabButton('Panen', 1)],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : mutedColor,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(DateTime today, int totalHoles) {
    final days = batches.isNotEmpty
        ? _daysUntilHarvest(today, batches.first)
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kebun hari ini • ${_formatDate(today)}',
            style: const TextStyle(color: mutedColor, fontSize: 10),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _summaryItem('${batches.length}', 'Batch aktif')),

              Expanded(child: _summaryItem('$totalHoles', 'Lubang tanam')),

              Expanded(child: _summaryItem('$days hari', 'Panen terdekat')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 2),

        Text(label, style: const TextStyle(color: mutedColor, fontSize: 9)),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/budidaya/tambah');
        },
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'Tambah data semai',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Budidaya aktif',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/budidaya/riwayat');
          },
          child: const Text(
            'Semua Riwayat',
            style: TextStyle(
              color: primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch, DateTime today) {
    final sowDate = batch['date'] as DateTime;
    final harvestDate = batch['harvestDate'] as DateTime;

    final age = today.difference(sowDate).inDays;
    final remaining = harvestDate.difference(today).inDays;

    final progress = (age / 35).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${batch['name']} • ${batch['plant']}',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${age < 0 ? 0 : age} HSS',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Semai ${_formatDate(sowDate)} • ${batch['holes']} lubang',
            style: const TextStyle(color: mutedColor, fontSize: 9),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE8EDDF),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Panen ${_formatDate(harvestDate)}',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                remaining >= 0
                    ? '+ $remaining hari lagi'
                    : 'Lewat ${remaining.abs()} hari',
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 6),

              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/budidaya/edit',
                    arguments: batch,
                  );
                },
                child: const Icon(
                  Icons.edit_outlined,
                  color: primaryColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestContent() {
    final monthlyRotations = _getMonthlyRotations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHarvestCalendar(),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TambahRotasiPanenView(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Tambah rotasi panen',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Rotasi bulan ini',
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        ...monthlyRotations.map(
          (batch) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildHarvestRotationCard(batch),
          ),
        ),

        if (monthlyRotations.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Belum ada jadwal panen pada bulan ini.',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHarvestCalendar() {
    final year = selectedCalendarMonth.year;
    final month = selectedCalendarMonth.month;

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final leadingDays = firstDay.weekday - 1;

    final harvestDays = batches
        .map((batch) => batch['harvestDate'] as DateTime)
        .where((date) => date.month == month && date.year == year)
        .map((date) => date.day)
        .toSet();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedCalendarMonth = DateTime(year, month - 1, 1);
                    selectedCalendarDay = 0;
                  });
                },
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: primaryColor,
                  size: 23,
                ),
                visualDensity: VisualDensity.compact,
              ),

              Expanded(
                child: Text(
                  _formatCalendarMonth(selectedCalendarMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    selectedCalendarMonth = DateTime(year, month + 1, 1);
                    selectedCalendarDay = 0;
                  });
                },
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: primaryColor,
                  size: 23,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: 2),

          Row(
            children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].map((
              day,
            ) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 5),

          SizedBox(
            height: 6 * 26,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 26,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final day = index - leadingDays + 1;

                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final isToday =
                    year == harvestReferenceDate.year &&
                    month == harvestReferenceDate.month &&
                    day == harvestReferenceDate.day;

                return _buildCalendarDay(
                  day: day,
                  isToday: isToday,
                  hasHarvest: harvestDays.contains(day),
                );
              },
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: primaryColor),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              const SizedBox(width: 5),

              const Text(
                'Hari ini',
                style: TextStyle(color: mutedColor, fontSize: 9),
              ),

              const SizedBox(width: 18),

              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              const SizedBox(width: 5),

              const Text(
                'Jadwal panen',
                style: TextStyle(color: mutedColor, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay({
    required int day,
    required bool isToday,
    required bool hasHarvest,
  }) {
    final isSelected = selectedCalendarDay == day;

    final backgroundColor = hasHarvest ? primaryColor : Colors.transparent;

    final foregroundColor = hasHarvest ? Colors.white : textColor;

    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCalendarDay = day;
          });
        },
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: (isToday || (isSelected && !hasHarvest))
                ? Border.all(color: primaryColor)
                : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$day',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: isToday || hasHarvest || isSelected
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMonthlyRotations() {
    final rotations = batches.where((batch) {
      final harvestDate = batch['harvestDate'] as DateTime;

      return harvestDate.month == selectedCalendarMonth.month &&
          harvestDate.year == selectedCalendarMonth.year;
    }).toList();

    rotations.sort((a, b) {
      final dateA = a['harvestDate'] as DateTime;
      final dateB = b['harvestDate'] as DateTime;

      return dateA.compareTo(dateB);
    });

    return rotations;
  }

  Widget _buildHarvestRotationCard(Map<String, dynamic> batch) {
    final harvestDate = batch['harvestDate'] as DateTime;

    final remaining = harvestDate.difference(harvestReferenceDate).inDays;

    return Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 46,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  harvestDate.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                Text(
                  _formatMonthShort(harvestDate.month),
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${batch['name']} • ${batch['plant']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${batch['holes']} lubang',
                  style: const TextStyle(color: mutedColor, fontSize: 9),
                ),
              ],
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                remaining >= 0
                    ? '$remaining hari lagi'
                    : 'Lewat ${remaining.abs()} hari',
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/panen/edit', arguments: batch);
                },
                child: const Icon(
                  Icons.edit_outlined,
                  color: primaryColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _daysUntilHarvest(DateTime today, Map<String, dynamic> batch) {
    return (batch['harvestDate'] as DateTime).difference(today).inDays;
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

  String _formatCalendarMonth(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatMonthShort(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];

    return months[month - 1];
  }
}
