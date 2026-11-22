import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color primaryColor = Color(0xFF6E8649);

  static const List<_NavigationItem> _items = [
    _NavigationItem(icon: Icons.home_outlined, label: 'Beranda'),
    _NavigationItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Keuangan',
    ),
    _NavigationItem(icon: Icons.calendar_month_outlined, label: 'Budidaya'),
    _NavigationItem(icon: Icons.favorite_border_rounded, label: 'Kesehatan'),
    _NavigationItem(icon: Icons.people_outline_rounded, label: 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEE3),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: List.generate(
          _items.length,
          (index) => Expanded(child: _buildNavigationItem(index)),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(int index) {
    final item = _items[index];
    final isSelected = currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 19, color: primaryColor),

              const SizedBox(height: 2),

              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF536348),
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Navigation item model khusus untuk komponen UI
class _NavigationItem {
  final IconData icon;
  final String label;

  const _NavigationItem({required this.icon, required this.label});
}
