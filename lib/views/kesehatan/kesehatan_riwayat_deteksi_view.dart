import 'dart:io';

import 'package:flutter/material.dart';

import 'kesehatan_hasil_deteksi_view.dart';

class KesehatanRiwayatDeteksiView extends StatefulWidget {
  const KesehatanRiwayatDeteksiView({super.key});

  @override
  State<KesehatanRiwayatDeteksiView> createState() =>
      _KesehatanRiwayatDeteksiViewState();
}

class _KesehatanRiwayatDeteksiViewState
    extends State<KesehatanRiwayatDeteksiView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softGreen = Color(0xFFF1F5E9);
  static const Color warningColor = Color(0xFF8C5B16);
  static const Color warningBackground = Color(0xFFFFF5DF);

  static const String sampleImage =
      'https://images.unsplash.com/photo-1540420773420-3366772f4999'
      '?auto=format&fit=crop&w=300&q=80';

  final TextEditingController searchController = TextEditingController();

  DateTime selectedMonth = DateTime(2026, 11, 1);

  String selectedFilter = 'Semua';

  final List<_DetectionRecord> records = [
    _DetectionRecord(
      batch: 'Batch 04 • Selada',
      date: DateTime(2026, 11, 5, 9, 41),
      location: 'Meja B1',
      status: 'Perlu perhatian',
    ),
    _DetectionRecord(
      batch: 'Batch 03 • Selada',
      date: DateTime(2026, 11, 4, 8, 15),
      location: 'Meja A1',
      status: 'Normal',
    ),
    _DetectionRecord(
      batch: 'Batch 05 • Selada',
      date: DateTime(2026, 11, 3, 10, 20),
      location: 'Meja C1',
      status: 'Normal',
    ),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<_DetectionRecord> get monthRecords {
    return records.where((record) {
      return record.date.month == selectedMonth.month &&
          record.date.year == selectedMonth.year;
    }).toList();
  }

  List<_DetectionRecord> get filteredRecords {
    final query = searchController.text.toLowerCase().trim();

    return monthRecords.where((record) {
      final matchesSearch =
          record.batch.toLowerCase().contains(query) ||
          record.location.toLowerCase().contains(query) ||
          record.status.toLowerCase().contains(query);

      final matchesFilter =
          selectedFilter == 'Semua' || record.status == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get totalCount => monthRecords.length;

  int get normalCount =>
      monthRecords.where((record) => record.status == 'Normal').length;

  int get attentionCount =>
      monthRecords.where((record) => record.status == 'Perlu perhatian').length;

  String _monthName(int month) {
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

  String _formatDate(DateTime date) {
    const abbreviatedMonths = [
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

    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day ${abbreviatedMonths[date.month - 1]} '
        '${date.year}, $hour.$minute';
  }

  Future<void> _selectMonth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Pilih bulan pemeriksaan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
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

    if (pickedDate != null && mounted) {
      setState(() {
        selectedMonth = DateTime(pickedDate.year, pickedDate.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Riwayat deteksi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchField(),

                      const SizedBox(height: 12),

                      _buildFilterButtons(),

                      const SizedBox(height: 16),

                      _buildMonthSelector(),

                      const SizedBox(height: 16),

                      _buildSummary(),

                      const SizedBox(height: 16),

                      ...filteredRecords.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildHistoryCard(record),
                        ),
                      ),

                      if (filteredRecords.isEmpty) _buildEmptyState(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {});
        },
        style: const TextStyle(
          color: textColor,
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          hintText: 'Cari batch atau kondisi...',
          hintStyle: const TextStyle(
            color: mutedColor,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
          prefixIcon: const Icon(Icons.search, color: mutedColor, size: 19),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.close, size: 17, color: mutedColor),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            label: 'Semua',
            count: totalCount,
            filter: 'Semua',
            color: softGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFilterButton(
            label: 'Normal',
            count: normalCount,
            filter: 'Normal',
            color: softGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFilterButton(
            label: 'Perhatian',
            count: attentionCount,
            filter: 'Perlu perhatian',
            color: warningBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required int count,
    required String filter,
    required Color color,
  }) {
    final bool isSelected = selectedFilter == filter;

    final Color background = isSelected
        ? (filter == 'Perlu perhatian' ? warningBackground : primaryColor)
        : color;

    final Color foreground = isSelected
        ? (filter == 'Perlu perhatian' ? warningColor : Colors.white)
        : (filter == 'Perlu perhatian' ? warningColor : primaryColor);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return InkWell(
      onTap: _selectMonth,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDFE5D7)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_monthName(selectedMonth.month)} '
                '${selectedMonth.year}',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 21,
              color: mutedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$totalCount pemeriksaan tersimpan',
            style: const TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$normalCount normal, $attentionCount perlu perhatian',
            style: const TextStyle(
              color: mutedColor,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(_DetectionRecord record) {
    final bool isWarning = record.status == 'Perlu perhatian';

    final Color statusColor = isWarning ? warningColor : primaryColor;

    final Color statusBackground = isWarning ? warningBackground : softGreen;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KesehatanHasilDeteksiView(
              daunFoto: record.daunFoto,
              batangFoto: record.batangFoto,
              batchName: record.batch,
              catatanGejala: record.catatanGejala,
              status: record.status,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 108,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDFE5D7)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                sampleImage,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 90,
                    height: 90,
                    color: softGreen,
                    child: const Icon(
                      Icons.eco_outlined,
                      color: primaryColor,
                      size: 34,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.batch,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(record.date),
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record.location,
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      record.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: mutedColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Riwayat tidak ditemukan',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Coba ubah kata pencarian atau filter.',
              style: TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionRecord {
  final String batch;
  final DateTime date;
  final String location;
  final String status;

  final File? daunFoto;
  final File? batangFoto;
  final String catatanGejala;

  const _DetectionRecord({
    required this.batch,
    required this.date,
    required this.location,
    required this.status,
    this.daunFoto,
    this.batangFoto,
    this.catatanGejala = '',
  });
}
