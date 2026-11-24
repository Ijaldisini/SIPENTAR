import 'dart:io';

import 'package:flutter/material.dart';

class KesehatanHasilDeteksiView extends StatelessWidget {
  static const String sampleImage =
      'https://images.unsplash.com/photo-1540420773420-3366772f4999'
      '?auto=format&fit=crop&w=500&q=80';

  final File? daunFoto;
  final File? batangFoto;
  final String status;
  final String batchName;
  final String catatanGejala;

  const KesehatanHasilDeteksiView({
    super.key,
    this.daunFoto,
    this.batangFoto,
    required this.batchName,
    required this.catatanGejala,
    this.status = 'Perlu perhatian',
  });

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softGreen = Color(0xFFF1F5E9);
  static const Color warningColor = Color(0xFF8C5B16);
  static const Color warningBackground = Color(0xFFFFF5DF);

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
                              title: 'Bercak daun',
                              confidence: '92%',
                              status: 'Perlu perhatian',
                              isWarning: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPhotoResult(
                              photo: batangFoto,
                              title: 'Sehat',
                              confidence: '98%',
                              status: 'Normal',
                              isWarning: false,
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

                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: primaryColor,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ini merupakan tampilan contoh hasil. '
                              'Analisis foto belum terhubung ke backend.',
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: 10,
                                height: 1.4,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
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
        color: warningBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contoh hasil • 2 foto diperiksa',
            style: TextStyle(
              color: warningColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: warningColor, size: 25),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Perlu perhatian',
                  style: TextStyle(
                    color: warningColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            'Perubahan warna dan bercak terlihat pada daun.',
            style: TextStyle(
              color: warningColor,
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
    required String title,
    required String confidence,
    required String status,
    required bool isWarning,
  }) {
    final Color statusColor = isWarning ? warningColor : primaryColor;

    final Color statusBackground = isWarning ? warningBackground : softGreen;

    return Container(
      height: 198,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDFE5D7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 108,
            width: double.infinity,
            child: photo != null
                ? Image.file(photo, fit: BoxFit.cover)
                : Image.network(
                    sampleImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: softGreen,
                        child: const Icon(
                          Icons.eco_outlined,
                          color: primaryColor,
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  'Keyakinan contoh: $confidence',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 10,
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
                    status,
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

  Widget _buildFindings() {
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
        const Text(
          'Daun: bercak kecokelatan disertai area yang menguning.',
          style: TextStyle(
            color: mutedColor,
            fontSize: 12,
            height: 1.4,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Batang: permukaan tampak utuh, tanpa kerusakan '
          'yang jelas pada foto.',
          style: TextStyle(
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
          const Text(
            'Batch yang dipilih saat pemeriksaan',
            style: TextStyle(
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 19, color: mutedColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hasil foto bersifat indikatif, bukan diagnosis pasti. '
              'Konfirmasi ke pendamping budidaya bila gejala meluas.',
              style: TextStyle(
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
}
