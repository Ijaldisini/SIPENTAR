import 'package:flutter/material.dart';

import '../../controllers/diagnosis/diagnosis_controller.dart';
import '../../models/diagnosis/diagnosis_model.dart';
import '../widgets/bottom_navigation.dart';
import 'kesehatan_riwayat_deteksi_view.dart';
import 'kesehatan_riwayat_detail_view.dart';
import 'kesehatan_unggah_foto_view.dart';

/// Dashboard Kesehatan dengan layout desain awal.
/// Sumber data ringkasan dan tiga pemeriksaan terbaru berasal dari API diagnosis.
class KesehatanView extends StatefulWidget {
  const KesehatanView({super.key});

  @override
  State<KesehatanView> createState() => _KesehatanViewState();
}

class _KesehatanViewState extends State<KesehatanView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softGreen = Color(0xFFF1F5E9);
  static const Color warningColor = Color(0xFF8C5B16);
  static const Color warningBackground = Color(0xFFFFF5DF);

  static const String lettuceImage =
      'https://images.unsplash.com/photo-1540420773420-3366772f4999'
      '?auto=format&fit=crop&w=500&q=80';

  final DiagnosisController _diagnosisController = DiagnosisController();
  bool _isLoadingOverview = false;
  bool _overviewComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDashboard();
    });
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (_isLoadingOverview) return;

    setState(() {
      _isLoadingOverview = true;
      _overviewComplete = false;
    });

    var complete = await _diagnosisController.loadDiagnoses(perPage: 50);

    // Dashboard menampilkan ringkasan dari seluruh data diagnosis yang dimuat.
    // Endpoint tidak menyediakan agregasi statistik, sehingga pagination dibaca
    // sampai selesai agar hitungan Sehat/Perhatian tidak hanya berdasarkan page 1.
    while (complete && _diagnosisController.hasMoreDiagnoses && mounted) {
      complete = await _diagnosisController.loadMoreDiagnoses();
    }

    if (!mounted) return;

    setState(() {
      _isLoadingOverview = false;
      _overviewComplete = complete && !_diagnosisController.hasMoreDiagnoses;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  int get _normalCount =>
      _diagnosisController.diagnoses.where((item) => item.isSehat).length;

  int get _attentionCount =>
      _diagnosisController.diagnoses.where((item) => !item.isSehat).length;

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

    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day ${months[date.month - 1]} ${date.year}, $hour.$minute';
  }

  String _budidayaTitle(DiagnosisModel diagnosis) {
    return 'Budidaya #${diagnosis.budidayaId}';
  }

  String _locationLabel(DiagnosisModel diagnosis) {
    final meja =
        diagnosis.budidaya?.meja?.nomorMeja ?? diagnosis.budidaya?.mejaId;
    return meja == null ? 'Budidaya #${diagnosis.budidayaId}' : 'Meja $meja';
  }

  void _openDetail(DiagnosisModel diagnosis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            KesehatanRiwayatDetailView(diagnosisId: diagnosis.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(color: primaryColor),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(
                  height: 112,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kesehatan selada',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Kenali kondisi tanaman, tangani lebih awal.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showMessage(
                            'Notifikasi kesehatan belum tersedia.',
                          ),
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _diagnosisController,
                      builder: (context, _) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeroCard(),
                              const SizedBox(height: 12),
                              _buildStartButton(context),
                              const SizedBox(height: 10),
                              _buildPhotoHint(),
                              const SizedBox(height: 14),
                              _buildSummary(),
                              const SizedBox(height: 18),
                              _buildHistoryHeader(context),
                              const SizedBox(height: 8),
                              if (_diagnosisController.errorMessage != null &&
                                  _diagnosisController.diagnoses.isEmpty)
                                _buildLoadError(),
                              if (_isLoadingOverview &&
                                  _diagnosisController.diagnoses.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ..._diagnosisController.diagnoses
                                  .take(3)
                                  .map(
                                    (item) => _buildHistoryItem(context, item),
                                  ),
                              if (!_isLoadingOverview &&
                                  _diagnosisController.errorMessage == null &&
                                  _diagnosisController.diagnoses.isEmpty)
                                _buildEmptyHistory(),
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
        ],
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Periksa daun,\njaga hasil panen.',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 19,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Text(
                    'Foto daun dan batang untuk pemeriksaan visual tanaman.',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      height: 1.4,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 126,
            height: double.infinity,
            child: Image.network(
              lettuceImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFDCE8CF),
                  child: const Icon(
                    Icons.eco_outlined,
                    size: 48,
                    color: primaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KesehatanUnggahFotoView(),
            ),
          ).then((_) {
            if (mounted) _loadDashboard();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Mulai Deteksi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoHint() {
    return const Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: primaryColor),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'Siapkan foto daun dan batang dari tanaman yang sama.',
            style: TextStyle(
              color: mutedColor,
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final total = _diagnosisController.totalDiagnoses.toString();
    final normal = _overviewComplete ? _normalCount.toString() : '—';
    final attention = _overviewComplete ? _attentionCount.toString() : '—';

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            value: _isLoadingOverview && _diagnosisController.diagnoses.isEmpty
                ? '—'
                : total,
            label: 'Pemeriksaan',
            backgroundColor: softGreen,
            valueColor: textColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            value: normal,
            label: 'Normal',
            backgroundColor: softGreen,
            valueColor: textColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            value: attention,
            label: 'Perlu perhatian',
            backgroundColor: warningBackground,
            valueColor: warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String value,
    required String label,
    required Color backgroundColor,
    required Color valueColor,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor == textColor ? mutedColor : valueColor,
              fontSize: 9,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Pemeriksaan terakhir',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const KesehatanRiwayatDeteksiView(),
              ),
            );
          },
          child: const Text(
            'Semua Riwayat',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, DiagnosisModel item) {
    final needsAttention = !item.isSehat;
    final statusColor = needsAttention ? warningColor : primaryColor;
    final title = _budidayaTitle(item);
    final location = _locationLabel(item);

    return InkWell(
      onTap: () => _openDetail(item),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                item.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 48,
                    height: 48,
                    color: softGreen,
                    child: const Icon(Icons.eco_outlined, color: primaryColor),
                  );
                },
              ),
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
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(item.tanggalDiagnosis),
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    needsAttention ? 'Perlu perhatian' : 'Normal',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
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

  Widget _buildLoadError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _diagnosisController.errorMessage ??
                'Gagal memuat pemeriksaan kesehatan.',
            style: const TextStyle(
              color: textColor,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isLoadingOverview ? null : _loadDashboard,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba lagi'),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Belum ada pemeriksaan tersimpan.',
          style: TextStyle(
            color: mutedColor,
            fontSize: 11,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
