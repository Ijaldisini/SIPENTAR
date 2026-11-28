import 'package:flutter/material.dart';

import 'stock_form_view.dart';
import 'transaction_form_view.dart';
import 'kalkulasi_hpp_view.dart';
import 'pembagian_kas_view.dart';
import 'laporan_keuangan_view.dart';
import '../widgets/bottom_navigation.dart';
import '../../controllers/stok/stok_controller.dart';
import '../../models/stok/stok_model.dart';
import '../../controllers/transaksi_keuangan/transaksi_keuangan_controller.dart';
import '../../models/transaksi_keuangan/transaksi_keuangan_model.dart';

class KeuanganStokView extends StatefulWidget {
  const KeuanganStokView({super.key});

  @override
  State<KeuanganStokView> createState() => _KeuanganStokViewState();
}

class _KeuanganStokViewState extends State<KeuanganStokView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);

  int selectedTab = 0;

  int selectedStockFilter = 0;

  String stockSearchQuery = '';

  // Stok Controller
  late final StokController _stokController;
  late final TransaksiKeuanganController _transaksiController;

  bool _hasRequestedStocks = false;
  bool _hasRequestedTransactions = false;
  bool _hasRequestedFinancialReport = false;

  // Menandai item yang sedang diproses penghapusannya.
  final Set<int> _deletingStockIds = <int>{};

  // Data stok berdasarkan pencarian dan filter
  List<StokModel> get filteredStockItems {
    return _stokController.stoks.where((item) {
      final matchesSearch = item.namaBahan.toLowerCase().contains(
        stockSearchQuery.toLowerCase().trim(),
      );

      final matchesFilter =
          selectedStockFilter == 0 ||
          (selectedStockFilter == 1 && item.isLow) ||
          (selectedStockFilter == 2 && !item.isLow);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _stokController = StokController();
    _stokController.addListener(_onStokControllerChanged);

    _transaksiController = TransaksiKeuanganController();
    _transaksiController.addListener(_onTransaksiControllerChanged);

    // Ambil data stok dan transaksi ketika halaman dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoks();
      _loadTransaksiKeuangan();
      _loadLaporanKeuangan();
    });
  }

  // Mendengarkan perubahan Controller
  void _onStokControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTransaksiControllerChanged() {
    if (mounted) setState(() {});
  }

  // Memuat daftar transaksi terbaru.
  Future<void> _loadTransaksiKeuangan({bool refresh = false}) async {
    if (_transaksiController.isLoading) return;
    if (_hasRequestedTransactions && !refresh) return;

    _hasRequestedTransactions = true;
    final success = await _transaksiController.loadTransaksiKeuangan(
      perPage: 5,
    );

    if (!mounted) return;
    if (!success) _hasRequestedTransactions = false;
  }

  Future<void> _loadMoreTransaksiKeuangan() async {
    await _transaksiController.loadMoreTransaksiKeuangan();
  }

  Future<void> _loadLaporanKeuangan({bool refresh = false}) async {
    if (_transaksiController.isReportLoading) return;
    if (_hasRequestedFinancialReport && !refresh) return;

    _hasRequestedFinancialReport = true;

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0);

    final success = await _transaksiController.loadLaporanKeuangan(
      from: from,
      to: to,
    );

    if (!mounted) return;
    if (!success) _hasRequestedFinancialReport = false;
  }

  Future<void> _openTransactionForm({
    TransactionType initialType = TransactionType.income,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormView(
          initialType: initialType,
          controller: _transaksiController,
        ),
      ),
    );

    if (!mounted || saved != true) return;

    _hasRequestedTransactions = false;
    await _loadTransaksiKeuangan(refresh: true);
    await _loadLaporanKeuangan(refresh: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan.')),
      );
  }

  // Memuat daftar stok
  Future<void> _loadStoks({bool refresh = false}) async {
    if (_stokController.isLoading) return;

    if (_hasRequestedStocks && !refresh) return;

    _hasRequestedStocks = true;

    await _stokController.loadStoks();

    if (!mounted) return;

    // Izinkan pengguna mencoba kembali jika gagal
    if (_stokController.errorMessage != null) {
      _hasRequestedStocks = false;
    }
  }

  @override
  void dispose() {
    _stokController.removeListener(_onStokControllerChanged);
    _stokController.dispose();

    _transaksiController.removeListener(_onTransaksiControllerChanged);
    _transaksiController.dispose();

    super.dispose();
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
                child: Column(
                  children: [
                    _buildTabSelector(),

                    const SizedBox(height: 16),

                    if (selectedTab == 0) ...[
                      _buildFinanceContent(),
                    ] else ...[
                      _buildStockContent(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: primaryColor,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 24,
        24,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keuangan & Stok',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                Text(
                  'Kelola usaha, tumbuh bersama.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
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
                size: 25,
              ),
              Positioned(
                top: 0,
                right: -1,
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
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton(title: 'Keuangan', index: 0),
          _buildTabButton(title: 'Stok', index: 1),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });

          if (index == 1) {
            _loadStoks();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF70776B),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceContent() {
    return Column(
      children: [
        _buildBalanceCard(),

        const SizedBox(height: 14),

        _buildQuickActions(context),

        const SizedBox(height: 14),

        _buildLowStockAlert(
          onTap: () {
            setState(() {
              selectedTab = 1;
              selectedStockFilter = 1;
            });
            _loadStoks();
          },
        ),

        const SizedBox(height: 14),

        _buildRecentTransactions(),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final report = _transaksiController.laporanKeuangan;
    final now = DateTime.now();
    final monthLabel = '${_getMonthName(now.month)} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ringkasan kas • $monthLabel',
                  style: const TextStyle(
                    color: Color(0xFF70786B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_transaksiController.isReportLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            report == null ? '—' : _formatRupiah(report.selisih),
            style: const TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Selisih pemasukan dikurangi pengeluaran pada periode ini',
            style: TextStyle(
              color: Color(0xFF70786B),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 10),
          const Divider(color: Color(0xFFDFE5D7), height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildCashInfo(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: primaryColor,
                  label: 'Pemasukan',
                  amount: report == null
                      ? '—'
                      : _formatRupiah(report.totalPemasukan),
                ),
              ),
              Expanded(
                child: _buildCashInfo(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFAE4E3D),
                  label: 'Pengeluaran',
                  amount: report == null
                      ? '—'
                      : _formatRupiah(report.totalPengeluaran),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildCashInfo(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: primaryColor,
                  label: 'Kas operasional',
                  amount: report == null
                      ? '—'
                      : _formatRupiah(report.totalKasOperasional),
                ),
              ),
              Expanded(
                child: _buildCashInfo(
                  icon: Icons.trending_up_rounded,
                  iconColor: primaryColor,
                  label: 'Laba bersih',
                  amount: report == null
                      ? '—'
                      : _formatRupiah(report.totalLabaBersih),
                ),
              ),
            ],
          ),

          if (_transaksiController.reportErrorMessage != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _transaksiController.reportErrorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFAE4E3D),
                      fontSize: 11,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _transaksiController.isReportLoading
                      ? null
                      : () => _loadLaporanKeuangan(refresh: true),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ],
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

  String _getMonthName(int month) {
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

  Widget _buildCashInfo({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 21),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF70786B), fontSize: 11),
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionItem(
            icon: Icons.add_rounded,
            label: 'Catat kas',
            onTap: () => _openTransactionForm(
              initialType: TransactionType.income,
            ),
          ),
        ),
        Expanded(
          child: _buildActionItem(
            icon: Icons.calculate_outlined,
            label: 'HPP',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KalkulasiHppView(),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _buildActionItem(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Bagi kas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PembagianKasView(),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _buildActionItem(
            icon: Icons.chevron_right_rounded,
            label: 'Laporan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LaporanKeuanganView(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: primaryColor, size: 23),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert({VoidCallback? onTap}) {
    final lowStockCount = _stokController.stoks
        .where((item) => item.isLow)
        .length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5DF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF8C5B16),
                size: 27,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saatnya isi ulang persediaan',
                      style: TextStyle(
                        color: Color(0xFF8C5B16),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$lowStockCount barang pada data yang dimuat berada di bawah batas minimum.',
                      style: const TextStyle(
                        color: Color(0xFF8C5B16),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8C5B16),
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = _transaksiController.transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi terbaru',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_transaksiController.hasMoreTransactions)
              TextButton(
                onPressed: _transaksiController.isLoadingMore
                    ? null
                    : _loadMoreTransaksiKeuangan,
                child: const Text(
                  'Lihat semua',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_transaksiController.isLoading && transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_transaksiController.errorMessage != null &&
            transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  _transaksiController.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF70786B),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _hasRequestedTransactions = false;
                    _loadTransaksiKeuangan(refresh: true);
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          )
        else if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                'Belum ada transaksi keuangan.',
                style: TextStyle(
                  color: Color(0xFF70786B),
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          ...transactions.asMap().entries.map((entry) {
            final isLast = entry.key == transactions.length - 1;
            return _buildTransactionItem(
              item: entry.value,
              showDivider: !isLast,
            );
          }),
        if (_transaksiController.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(10),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        if (_transaksiController.loadMoreErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _transaksiController.loadMoreErrorMessage!,
              style: const TextStyle(
                color: Color(0xFFAE4E3D),
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required TransaksiKeuanganModel item,
    required bool showDivider,
  }) {
    final isIncome = item.isPemasukan;
    final iconColor = isIncome ? primaryColor : const Color(0xFFAE4E3D);
    final iconBackground = isIncome
        ? softColor
        : const Color(0xFFFBF0EC);
    final title = item.keterangan?.trim().isNotEmpty == true
        ? item.keterangan!.trim()
        : (isIncome ? 'Pemasukan' : 'Pengeluaran');
    final amountPrefix = isIncome ? '+' : '−';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTransactionDate(item.tanggal)} • '
                      '${isIncome ? 'Pemasukan' : 'Pengeluaran'}',
                      style: const TextStyle(
                        color: Color(0xFF70786B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$amountPrefix${_formatRupiah(item.jumlah)}',
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(color: Color(0xFFDFE5D7), height: 1),
      ],
    );
  }

  String _formatTransactionDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _openStockForm({StokModel? stok}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StockFormView(
          stokController: _stokController,
          stok: stok,
        ),
      ),
    );

    if (!mounted || saved != true) return;

    // Ambil ulang halaman pertama agar daftar dan ringkasan sesuai server.
    _hasRequestedStocks = false;
    await _loadStoks(refresh: true);
  }

  Future<void> _confirmDeleteStock(StokModel stok) async {
    if (_deletingStockIds.contains(stok.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus stok?'),
          content: Text(
            'Stok "${stok.namaBahan}" akan dihapus. '
            'Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFAE4E3D),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingStockIds.add(stok.id);
    });

    String? deletionError;

    try {
      _stokController.clearError();
      await _stokController.deleteStok(id: stok.id);
      deletionError = _stokController.submitErrorMessage;
    } catch (error) {
      deletionError = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _deletingStockIds.remove(stok.id);
        });
      }
    }

    if (!mounted) return;

    if (deletionError != null && deletionError.trim().isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(deletionError),
            backgroundColor: const Color(0xFFAE4E3D),
          ),
        );
      return;
    }

    // Muat ulang agar jumlah stok dan pagination sesuai data server.
    _hasRequestedStocks = false;
    await _loadStoks(refresh: true);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Stok berhasil dihapus.')),
      );
  }

  Widget _buildStockContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        _buildStockSearchField(),

        const SizedBox(height: 12),

        // Stock warning
        _buildLowStockAlert(),

        const SizedBox(height: 10),

        // Stock summary
        _buildStockSummary(),

        const SizedBox(height: 10),

        // Stock filters
        _buildStockFilters(),

        const SizedBox(height: 12),

        // Loading state
        if (_stokController.isLoading && _stokController.stoks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 2,
              ),
            ),
          )
        // Error state
        else if (_stokController.errorMessage != null &&
            _stokController.stoks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFF70786B),
                  size: 32,
                ),

                const SizedBox(height: 8),

                Text(
                  _stokController.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF70786B),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: () {
                    _loadStoks(refresh: true);
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          )
        // Empty state
        else if (filteredStockItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: const Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF6E8649),
                  size: 32,
                ),

                SizedBox(height: 8),

                Text(
                  'Stok tidak ditemukan',
                  style: TextStyle(color: Color(0xFF70786B), fontSize: 13),
                ),
              ],
            ),
          )
        // Stock list
        else
          ...filteredStockItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildStockItem(context, item),
            ),
          ),

        // Loading next page
        if (_stokController.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 2,
            ),
          )
        // Load more
        else if (_stokController.hasMoreStoks)
          Center(
            child: TextButton(
              onPressed: () {
                _stokController.loadMoreStoks();
              },
              child: const Text(
                'Muat stok lainnya',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        const SizedBox(height: 2),

        // Add stock button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _openStockForm(),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              'Tambah stok',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
      ],
    );
  }

  Widget _buildStockSearchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF70786B), size: 21),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  stockSearchQuery = value;
                });
              },
              style: const TextStyle(color: textColor, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Cari nama stok...',
                hintStyle: TextStyle(color: Color(0xFF70786B), fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummary() {
    final stocks = _stokController.stoks;

    final total = stocks.length;

    final lowStock = stocks.where((item) => item.isLow).length;

    final safeStock = stocks.where((item) => !item.isLow).length;

    return Row(
      children: [
        Expanded(
          child: _buildStockSummaryItem(
            value: total.toString(),
            label: 'Jenis barang',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildStockSummaryItem(
            value: lowStock.toString(),
            label: 'Stok menipis',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildStockSummaryItem(
            value: safeStock.toString(),
            label: 'Stok aman',
          ),
        ),
      ],
    );
  }

  Widget _buildStockSummaryItem({
    required String value,
    required String label,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: textColor,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF70786B), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStockFilters() {
    final stocks = _stokController.stoks;

    final total = stocks.length;

    final lowStock = stocks.where((item) => item.isLow).length;

    final safeStock = stocks.where((item) => !item.isLow).length;

    return Row(
      children: [
        Expanded(
          child: _buildStockFilterButton(index: 0, label: 'Semua ($total)'),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _buildStockFilterButton(
            index: 1,
            label: 'Menipis ($lowStock)',
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _buildStockFilterButton(index: 2, label: 'Aman ($safeStock)'),
        ),
      ],
    );
  }

  Widget _buildStockFilterButton({required int index, required String label}) {
    final isSelected = selectedStockFilter == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStockFilter = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : index == 2
              ? const Color(0xFFF6F8F3)
              : softColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6E8649),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStockItem(BuildContext context, StokModel item) {
    final isLowStock = item.isLow;

    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDFE5D7), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: primaryColor,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaBahan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '${item.kategori} • Batas min. '
                  '${_formatStockNumber(item.batasMinimum)} '
                  '${item.satuan}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF70786B),
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${_formatStockNumber(item.jumlahStok)} ${item.satuan}',
                style: TextStyle(
                  color: isLowStock ? const Color(0xFF8C5B16) : primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          IconButton(
            tooltip: 'Edit stok',
            onPressed: () => _openStockForm(stok: item),
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF70786B),
              size: 17,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
          ),

          SizedBox(
            width: 28,
            height: 36,
            child: _deletingStockIds.contains(item.id)
                ? const Padding(
                    padding: EdgeInsets.all(7),
                    child: CircularProgressIndicator(
                      color: Color(0xFFAE4E3D),
                      strokeWidth: 2,
                    ),
                  )
                : IconButton(
                    tooltip: 'Hapus stok',
                    onPressed: () => _confirmDeleteStock(item),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFAE4E3D),
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 36,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Format angka agar tidak menampilkan angka desimal
  // yang tidak diperlukan.
  String _formatStockNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
