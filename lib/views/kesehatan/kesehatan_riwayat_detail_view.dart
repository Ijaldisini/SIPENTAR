import 'package:flutter/material.dart';

import '../../controllers/diagnosis/diagnosis_controller.dart';
import '../../models/diagnosis/diagnosis_model.dart';

/// Detail satu record riwayat diagnosis. Satu record backend menyimpan satu foto.
class KesehatanRiwayatDetailView extends StatefulWidget {
  final int diagnosisId;

  const KesehatanRiwayatDetailView({super.key, required this.diagnosisId});

  @override
  State<KesehatanRiwayatDetailView> createState() =>
      _KesehatanRiwayatDetailViewState();
}

class _KesehatanRiwayatDetailViewState
    extends State<KesehatanRiwayatDetailView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softGreen = Color(0xFFF1F5E9);
  static const Color warningColor = Color(0xFF8C5B16);
  static const Color warningBackground = Color(0xFFFFF5DF);
  static const Color borderColor = Color(0xFFDFE5D7);

  final DiagnosisController _controller = DiagnosisController();

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    await _controller.loadDiagnosisDetail(id: widget.diagnosisId);
  }

  String _formatDate(DateTime date) {
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
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}, $hour.$minute';
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
                    'Detail diagnosis',
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
                  animation: _controller,
                  builder: (context, _) {
                    if (_controller.isDetailLoading &&
                        _controller.selectedDiagnosis == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    }

                    if (_controller.detailErrorMessage != null ||
                        _controller.selectedDiagnosis == null) {
                      return _buildErrorState();
                    }

                    return _buildContent(_controller.selectedDiagnosis!);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(DiagnosisModel diagnosis) {
    final isHealthy = diagnosis.isSehat;
    final statusColor = isHealthy ? primaryColor : warningColor;
    final statusBackground = isHealthy ? softGreen : warningBackground;
    final budidaya = diagnosis.budidaya;
    final meja = budidaya?.meja?.nomorMeja ?? budidaya?.mejaId;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.45,
              child: Image.network(
                diagnosis.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: softGreen,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.eco_outlined,
                      color: primaryColor,
                      size: 52,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hasil diagnosis #${diagnosis.id}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isHealthy
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: statusColor,
                      size: 25,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        diagnosis.hasilLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Confidence ${diagnosis.confidence.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Rekomendasi',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            diagnosis.rekomendasi,
            style: const TextStyle(
              color: mutedColor,
              fontSize: 12,
              height: 1.5,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          _buildInformationCard(
            title: 'Informasi pemeriksaan',
            rows: [
              ('Tanggal', _formatDate(diagnosis.tanggalDiagnosis)),
              ('ID budidaya', diagnosis.budidayaId.toString()),
              ('Meja', meja == null ? 'Tidak tersedia' : 'Meja $meja'),
              (
                'Jumlah tanaman',
                budidaya == null
                    ? 'Tidak tersedia'
                    : '${budidaya.jumlahTanaman} tanaman',
              ),
              (
                'Umur tanaman',
                budidaya == null ? 'Tidak tersedia' : '${budidaya.hss} HSS',
              ),
              ('Pemeriksa', diagnosis.user?.nama ?? 'Tidak tersedia'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8F4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 19, color: mutedColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    diagnosis.disclaimer,
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 11,
                      height: 1.4,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard({
    required String title,
    required List<(String, String)> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        color: mutedColor,
                        fontSize: 11,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const Text(': ', style: TextStyle(color: mutedColor)),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: mutedColor),
            const SizedBox(height: 12),
            const Text(
              'Detail diagnosis tidak dapat dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _controller.detailErrorMessage ??
                  'Data diagnosis tidak ditemukan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba lagi'),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
