import 'package:flutter/material.dart';

import '../widgets/bottom_navigation.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // Header dashboard
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: _buildHeader(context),
          ),

          // White content panel with scroll
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: Column(
                  children: [
                    _buildCultivationCard(),

                    const SizedBox(height: 12),

                    _buildFinanceCard(),

                    const SizedBox(height: 12),

                    _buildStockCard(),

                    const SizedBox(height: 12),

                    _buildHealthCard(),
                  ],
                ),
              ),
            ),
          ),

          // Fixed bottom navigation
          Positioned(
            left: 24,
            right: 24,
            bottom: 12 + bottomInset,
            child: BottomNavigation(
              currentIndex: 0,
              onTap: (index) {
                if (index == 1) {
                  Navigator.pushReplacementNamed(context, '/keuangan-stok');
                } else if (index != 0) {
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

  // Dashboard header
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: primaryColor,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 12,
        24,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lacak budidaya dan\nkesehatan selada.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Pantau budidaya dan kesehatan tanaman.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Notification icon
          Stack(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),

              Positioned(
                top: 2,
                right: 2,
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

  // Reusable dashboard card container
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  // Reusable card header
  Widget _buildCardHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ],
    );
  }

  // Reusable card footer
  Widget _buildCardFooter(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Icon(Icons.arrow_forward_rounded, color: primaryColor, size: 16),
      ],
    );
  }

  // Cultivation card
  Widget _buildCultivationCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: 'Budidaya',
            subtitle: 'Batch 04 • 12 lubang tanam',
            icon: Icons.eco_outlined,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoBox(label: 'HSS', value: '18 hari'),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildInfoBox(label: 'Panen berikut', value: '4 hari'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildCardFooter('Lihat budidaya & rotasi'),
        ],
      ),
    );
  }

  // Reusable information box
  Widget _buildInfoBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(
              color: textColor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Finance card
  Widget _buildFinanceCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: 'Keuangan',
            subtitle: 'Saldo kas • November 2026',
            icon: Icons.account_balance_wallet_outlined,
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo kas saat ini',
                  style: TextStyle(color: Color(0xFF70786B), fontSize: 12),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Rp7.200.000',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildCardFooter('Lihat detail keuangan'),
        ],
      ),
    );
  }

  // Stock management card
  Widget _buildStockCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: 'Manajemen Stok',
            subtitle: 'Jumlah stok hari ini',
            icon: Icons.inventory_2_outlined,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStockInfo(
                  value: '3',
                  label: 'Jenis barang',
                  color: const Color(0xFFFFFFFF),
                  valueColor: textColor,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildStockInfo(
                  value: '2',
                  label: 'Stok menipis',
                  color: const Color(0xFFF2D9D6),
                  valueColor: const Color(0xFFAE4E3D),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildStockInfo(
                  value: '1',
                  label: 'Stok aman',
                  color: const Color(0xFFDCE9C2),
                  valueColor: const Color(0xFF526C36),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildCardFooter('Lihat detail stok'),
        ],
      ),
    );
  }

  // Reusable stock information
  Widget _buildStockInfo({
    required String value,
    required String label,
    required Color color,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            maxLines: 2,
            style: const TextStyle(
              color: Color(0xFF70786B),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Lettuce health card
  Widget _buildHealthCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: 'Kesehatan selada',
            subtitle: '3 hasil diagnosis hari ini',
            icon: Icons.health_and_safety_outlined,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildHealthInfo(
                  label: 'Normal',
                  value: '2 daun',
                  dotColor: primaryColor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildHealthInfo(
                  label: 'Perlu pantau',
                  value: '1 daun',
                  dotColor: const Color(0xFFFFCC00),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildCardFooter('Lihat diagnosis AI'),
        ],
      ),
    );
  }

  // Reusable health information
  Widget _buildHealthInfo({
    required String label,
    required String value,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(color: primaryColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
