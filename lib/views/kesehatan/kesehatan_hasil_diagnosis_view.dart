import 'package:flutter/material.dart';

import '../../models/diagnosis/diagnosis_model.dart';

/// Halaman hasil diagnosis yang seluruh nilainya berasal dari response Laravel.
/// Tidak membuat status, confidence, atau rekomendasi lokal/dummy.
class KesehatanHasilDiagnosisView extends StatelessWidget {
  final DiagnosisModel diagnosis;

  const KesehatanHasilDiagnosisView({super.key, required this.diagnosis});

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softGreen = Color(0xFFF1F5E9);
  static const Color warningColor = Color(0xFF8C5B16);
  static const Color warningBackground = Color(0xFFFFF5DF);
  static const Color borderColor = Color(0xFFDFE5D7);

  bool get _isHealthy => diagnosis.isSehat;

  Color get _statusColor => _isHealthy ? primaryColor : warningColor;

  Color get _statusBackground => _isHealthy ? softGreen : warningBackground;

  IconData get _statusIcon {
    switch (diagnosis.hasil) {
      case DiagnosisModel.hasilSehat:
        return Icons.check_circle_rounded;
      case DiagnosisModel.hasilBusukBatang:
        return Icons.warning_amber_rounded;
      case DiagnosisModel.hasilCacarDaun:
        return Icons.eco_outlined;
      case DiagnosisModel.hasilBusukAkar:
        return Icons.water_drop_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
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
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hasil diagnosis',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildImageCard(),
                      const SizedBox(height: 16),
                      _buildConfidenceCard(),
                      const SizedBox(height: 18),
                      _buildRecommendationCard(),
                      if (diagnosis.budidaya != null) ...[
                        const SizedBox(height: 16),
                        _buildBudidayaCard(),
                      ],
                      const SizedBox(height: 16),
                      _buildMetadataCard(),
                      const SizedBox(height: 12),
                      _buildDisclaimerCard(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HASIL KLASIFIKASI',
            style: TextStyle(
              color: _statusColor,
              fontSize: 10,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(_statusIcon, color: _statusColor, size: 27),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  diagnosis.hasilLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _isHealthy
                ? 'Backend mengklasifikasikan tanaman pada kategori sehat.'
                : 'Backend mendeteksi kategori yang perlu diperhatikan.',
            style: TextStyle(
              color: _statusColor,
              fontSize: 11,
              height: 1.4,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(17),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 225,
            child: Image.network(
              diagnosis.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: softGreen,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 42,
                        color: primaryColor,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Foto tidak dapat dimuat',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, size: 17, color: primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Foto yang diperiksa',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Text(
                  'ID #${diagnosis.id}',
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 10,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard() {
    final confidence = diagnosis.confidence.clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Confidence',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Text(
                '${confidence.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: confidence / 100,
              minHeight: 9,
              backgroundColor: const Color(0xFFE3E9DA),
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Nilai confidence ditampilkan sesuai response backend dalam skala 0–100%.',
            style: TextStyle(
              color: mutedColor,
              fontSize: 10,
              height: 1.4,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: primaryColor, size: 19),
              SizedBox(width: 8),
              Text(
                'Rekomendasi penanganan',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            diagnosis.rekomendasi.trim().isEmpty
                ? 'Belum ada rekomendasi dari backend untuk hasil ini.'
                : diagnosis.rekomendasi,
            style: const TextStyle(
              color: textColor,
              fontSize: 12,
              height: 1.55,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudidayaCard() {
    final budidaya = diagnosis.budidaya!;
    final mejaNumber = budidaya.meja?.nomorMeja;
    final mejaLabel = mejaNumber == null
        ? 'Meja ID ${budidaya.mejaId}'
        : 'Meja $mejaNumber';

    return _buildInformationCard(
      title: 'Informasi budidaya',
      icon: Icons.spa_outlined,
      children: [
        _buildInfoRow('Budidaya', '#${budidaya.id}'),
        _buildInfoRow('Lokasi', mejaLabel),
        _buildInfoRow('Jumlah tanaman', '${budidaya.jumlahTanaman} tanaman'),
        _buildInfoRow('Tanggal semai', _formatDate(budidaya.tanggalSemai)),
        _buildInfoRow('Umur tanaman', '${budidaya.hss} HSS'),
      ],
    );
  }

  Widget _buildMetadataCard() {
    final userName = diagnosis.user?.nama;

    return _buildInformationCard(
      title: 'Informasi pemeriksaan',
      icon: Icons.assignment_outlined,
      children: [
        _buildInfoRow(
          'Tanggal diagnosis',
          _formatDateTime(diagnosis.tanggalDiagnosis),
        ),
        if (userName != null && userName.trim().isNotEmpty)
          _buildInfoRow('Pemeriksa', userName),
        _buildInfoRow('ID budidaya', '#${diagnosis.budidayaId}'),
      ],
    );
  }

  Widget _buildInformationCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: mutedColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              diagnosis.disclaimer,
              style: const TextStyle(
                color: mutedColor,
                fontSize: 10,
                height: 1.45,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
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

    return '${value.day.toString().padLeft(2, '0')} '
        '${months[value.month - 1]} ${value.year}';
  }

  String _formatDateTime(DateTime value) {
    final date = _formatDate(value);
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$date, $hour:$minute';
  }
}
