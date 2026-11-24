import 'dart:io';

import 'package:flutter/material.dart';

import 'kesehatan_kamera_view.dart';
import 'kesehatan_hasil_deteksi_view.dart';

class KesehatanUnggahFotoView extends StatefulWidget {
  const KesehatanUnggahFotoView({super.key});

  @override
  State<KesehatanUnggahFotoView> createState() =>
      _KesehatanUnggahFotoViewState();
}

class _KesehatanUnggahFotoViewState extends State<KesehatanUnggahFotoView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softGreen = Color(0xFFF1F5E9);

  static const String sampleImage =
      'https://images.unsplash.com/photo-1540420773420-3366772f4999'
      '?auto=format&fit=crop&w=500&q=80';

  String selectedBatch = 'Batch 04 • Selada';

  final List<String> batchOptions = [
    'Batch 04 • Selada',
    'Batch 03 • Selada',
    'Batch 05 • Selada',
  ];

  final TextEditingController noteController = TextEditingController(
    text: 'Bercak pada daun terlihat sejak pagi.',
  );

  File? daunFoto;
  File? batangFoto;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  int get totalFoto {
    int total = 0;

    if (daunFoto != null) total++;
    if (batangFoto != null) total++;

    return total;
  }

  Future<void> _openCamera({int initialStep = 0}) async {
    final result = await Navigator.push<Map<String, File>>(
      context,
      MaterialPageRoute(
        builder: (context) => KesehatanKameraView(
          initialDaun: daunFoto,
          initialBatang: batangFoto,
          initialStep: initialStep,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      daunFoto = result['daun'];
      batangFoto = result['batang'];
    });
  }

  Future<void> _changePhoto(String title) async {
    await _openCamera(initialStep: title == 'Foto daun' ? 0 : 1);
  }

  void _startDetection() {
    if (daunFoto == null || batangFoto == null) {
      _showMessage(
        'Silakan lengkapi foto daun dan foto batang terlebih dahulu.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KesehatanHasilDeteksiView(
          daunFoto: daunFoto!,
          batangFoto: batangFoto!,
          batchName: selectedBatch,
          catatanGejala: noteController.text.trim(),
        ),
      ),
    );
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
                    'Deteksi tanaman',
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalFoto foto siap diperiksa',
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(child: _buildPhotoCard('Foto daun')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildPhotoCard('Foto batang')),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final nextStep = daunFoto == null ? 0 : 1;

                            _openCamera(initialStep: nextStep);
                          },
                          icon: const Icon(Icons.camera_alt_outlined, size: 19),
                          label: const Text(
                            'Ambil Gambar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            backgroundColor: softGreen,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Batch budidaya',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        initialValue: selectedBatch,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFB7C4A5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFB7C4A5),
                            ),
                          ),
                        ),
                        items: batchOptions.map((batch) {
                          return DropdownMenuItem<String>(
                            value: batch,
                            child: Text(
                              batch,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedBatch = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Catatan gejala (opsional)',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Tuliskan gejala tanaman...',
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFB7C4A5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFB7C4A5),
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: softGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: primaryColor,
                              size: 19,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Gunakan pencahayaan yang cukup. Pastikan daun dan batang terlihat jelas, tidak buram.',
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Deteksi kesehatan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String title) {
    final File? photo = title == 'Foto daun' ? daunFoto : batangFoto;

    return Container(
      height: 228,
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
            height: 140,
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
                          size: 40,
                          color: primaryColor,
                        ),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 0),
            child: Text(
              title,
              style: const TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 8, 0),
            child: Row(
              children: [
                Icon(
                  photo != null ? Icons.check_circle : Icons.info_outline,
                  size: 13,
                  color: photo != null ? primaryColor : mutedColor,
                ),
                const SizedBox(width: 5),
                Text(
                  photo != null ? 'Foto siap' : 'Belum ada foto',
                  style: TextStyle(
                    color: photo != null ? primaryColor : mutedColor,
                    fontSize: 10,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: TextButton(
              onPressed: () => _changePhoto(title),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                photo != null ? 'Ganti foto' : 'Pilih foto',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
