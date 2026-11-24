import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const BottomNavigation({super.key, required this.currentIndex});

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color backgroundColor = Color(0xFFE9EEE3);
  static const Color darkColor = Color(0xFF26351F);

  static const List<_NavigationItem> _items = [
    _NavigationItem(
      label: 'Beranda',
      icon: Icons.home_outlined,
      route: '/dashboard',
    ),
    _NavigationItem(
      label: 'Keuangan',
      icon: Icons.account_balance_wallet_outlined,
      route: '/keuangan-stok',
    ),
    _NavigationItem(
      label: 'Budidaya',
      icon: Icons.calendar_month_outlined,
      route: '/budidaya',
    ),
    _NavigationItem(
      label: 'Kesehatan',
      icon: Icons.favorite_border_rounded,
      route: '/kesehatan',
    ),
    _NavigationItem(
      label: 'Akun',
      icon: Icons.person_outline_rounded,
      route: '/akun',
    ),
  ];

  void _navigateToPage(BuildContext context, int index) {
    if (index == currentIndex) return;

    Navigator.of(context)
        .pushNamedAndRemoveUntil(_items[index].route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isSelected = currentIndex == index;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () => _navigateToPage(context, index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.75)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: isSelected
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 0.5,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 21,
                            color: isSelected ? primaryColor : darkColor,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: isSelected ? primaryColor : darkColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavigationItem {
  final String label;
  final IconData icon;
  final String route;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
