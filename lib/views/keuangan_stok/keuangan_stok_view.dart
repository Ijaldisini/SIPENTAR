import 'package:flutter/material.dart';

import 'stock_form_view.dart';
import 'transaction_form_view.dart';
import 'kalkulasi_hpp_view.dart';
import 'pembagian_kas_view.dart';
import 'laporan_keuangan_view.dart';
import '../widgets/bottom_navigation.dart';

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

  // Filter stok
  int selectedStockFilter = 0;

  // Pencarian stok
  String stockSearchQuery = '';

  // Dummy data stok
  final List<Map<String, String>> stockItems = const [
    {
      'name': 'Nutrisi AB Mix',
      'category': 'Nutrisi',
      'minimum': 'Batas min. 5 liter',
      'quantity': '2 liter',
      'status': 'Menipis',
    },
    {
      'name': 'Rockwool',
      'category': 'Media tanam',
      'minimum': 'Batas min. 10 lembar',
      'quantity': '8 Lembar',
      'status': 'Menipis',
    },
    {
      'name': 'Benih selada',
      'category': 'Benih',
      'minimum': 'Batas min. 5 pak',
      'quantity': '12 Pak',
      'status': 'Aman',
    },
  ];

  // Data stok setelah pencarian dan filter
  List<Map<String, String>> get filteredStockItems {
    return stockItems.where((item) {
      final name = (item['name'] ?? '').toLowerCase();

      final matchesSearch = name.contains(stockSearchQuery.toLowerCase());

      final matchesFilter =
          selectedStockFilter == 0 ||
          item['status'] == (selectedStockFilter == 1 ? 'Menipis' : 'Aman');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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

          Positioned(
            left: 24,
            right: 24,
            bottom: 12 + bottomInset,
            child: BottomNavigation(
              currentIndex: 1,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                } else if (index != 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Halaman ini belum tersedia.'),
                    ),
                  );
                }
              },
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
        // Saldo kas
        _buildBalanceCard(),

        const SizedBox(height: 14),

        // Quick actions
        _buildQuickActions(context),

        const SizedBox(height: 14),

        // Peringatan stok
        _buildLowStockAlert(
          onTap: () {
            setState(() {
              selectedTab = 1;
              selectedStockFilter = 1;
            });
          },
        ),

        const SizedBox(height: 14),

        // Transaksi terbaru
        _buildRecentTransactions(),
      ],
    );
  }

  Widget _buildBalanceCard() {
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
          const Text(
            'Saldo kas • November 2026',
            style: TextStyle(
              color: Color(0xFF70786B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Rp7.200.000',
            style: TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          const Divider(color: Color(0xFFDFE5D7), height: 1),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildCashInfo(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: primaryColor,
                  label: 'Pemasukan',
                  amount: 'Rp12.000.000',
                ),
              ),

              Expanded(
                child: _buildCashInfo(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFAE4E3D),
                  label: 'Pengeluaran',
                  amount: 'Rp4.800.000',
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionFormView(
                    initialType: TransactionType.income,
                  ),
                ),
              );
            },
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

  // Low stock alert
  Widget _buildLowStockAlert({VoidCallback? onTap}) {
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

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saatnya isi ulang persediaan',
                      style: TextStyle(
                        color: Color(0xFF8C5B16),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '2 barang berada di bawah batas minimum.',
                      style: TextStyle(color: Color(0xFF8C5B16), fontSize: 11),
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

  // Recent transactions
  Widget _buildRecentTransactions() {
    return Column(
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

            Text(
              'Lihat semua',
              style: const TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        _buildTransactionItem(
          icon: Icons.arrow_downward_rounded,
          iconBackground: softColor,
          iconColor: primaryColor,
          title: 'Penjualan selada',
          date: '05 Nov 2026 • Pemasukan',
          amount: '+Rp1.200.000',
          amountColor: primaryColor,
          showDivider: true,
        ),

        _buildTransactionItem(
          icon: Icons.arrow_upward_rounded,
          iconBackground: const Color(0xFFFBF0EC),
          iconColor: const Color(0xFFAE4E3D),
          title: 'Nutrisi & perawatan',
          date: '04 Nov 2026 • Pengeluaran',
          amount: '−Rp450.000',
          amountColor: const Color(0xFFAE4E3D),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
    required bool showDivider,
  }) {
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
                child: Icon(icon, color: iconColor, size: 21),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      date,
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
                    amount,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showDivider) const Divider(color: Color(0xFFDFE5D7), height: 1),
      ],
    );
  }

  // =========================
  // STOCK CONTENT
  // =========================

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

        // Stock list
        if (filteredStockItems.isEmpty)
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
        else
          ...filteredStockItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildStockItem(context, item),
            ),
          ),

        const SizedBox(height: 2),

        // Add stock button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StockFormView()),
              );
            },
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

  // =========================
  // SEARCH STOCK
  // =========================

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

  // =========================
  // STOCK SUMMARY
  // =========================

  Widget _buildStockSummary() {
    final total = stockItems.length;
    final lowStock = stockItems
        .where((item) => item['status'] == 'Menipis')
        .length;
    final safeStock = stockItems
        .where((item) => item['status'] == 'Aman')
        .length;

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

  // =========================
  // STOCK FILTER
  // =========================

  Widget _buildStockFilters() {
    final total = stockItems.length;
    final lowStock = stockItems
        .where((item) => item['status'] == 'Menipis')
        .length;
    final safeStock = stockItems
        .where((item) => item['status'] == 'Aman')
        .length;

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

  // =========================
  // STOCK ITEM
  // =========================

  Widget _buildStockItem(BuildContext context, Map<String, String> item) {
    final isLowStock = item['status'] == 'Menipis';

    return Container(
      width: double.infinity,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDFE5D7), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Stock icon
          Container(
            width: 36,
            height: 36,
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

          // Stock information
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
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
                  '${item['category']} • ${item['minimum']}',
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

          // Stock quantity
          Text(
            item['quantity'] ?? '',
            style: TextStyle(
              color: isLowStock ? const Color(0xFF8C5B16) : primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 8),

          // Edit icon (UI only)
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StockFormView(isEdit: true, initialData: item),
                ),
              );
            },
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF70786B),
              size: 17,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCount({
    required String value,
    required String label,
    required Color color,
    required Color textValueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: textValueColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: const TextStyle(color: Color(0xFF70786B), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
