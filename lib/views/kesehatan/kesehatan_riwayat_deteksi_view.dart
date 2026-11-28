import 'package:flutter/material.dart';

import '../../controllers/diagnosis/diagnosis_controller.dart';
import '../../models/diagnosis/diagnosis_model.dart';
import 'kesehatan_riwayat_detail_view.dart';

/// Riwayat diagnosis dengan susunan UI awal.
/// Data bulan diambil dari API; pencarian dan kategori Perhatian difilter lokal
/// karena endpoint diagnosis tidak menyediakan parameter pencarian/negasi hasil.
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

  final DiagnosisController _diagnosisController = DiagnosisController();
  final TextEditingController searchController = TextEditingController();

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  String selectedFilter = 'Semua';
  bool _isLoadingMonth = false;
  bool _monthFullyLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMonth();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  DateTime get _monthStart =>
      DateTime(selectedMonth.year, selectedMonth.month, 1);

  DateTime get _monthEnd =>
      DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

  Future<void> _loadMonth() async {
    if (_isLoadingMonth) return;

    _diagnosisController.reset();

    setState(() {
      _isLoadingMonth = true;
      _monthFullyLoaded = false;
    });

    var complete = await _diagnosisController.loadDiagnoses(
      from: _monthStart,
      to: _monthEnd,
      perPage: 50,
    );

    // Ambil seluruh halaman dalam bulan terpilih agar ringkasan normal/perhatian
    // dihitung dari semua record bulan itu, bukan hanya halaman pertama.
    while (complete && _diagnosisController.hasMoreDiagnoses && mounted) {
      complete = await _diagnosisController.loadMoreDiagnoses();
    }

    if (!mounted) return;

    setState(() {
      _isLoadingMonth = false;
      _monthFullyLoaded = complete && !_diagnosisController.hasMoreDiagnoses;
    });
  }

  List<DiagnosisModel> get monthRecords =>
      _diagnosisController.diagnoses.where((record) {
        return record.tanggalDiagnosis.year == selectedMonth.year &&
            record.tanggalDiagnosis.month == selectedMonth.month;
      }).toList();

  List<DiagnosisModel> get filteredRecords {
    final query = searchController.text.toLowerCase().trim();

    return monthRecords.where((record) {
      final matchesFilter = switch (selectedFilter) {
        'Normal' => record.isSehat,
        'Perlu perhatian' => !record.isSehat,
        _ => true,
      };

      final meja = record.budidaya?.meja?.nomorMeja ?? record.budidaya?.mejaId;
      final searchValues = [
        'budidaya ${record.budidayaId}',
        'budidaya #${record.budidayaId}',
        'diagnosis ${record.id}',
        'meja ${meja ?? ''}',
        record.hasil,
        record.hasilLabel,
        record.user?.nama ?? '',
        record.user?.username ?? '',
      ];
      final matchesSearch =
          query.isEmpty ||
          searchValues.any((value) => value.toLowerCase().contains(query));

      return matchesFilter && matchesSearch;
    }).toList();
  }

  int get totalCount => _diagnosisController.totalDiagnoses;

  int get normalCount => monthRecords.where((record) => record.isSehat).length;

  int get attentionCount =>
      monthRecords.where((record) => !record.isSehat).length;

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
      await _loadMonth();
    }
  }

  void _openDetail(DiagnosisModel record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            KesehatanRiwayatDetailView(diagnosisId: record.id),
      ),
    );
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
                child: AnimatedBuilder(
                  animation: _diagnosisController,
                  builder: (context, _) {
                    return SingleChildScrollView(
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
                          if (_diagnosisController.errorMessage != null &&
                              monthRecords.isEmpty)
                            _buildErrorState(),
                          if (_isLoadingMonth && monthRecords.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 25),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ...filteredRecords.map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildHistoryCard(record),
                            ),
                          ),
                          if (!_isLoadingMonth &&
                              _diagnosisController.errorMessage == null &&
                              filteredRecords.isEmpty)
                            _buildEmptyState(),
                          if (_diagnosisController.loadMoreErrorMessage != null)
                            _buildLoadMoreError(),
                        ],
                      ),
                    );
                  },
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
        onChanged: (value) => setState(() {}),
        style: const TextStyle(
          color: textColor,
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          hintText: 'Cari budidaya atau kondisi...',
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
            count: _monthFullyLoaded ? normalCount : null,
            filter: 'Normal',
            color: softGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFilterButton(
            label: 'Perhatian',
            count: _monthFullyLoaded ? attentionCount : null,
            filter: 'Perlu perhatian',
            color: warningBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required int? count,
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
            '$label${count == null ? '' : ' ($count)'}',
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
                '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
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
    final subtitle = _monthFullyLoaded
        ? '$normalCount normal, $attentionCount perlu perhatian'
        : 'Memuat ringkasan pemeriksaan...';

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
            _isLoadingMonth && monthRecords.isEmpty
                ? 'Memuat pemeriksaan...'
                : '$totalCount pemeriksaan tersimpan',
            style: const TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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

  Widget _buildHistoryCard(DiagnosisModel record) {
    final bool isWarning = !record.isSehat;
    final Color statusColor = isWarning ? warningColor : primaryColor;
    final Color statusBackground = isWarning ? warningBackground : softGreen;
    final meja = record.budidaya?.meja?.nomorMeja ?? record.budidaya?.mejaId;

    return InkWell(
      onTap: () => _openDetail(record),
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
                record.imageUrl,
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
                    'Budidaya #${record.budidayaId}',
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
                    _formatDate(record.tanggalDiagnosis),
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meja == null ? 'ID diagnosis ${record.id}' : 'Meja $meja',
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
                      isWarning ? 'Perlu perhatian' : 'Normal',
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

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: mutedColor),
            const SizedBox(height: 12),
            const Text(
              'Riwayat gagal dimuat',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _diagnosisController.errorMessage ?? 'Silakan coba lagi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontFamily: 'Inter',
              ),
            ),
            TextButton.icon(
              onPressed: _isLoadingMonth ? null : _loadMonth,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba lagi'),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreError() {
    return Center(
      child: TextButton.icon(
        onPressed: _isLoadingMonth ? null : _loadMonth,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Muat ulang riwayat'),
        style: TextButton.styleFrom(foregroundColor: primaryColor),
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
