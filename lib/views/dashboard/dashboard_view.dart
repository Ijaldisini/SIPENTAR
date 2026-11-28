import 'package:flutter/material.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../controllers/dashboard/dashboard_controller.dart';
import '../../models/auth/user_model.dart';
import '../widgets/bottom_navigation.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color warningColor = Color(0xFF9A641B);
  static const Color warningBackground = Color(0xFFF8E7BD);

  late final AuthController _authController;
  late final DashboardController _dashboardController;

  bool _isRestoringSession = true;
  String? _sessionError;
  String? _currentRole;

  bool get _isOwner => _currentRole == 'pemilik';

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _dashboardController = DashboardController();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    if (mounted) {
      setState(() {
        _isRestoringSession = true;
        _sessionError = null;
      });
    }

    try {
      final status = await _authController.restoreSession();
      if (!mounted) return;

      final user = _authController.user;
      if (status != SessionRestoreStatus.authenticated || user == null) {
        setState(() {
          _sessionError =
              _authController.errorMessage ??
              'Sesi pengguna tidak ditemukan. Silakan login kembali.';
          _isRestoringSession = false;
        });
        return;
      }

      _currentRole = user.role.trim().toLowerCase();
      await _dashboardController.loadDashboard(role: _currentRole!);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sessionError = 'Gagal memuat sesi pengguna. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringSession = false;
        });
      }
    }
  }

  Future<void> _refreshDashboard() async {
    if (_currentRole == null) {
      await _initializeDashboard();
      return;
    }
    await _dashboardController.refreshDashboard();
  }

  @override
  void dispose() {
    _authController.dispose();
    _dashboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 112, child: _buildHeader(context)),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _refreshDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    child: Column(
                      children: [
                        _buildCultivationCard(),
                        const SizedBox(height: 10),
                        _buildFinanceStockCard(),
                        const SizedBox(height: 10),
                        _buildHealthCard(),
                        if (_isOwner) ...[
                          const SizedBox(height: 10),
                          _buildEmployeeCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lacak budidaya dan\nkesehatan selada.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pantau budidaya dan kesehatan tanaman.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Notifikasi akan diintegrasikan pada tahap berikutnya.',
                  ),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildCardFooter(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: primaryColor,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu Budidaya sudah menggunakan data dari DashboardController.
  /// Struktur dan styling kartu mengikuti screenshot Dashboard Full.
  Widget _buildCultivationCard() {
    return AnimatedBuilder(
      animation: _dashboardController,
      builder: (context, _) {
        final dashboard = _dashboardController.summary;
        final cultivation = dashboard?.budidaya;
        final mainCultivation = cultivation?.budidayaUtama;
        final isInitialLoading =
            (_isRestoringSession || _dashboardController.isLoading) &&
            dashboard == null;

        String subtitle;
        if (mainCultivation != null) {
          subtitle =
              cultivation?.labelBudidaya ?? 'Budidaya #${mainCultivation.id}';
        } else if (isInitialLoading) {
          subtitle = 'Memuat data budidaya...';
        } else if (_sessionError != null ||
            _dashboardController.errorMessage != null) {
          subtitle = 'Data budidaya belum dapat dimuat';
        } else {
          subtitle = 'Belum ada budidaya berjalan';
        }

        final hssValue = mainCultivation == null
            ? '—'
            : '${mainCultivation.hss} hari';

        final daysToHarvest = dashboard?.hariMenujuPanen;
        final harvestValue = daysToHarvest == null
            ? 'Belum dijadwalkan'
            : daysToHarvest == 0
            ? 'Hari ini'
            : '$daysToHarvest hari';

        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                title: 'Budidaya',
                subtitle: subtitle,
                icon: Icons.eco_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(label: 'HSS', value: hssValue),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _buildInfoBox(
                      label: 'Panen berikut',
                      value: harvestValue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_dashboardController.errorMessage != null &&
                  dashboard == null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _refreshDashboard,
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text(
                      'Coba muat ulang',
                      style: TextStyle(fontSize: 10, fontFamily: 'Inter'),
                    ),
                  ),
                ),
              ] else ...[
                _buildCardFooter(
                  'Lihat budidaya & rotasi',
                  onTap: () => Navigator.pushNamed(context, '/budidaya'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBox({required String label, required String value}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Keuangan & Stok menggunakan ringkasan dari endpoint modul terkait.
  ///
  /// Laporan API merupakan agregat bulan berjalan, bukan saldo kas kumulatif.
  /// Karena itu angka utama diberi label Laba bersih.
  Widget _buildFinanceStockCard() {
    return AnimatedBuilder(
      animation: _dashboardController,
      builder: (context, _) {
        final dashboard = _dashboardController.summary;
        final financial = dashboard?.keuangan?.laporan;
        final stock = dashboard?.stok;

        final isInitialLoading =
            (_isRestoringSession || _dashboardController.isLoading) &&
            dashboard == null;
        final hasError =
            _sessionError != null || _dashboardController.errorMessage != null;

        final totalStockTypes = stock?.totalJenisBarang ?? 0;
        final lowStockCount = stock?.totalStokHampirHabis ?? 0;
        final isStockSafe =
            stock != null && totalStockTypes > 0 && lowStockCount == 0;

        String stockStatus;
        if (stock != null) {
          if (totalStockTypes == 0) {
            stockStatus = 'Belum ada data stok';
          } else if (lowStockCount > 0) {
            stockStatus =
                '$lowStockCount dari $totalStockTypes stok di bawah batas minimum';
          } else {
            stockStatus = '$totalStockTypes jenis stok • aman';
          }
        } else if (isInitialLoading) {
          stockStatus = 'Memuat data stok...';
        } else if (hasError) {
          stockStatus = 'Data stok belum dapat dimuat';
        } else {
          stockStatus = 'Data stok belum tersedia';
        }

        final stockStatusColor = isStockSafe ? primaryColor : warningColor;
        final stockStatusBackground = isStockSafe
            ? const Color(0xFFEAF1E1)
            : warningBackground;
        final stockStatusIcon = isStockSafe
            ? Icons.check_circle_outline_rounded
            : Icons.warning_amber_rounded;

        final monthLabel = financial == null
            ? _currentMonthLabel()
            : _monthYearLabel(financial.tanggalMulai);

        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                title: _isOwner ? 'Keuangan & Stok' : 'Manajemen Stok',
                subtitle: _isOwner
                    ? 'Keuangan bulan ini & stok'
                    : 'Stok hari ini',
                icon: _isOwner
                    ? Icons.account_balance_wallet_outlined
                    : Icons.inventory_2_outlined,
              ),
              if (_isOwner) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laba bersih • $monthLabel',
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 9,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        financial == null
                            ? '—'
                            : _formatRupiah(financial.totalLabaBersih),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Divider(height: 14, color: Color(0xFFE6EBDD)),
                      Row(
                        children: [
                          Expanded(
                            child: _FinanceValue(
                              label: 'Pemasukan',
                              value: financial == null
                                  ? '—'
                                  : _formatRupiah(financial.totalPemasukan),
                              icon: Icons.arrow_downward_rounded,
                              iconColor: primaryColor,
                            ),
                          ),
                          Expanded(
                            child: _FinanceValue(
                              label: 'Pengeluaran',
                              value: financial == null
                                  ? '—'
                                  : _formatRupiah(financial.totalPengeluaran),
                              icon: Icons.arrow_upward_rounded,
                              iconColor: const Color(0xFFC65B49),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: stockStatusBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Icon(stockStatusIcon, color: stockStatusColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stockStatus,
                        style: TextStyle(
                          color: stockStatusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              _buildCardFooter(
                'Lihat detail keuangan & stok',
                onTap: () => Navigator.pushNamed(context, '/keuangan-stok'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Kartu Kesehatan menggunakan hasil GET /diagnosis untuk hari ini.
  /// Angka menyatakan jumlah record pemeriksaan, bukan jumlah daun/tanaman.
  Widget _buildHealthCard() {
    return AnimatedBuilder(
      animation: _dashboardController,
      builder: (context, _) {
        final dashboard = _dashboardController.summary;
        final health = dashboard?.kesehatan;
        final isInitialLoading =
            (_isRestoringSession || _dashboardController.isLoading) &&
            dashboard == null;
        final hasError =
            _sessionError != null || _dashboardController.errorMessage != null;

        String subtitle;
        String normalValue;
        String attentionValue;

        if (health != null) {
          subtitle = health.totalPemeriksaan == 0
              ? 'Belum ada pemeriksaan hari ini'
              : '${health.totalPemeriksaan} pemeriksaan hari ini';
          normalValue = '${health.totalNormal} pemeriksaan';
          attentionValue = '${health.totalPerluPantau} pemeriksaan';
        } else if (isInitialLoading) {
          subtitle = 'Memuat ringkasan diagnosis...';
          normalValue = 'Memuat...';
          attentionValue = 'Memuat...';
        } else if (hasError) {
          subtitle = 'Data diagnosis belum dapat dimuat';
          normalValue = '—';
          attentionValue = '—';
        } else {
          subtitle = 'Ringkasan diagnosis belum tersedia';
          normalValue = '—';
          attentionValue = '—';
        }

        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                title: 'Kesehatan selada',
                subtitle: subtitle,
                icon: Icons.monitor_heart_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HealthSummaryItem(
                      label: 'Normal',
                      value: normalValue,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _HealthSummaryItem(
                      label: 'Perlu pantau',
                      value: attentionValue,
                      warning: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              _buildCardFooter(
                'Lihat diagnosis AI',
                onTap: () => Navigator.pushNamed(context, '/kesehatan'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Kartu Karyawan membaca total dan tiga preview akun dari GET /karyawan.
  ///
  /// Endpoint ini hanya dipanggil untuk role pemilik oleh DashboardService.
  /// Tombol menuju halaman Akun & Karyawan yang sudah terdaftar di main.dart.
  Widget _buildEmployeeCard() {
    return AnimatedBuilder(
      animation: _dashboardController,
      builder: (context, _) {
        final dashboard = _dashboardController.summary;
        final employees = dashboard?.karyawan;
        final isInitialLoading =
            (_isRestoringSession || _dashboardController.isLoading) &&
            dashboard == null;
        final hasError =
            _sessionError != null || _dashboardController.errorMessage != null;

        final String subtitle;
        final String totalValue;

        if (employees != null) {
          subtitle = employees.totalKaryawan == 0
              ? 'Belum ada akun karyawan'
              : 'Jumlah karyawan tercatat';
          totalValue = employees.totalKaryawan.toString();
        } else if (isInitialLoading) {
          subtitle = 'Memuat data karyawan...';
          totalValue = '—';
        } else if (hasError) {
          subtitle = 'Data karyawan belum dapat dimuat';
          totalValue = '—';
        } else {
          subtitle = 'Data karyawan belum tersedia';
          totalValue = '—';
        }

        final employeePreview =
            employees?.karyawanPreview ?? const <UserModel>[];

        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                title: 'Karyawan',
                subtitle: subtitle,
                icon: Icons.person_add_alt_1_outlined,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Text(
                      totalValue,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'orang',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 10,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const Spacer(),
                    if (employeePreview.isNotEmpty)
                      _buildEmployeeAvatars(employeePreview)
                    else
                      const Icon(
                        Icons.groups_rounded,
                        color: primaryColor,
                        size: 35,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (hasError && employees == null)
                _buildCardFooter('Coba muat ulang', onTap: _refreshDashboard)
              else
                _buildCardFooter(
                  'Lihat akun karyawan',
                  onTap: () => Navigator.pushNamed(context, '/akun'),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Menampilkan maksimal tiga akun preview seperti susunan avatar pada desain.
  /// Nama tetap tersedia melalui tooltip tanpa menambah teks ke layout kartu.
  Widget _buildEmployeeAvatars(List<UserModel> employees) {
    final visibleEmployees = employees.take(3).toList(growable: false);
    if (visibleEmployees.isEmpty) {
      return const Icon(Icons.groups_rounded, color: primaryColor, size: 35);
    }

    const avatarColors = [
      Color(0xFFE2EBD6),
      Color(0xFFC9D9B5),
      Color(0xFF71894F),
    ];

    return SizedBox(
      width: 34.0 + ((visibleEmployees.length - 1) * 18.0),
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < visibleEmployees.length; index++)
            Positioned(
              left: index * 18.0,
              child: Tooltip(
                message: visibleEmployees[index].nama,
                child: Container(
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    backgroundColor: avatarColors[index % avatarColors.length],
                    child: Icon(
                      Icons.person_rounded,
                      color: index == 2 ? Colors.white : primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _currentMonthLabel() => _monthYearLabel(DateTime.now());

  String _monthYearLabel(DateTime date) {
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

  String _formatRupiah(num amount) {
    final roundedAmount = amount.round();
    final isNegative = roundedAmount < 0;
    final digits = roundedAmount.abs().toString();
    final formatted = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write('.');
      }
      formatted.write(digits[index]);
    }

    return '${isNegative ? '-' : ''}Rp ${formatted.toString()}';
  }
}

class _FinanceValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _FinanceValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 15),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF70786B),
                  fontSize: 8,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF26351F),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthSummaryItem extends StatelessWidget {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color warningColor = Color(0xFF9A641B);
  static const Color warningBackground = Color(0xFFF8E7BD);

  final String label;
  final String value;
  final bool warning;

  const _HealthSummaryItem({
    required this.label,
    required this.value,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning ? warningColor : primaryColor;
    final background = warning ? warningBackground : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: warning ? const Color(0xFFFFCC00) : primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: warning ? warningColor : textColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 10, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}
