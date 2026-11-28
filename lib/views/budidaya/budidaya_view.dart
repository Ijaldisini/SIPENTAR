import 'package:flutter/material.dart';

import '../../controllers/budidaya/budidaya_controller.dart';
import '../../controllers/panen/panen_controller.dart';
import '../../models/budidaya/budidaya_model.dart';
import '../../models/panen/panen_model.dart';
import '../widgets/bottom_navigation.dart';

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

  late final BudidayaController _budidayaController;
  late final PanenController _panenController;
  late final ScrollController _scrollController;

  int selectedTab = 0;
  String selectedStatus = BudidayaModel.statusBerjalan;

  DateTime selectedCalendarMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  int selectedCalendarDay = DateTime.now().day;
  String? _loadedPanenMonthKey;

  @override
  void initState() {
    super.initState();
    _budidayaController = BudidayaController();
    _panenController = PanenController();
    _scrollController = ScrollController()..addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudidaya();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _budidayaController.dispose();
    _panenController.dispose();
    super.dispose();
  }

  Future<void> _loadBudidaya({String? status}) async {
    final effectiveStatus = selectedStatus == 'semua'
        ? null
        : status ?? selectedStatus;

    await _budidayaController.loadBudidayas(
      status: effectiveStatus,
      perPage: 15,
    );
  }

  Future<void> _changeStatus(String value) async {
    if (selectedStatus == value || _budidayaController.isLoading) return;

    setState(() => selectedStatus = value);
    await _loadBudidaya(status: value == 'semua' ? null : value);
  }

  void _selectTab(int index) {
    if (selectedTab == index) return;
    setState(() => selectedTab = index);

    if (index == 1) {
      _loadPanensForSelectedMonth();
    }
  }

  String _calendarMonthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  Future<void> _loadPanensForSelectedMonth({bool force = false}) async {
    final monthKey = _calendarMonthKey(selectedCalendarMonth);
    if (_panenController.isLoading || _panenController.isLoadingMore) return;
    if (!force && _loadedPanenMonthKey == monthKey) return;

    final from = DateTime(
      selectedCalendarMonth.year,
      selectedCalendarMonth.month,
      1,
    );
    final to = DateTime(
      selectedCalendarMonth.year,
      selectedCalendarMonth.month + 1,
      0,
    );

    final loaded = await _panenController.loadPanens(
      from: from,
      to: to,
      perPage: 50,
    );

    if (!mounted) return;
    if (loaded) {
      setState(() => _loadedPanenMonthKey = monthKey);
    }
  }

  Future<void> _refreshCurrentTab() async {
    if (selectedTab == 0) {
      await _budidayaController.refreshBudidayas();
    } else {
      await _loadPanensForSelectedMonth(force: true);
    }
  }

  List<PanenModel> get _panensForSelectedMonth =>
      _panenController.panens.where((item) {
        return item.tanggalPanen.year == selectedCalendarMonth.year &&
            item.tanggalPanen.month == selectedCalendarMonth.month;
      }).toList();

  Future<void> _openTambahPanen() async {
    final saved = await Navigator.pushNamed(context, '/panen/tambah');
    if (!mounted) return;
    if (saved == true) {
      await _loadPanensForSelectedMonth(force: true);
    }
  }

  Future<void> _openEditPanen(PanenModel item) async {
    final saved = await Navigator.pushNamed(
      context,
      '/panen/edit',
      arguments: {'id': item.id},
    );
    if (!mounted) return;
    if (saved == true) {
      await _loadPanensForSelectedMonth(force: true);
    }
  }

  Future<void> _changeCalendarMonth(int offset) async {
    if (_panenController.isLoading || _panenController.isLoadingMore) return;

    setState(() {
      selectedCalendarMonth = DateTime(
        selectedCalendarMonth.year,
        selectedCalendarMonth.month + offset,
        1,
      );
      selectedCalendarDay = 1;
    });

    await _loadPanensForSelectedMonth(force: true);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels >= 240) return;

    if (selectedTab == 0) {
      if (_budidayaController.hasMoreBudidayas &&
          !_budidayaController.isLoadingMore &&
          !_budidayaController.isLoading) {
        _budidayaController.loadMoreBudidayas();
      }
      return;
    }

    if (_panenController.hasMorePanens &&
        !_panenController.isLoadingMore &&
        !_panenController.isLoading) {
      _panenController.loadMorePanens();
    }
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
            top: 136,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _budidayaController,
                  _panenController,
                ]),
                builder: (context, _) {
                  return RefreshIndicator(
                    color: primaryColor,
                    onRefresh: _refreshCurrentTab,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTabSelector(),
                          const SizedBox(height: 12),
                          if (selectedTab == 0)
                            _buildBudidayaContent()
                          else
                            _buildHarvestContent(),
                        ],
                      ),
                    ),
                  );
                },
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
        onTap: () => _selectTab(index),
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

  Widget _buildBudidayaContent() {
    final items = _budidayaController.budidayas;
    final totalPlants = items.fold<int>(
      0,
      (sum, item) => sum + item.jumlahTanaman,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBudidayaSummary(
          total: _budidayaController.totalBudidayas,
          loaded: items.length,
          totalPlants: totalPlants,
        ),
        const SizedBox(height: 12),
        _buildAddButton(),
        const SizedBox(height: 12),
        _buildSectionHeader(),
        const SizedBox(height: 10),
        _buildStatusFilters(),
        const SizedBox(height: 10),
        if (_budidayaController.isLoading && items.isEmpty)
          _buildLoadingState()
        else if (_budidayaController.errorMessage != null && items.isEmpty)
          _buildErrorState(_budidayaController.errorMessage!)
        else if (items.isEmpty)
          _buildEmptyState()
        else ...[
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildBudidayaCard(item),
            ),
          ),
          if (_budidayaController.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          if (_budidayaController.loadMoreErrorMessage != null)
            _buildLoadMoreError(),
          if (_budidayaController.hasMoreBudidayas &&
              !_budidayaController.isLoadingMore)
            _buildLoadMoreButton(),
        ],
      ],
    );
  }

  Widget _buildBudidayaSummary({
    required int total,
    required int loaded,
    required int totalPlants,
  }) {
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
          const Text(
            'Ringkasan budidaya',
            style: TextStyle(color: mutedColor, fontSize: 10),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _summaryItem('$total', 'Total data')),
              Expanded(child: _summaryItem('$loaded', 'Data termuat')),
              Expanded(child: _summaryItem('$totalPlants', 'Tanaman termuat')),
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
        onPressed: () async {
          await Navigator.pushNamed(context, '/budidaya/tambah');
          if (mounted) _budidayaController.refreshBudidayas();
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
          'Daftar budidaya',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${_budidayaController.totalBudidayas} data',
          style: const TextStyle(
            color: primaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusFilter('Berjalan', BudidayaModel.statusBerjalan),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusFilter('Selesai', BudidayaModel.statusSelesai),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildStatusFilter('Semua', 'semua')),
      ],
    );
  }

  Widget _buildStatusFilter(String label, String value) {
    final selected = selectedStatus == value;

    return GestureDetector(
      onTap: () => _changeStatus(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primaryColor : softColor,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : primaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _openEditBudidaya(BudidayaModel item) async {
    await Navigator.pushNamed(
      context,
      '/budidaya/edit',
      arguments: {
        'id': item.id,
        'meja_id': item.mejaId,
        'tanggal_semai': _formatApiDate(item.tanggalSemai),
        'jumlah_tanaman': item.jumlahTanaman,
        'status': item.status,
      },
    );

    if (mounted) {
      await _budidayaController.refreshBudidayas();
    }
  }

  String _formatApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Widget _buildBudidayaCard(BudidayaModel item) {
    final mejaLabel = item.meja == null
        ? 'Meja ${item.mejaId}'
        : 'Meja ${item.meja!.nomorMeja}';
    final isRunning = item.status == BudidayaModel.statusBerjalan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
                  'Budidaya #${item.id}',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isRunning ? softColor : const Color(0xFFF3F0E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isRunning ? 'Berjalan' : 'Selesai',
                  style: TextStyle(
                    color: isRunning ? primaryColor : const Color(0xFF8A7047),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.hss} HSS',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Semai ${_formatDate(item.tanggalSemai)} • $mejaLabel',
            style: const TextStyle(color: mutedColor, fontSize: 10),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.spa_outlined, color: primaryColor, size: 17),
              const SizedBox(width: 6),
              Text(
                '${item.jumlahTanaman} tanaman',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (item.user?.nama != null)
                Flexible(
                  child: Text(
                    'Oleh ${item.user!.nama}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: mutedColor, fontSize: 9),
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Edit budidaya',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: EdgeInsets.zero,
                onPressed: () => _openEditBudidaya(item),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: primaryColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 34),
      child: Center(child: CircularProgressIndicator(color: primaryColor)),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0D4CA)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFFAE4E3D),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8E4135), fontSize: 11),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _loadBudidaya(
              status: selectedStatus == 'semua' ? null : selectedStatus,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Coba lagi'),
            style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
      child: Column(
        children: [
          const Icon(Icons.spa_outlined, color: primaryColor, size: 34),
          const SizedBox(height: 9),
          const Text(
            'Belum ada data budidaya',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Data budidaya akan muncul di sini setelah tersimpan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            _budidayaController.loadMoreErrorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFAE4E3D), fontSize: 10),
          ),
          TextButton(
            onPressed: () => _budidayaController.loadMoreBudidayas(),
            child: const Text(
              'Muat lagi',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _budidayaController.loadMoreBudidayas(),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Muat lebih banyak'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kalender dan daftar panen dari API.
  // ---------------------------------------------------------------------------

  Widget _buildHarvestContent() {
    final panens = List<PanenModel>.from(_panensForSelectedMonth)
      ..sort((a, b) => a.tanggalPanen.compareTo(b.tanggalPanen));
    final totalLabel =
        _loadedPanenMonthKey == _calendarMonthKey(selectedCalendarMonth)
        ? '${_panenController.totalPanens} data'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHarvestCalendar(),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Jadwal panen',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              totalLabel,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                onPressed: _panenController.isLoading ? null : _openTambahPanen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB8C3AA),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text(
                  'Tambah',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_panenController.isLoading && panens.isEmpty)
          _buildPanenLoadingState()
        else if (_panenController.errorMessage != null && panens.isEmpty)
          _buildPanenErrorState(_panenController.errorMessage!)
        else if (panens.isEmpty)
          _buildPanenEmptyState()
        else ...[
          ...panens.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _openEditPanen(item),
                borderRadius: BorderRadius.circular(14),
                child: _buildPanenCard(item),
              ),
            ),
          ),
          if (_panenController.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          if (_panenController.loadMoreErrorMessage != null)
            _buildPanenLoadMoreError(),
          if (_panenController.hasMorePanens && !_panenController.isLoadingMore)
            _buildPanenLoadMoreButton(),
        ],
      ],
    );
  }

  Widget _buildHarvestCalendar() {
    final year = selectedCalendarMonth.year;
    final month = selectedCalendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingDays = firstDay.weekday - 1;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final monthlyPanens = _panensForSelectedMonth;
    final scheduledDays = monthlyPanens
        .where((item) => item.status == PanenModel.statusTerjadwal)
        .map((item) => item.tanggalPanen.day)
        .toSet();
    final completedDays = monthlyPanens
        .where((item) => item.status == PanenModel.statusSelesai)
        .map((item) => item.tanggalPanen.day)
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
                onPressed: _panenController.isLoading
                    ? null
                    : () => _changeCalendarMonth(-1),
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
                onPressed: _panenController.isLoading
                    ? null
                    : () => _changeCalendarMonth(1),
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
            children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: mutedColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 6 * 30,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 30,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final day = index - leadingDays + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(year, month, day);
                final isToday = date == todayOnly;

                return _buildCalendarDay(
                  day: day,
                  isToday: isToday,
                  hasScheduled: scheduledDays.contains(day),
                  hasCompleted: completedDays.contains(day),
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildCalendarLegend(
                color: Colors.white,
                borderColor: primaryColor,
                label: 'Hari ini',
              ),
              _buildCalendarLegend(color: primaryColor, label: 'Terjadwal'),
              _buildCalendarLegend(
                color: const Color(0xFFE9EFE0),
                label: 'Selesai',
              ),
            ],
          ),
          if (_panenController.isLoading && monthlyPanens.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: primaryColor,
                backgroundColor: softColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend({
    required Color color,
    Color? borderColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            border: borderColor == null ? null : Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: mutedColor, fontSize: 9)),
      ],
    );
  }

  Widget _buildCalendarDay({
    required int day,
    required bool isToday,
    required bool hasScheduled,
    required bool hasCompleted,
  }) {
    final isSelected = selectedCalendarDay == day;
    final backgroundColor = hasScheduled
        ? primaryColor
        : hasCompleted
        ? const Color(0xFFE9EFE0)
        : Colors.transparent;
    final foregroundColor = hasScheduled ? Colors.white : textColor;

    return Center(
      child: GestureDetector(
        onTap: () => setState(() => selectedCalendarDay = day),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: (isToday || isSelected) && !hasScheduled
                ? Border.all(color: primaryColor)
                : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$day',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: isToday || hasScheduled || hasCompleted || isSelected
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanenCard(PanenModel item) {
    final budidaya = item.budidaya;
    final isCompleted = item.status == PanenModel.statusSelesai;
    final panenDate = _dateOnly(item.tanggalPanen);
    final today = _dateOnly(DateTime.now());
    final remainingDays = panenDate.difference(today).inDays;
    final mejaLabel = budidaya?.meja == null
        ? 'Meja ${budidaya?.mejaId ?? '-'}'
        : 'Meja ${budidaya!.meja!.nomorMeja}';

    final statusLabel = isCompleted ? 'Selesai' : 'Terjadwal';
    final statusColor = isCompleted ? const Color(0xFF8A7047) : primaryColor;
    final statusBackground = isCompleted ? const Color(0xFFF3F0E8) : softColor;

    String timingLabel;
    if (isCompleted) {
      timingLabel = item.beratKg == null
          ? 'Berat belum tersedia'
          : '${item.beratKg!.toStringAsFixed(2)} kg';
    } else if (remainingDays == 0) {
      timingLabel = 'Hari ini';
    } else if (remainingDays > 0) {
      timingLabel = '$remainingDays hari lagi';
    } else {
      timingLabel = 'Terlambat ${remainingDays.abs()} hari';
    }

    final details = <String>[
      mejaLabel,
      'Budidaya #${item.budidayaId}',
      if (budidaya != null) '${budidaya.jumlahTanaman} tanaman',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 48,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.tanggalPanen.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatMonthShort(item.tanggalPanen.month),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Panen #${item.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  details.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: mutedColor, fontSize: 9),
                ),
                const SizedBox(height: 5),
                Text(
                  timingLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit_outlined, color: primaryColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildPanenLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 34),
      child: Center(child: CircularProgressIndicator(color: primaryColor)),
    );
  }

  Widget _buildPanenErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0D5CC)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFB35D48)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textColor, fontSize: 11),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _loadPanensForSelectedMonth(force: true),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildPanenEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available_outlined, color: primaryColor, size: 28),
          SizedBox(height: 8),
          Text(
            'Belum ada data panen pada bulan ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Jadwal panen dari backend akan muncul di kalender ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildPanenLoadMoreError() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Text(
            _panenController.loadMoreErrorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedColor, fontSize: 10),
          ),
          TextButton(
            onPressed: () => _panenController.loadMorePanens(),
            child: const Text(
              'Coba muat lagi',
              style: TextStyle(color: primaryColor, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanenLoadMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _panenController.loadMorePanens(),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Muat lebih banyak'),
      ),
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
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
