import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/diagnosis/diagnosis_model.dart';

/// Halaman hasil dengan susunan visual lama (dua kartu foto, temuan,
/// informasi budidaya, catatan, disclaimer), tetapi data hasil berasal dari API.
class KesehatanHasilDeteksiView extends StatelessWidget {
  final File? daunFoto;
  final File? batangFoto;
  final DiagnosisModel? daunDiagnosis;
  final DiagnosisModel? batangDiagnosis;
  final String? status;
  final String batchName;
  final String catatanGejala;

  const KesehatanHasilDeteksiView({
    super.key,
    this.daunFoto,
    this.batangFoto,
    this.daunDiagnosis,
    this.batangDiagnosis,
    required this.batchName,
    required this.catatanGejala,
    this.status,
  });

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softGreen = Color(0xFFF1F5E9);
  static const Color warningColor = Color(0xFF8C5B16);
  static const Color warningBackground = Color(0xFFFFF5DF);
  static const Color borderColor = Color(0xFFDFE5D7);

  bool get _hasResults => daunDiagnosis != null && batangDiagnosis != null;

  bool get _needsAttention {
    return (daunDiagnosis != null && !daunDiagnosis!.isSehat) ||
        (batangDiagnosis != null && !batangDiagnosis!.isSehat);
  }

  Color get _statusColor => _needsAttention ? warningColor : primaryColor;

  Color get _statusBackground =>
      _needsAttention ? warningBackground : softGreen;

  String _formatConfidence(DiagnosisModel? diagnosis) {
    if (diagnosis == null) return '—';
    return '${diagnosis.confidence.toStringAsFixed(2)}%';
  }

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
                    'Hasil deteksi',
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPhotoResult(
                              photo: daunFoto,
                              diagnosis: daunDiagnosis,
                              titleFallback: 'Foto daun',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPhotoResult(
                              photo: batangFoto,
                              diagnosis: batangDiagnosis,
                              titleFallback: 'Foto batang',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildFindings(),
                      const SizedBox(height: 16),
                      _buildBatchInformation(),
                      const SizedBox(height: 12),
                      if (catatanGejala.trim().isNotEmpty) _buildUserNote(),
                      if (catatanGejala.trim().isNotEmpty)
                        const SizedBox(height: 12),
                      _buildDisclaimer(),
                      const SizedBox(height: 16),
                      if (_hasResults) _buildSavedInformation(),
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
    final title = !_hasResults
        ? 'Hasil belum tersedia'
        : _needsAttention
        ? 'Perlu perhatian'
        : 'Normal';

    final subtitle = !_hasResults
        ? 'Data diagnosis lengkap belum tersedia dari server.'
        : _needsAttention
        ? 'Satu atau lebih foto memerlukan perhatian.'
        : 'Kedua foto diklasifikasikan sehat oleh server.';

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
            _hasResults
                ? 'Hasil diagnosis • 2 foto diperiksa'
                : 'Hasil diagnosis',
            style: TextStyle(
              color: _statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _hasResults && !_needsAttention
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: _statusColor,
                size: 25,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
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
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: _statusColor,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoResult({
    required File? photo,
    required DiagnosisModel? diagnosis,
    required String titleFallback,
  }) {
    final isHealthy = diagnosis?.isSehat ?? false;
    final isAvailable = diagnosis != null;
    final statusColor = isAvailable
        ? (isHealthy ? primaryColor : warningColor)
        : mutedColor;
    final statusBackground = isAvailable
        ? (isHealthy ? softGreen : warningBackground)
        : const Color(0xFFF2F3F0);
    final title = !isAvailable
        ? 'Belum tersedia'
        : isHealthy
        ? 'Sehat'
        : 'Tidak Sehat';
    final statusLabel = !isAvailable
        ? 'Belum tersedia'
        : isHealthy
        ? 'Normal'
        : 'Perlu perhatian';

    return Container(
      height: 198,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 108,
            width: double.infinity,
            child: photo != null
                ? Image.file(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _imageFallback(),
                  )
                : diagnosis != null
                ? Image.network(
                    diagnosis.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _imageFallback(),
                  )
                : _imageFallback(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? title : titleFallback,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAvailable
                      ? '${diagnosis.hasilLabel} • Keyakinan: ${_formatConfidence(diagnosis)}'
                      : 'Hasil pemeriksaan belum tersedia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 9,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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

  Widget _imageFallback() {
    return Container(
      color: softGreen,
      alignment: Alignment.center,
      child: const Icon(Icons.eco_outlined, color: primaryColor, size: 38),
    );
  }

  Widget _buildFindings() {
    final leaf = daunDiagnosis;
    final stem = batangDiagnosis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Temuan visual',
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          leaf == null
              ? 'Daun: hasil klasifikasi belum tersedia.'
              : 'Daun: ${leaf.hasilLabel} • ${leaf.rekomendasi}',
          style: const TextStyle(
            color: mutedColor,
            fontSize: 12,
            height: 1.4,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 7),
        Text(
          stem == null
              ? 'Batang: hasil klasifikasi belum tersedia.'
              : 'Batang: ${stem.hasilLabel} • ${stem.rekomendasi}',
          style: const TextStyle(
            color: mutedColor,
            fontSize: 12,
            height: 1.4,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildBatchInformation() {
    final budidaya = daunDiagnosis?.budidaya ?? batangDiagnosis?.budidaya;
    final subtitle = budidaya == null
        ? 'Budidaya yang dipilih saat pemeriksaan'
        : 'Meja ${budidaya.meja?.nomorMeja ?? budidaya.mejaId} • '
              '${budidaya.jumlahTanaman} tanaman • ${budidaya.hss} HSS';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            batchName,
            style: const TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: mutedColor,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan gejala dari pengguna',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            catatanGejala,
            style: const TextStyle(
              color: mutedColor,
              fontSize: 11,
              height: 1.4,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    final disclaimer =
        daunDiagnosis?.disclaimer ??
        batangDiagnosis?.disclaimer ??
        DiagnosisModel.disclaimerDefault;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 19, color: mutedColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              disclaimer,
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
    );
  }

  Widget _buildSavedInformation() {
    final date =
        daunDiagnosis?.tanggalDiagnosis ?? batangDiagnosis!.tanggalDiagnosis;

    return Row(
      children: [
        const Icon(Icons.check_rounded, size: 16, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tersimpan di riwayat • ${_formatDate(date)}',
            style: const TextStyle(
              color: primaryColor,
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}
