import 'dart:io';

import 'package:flutter/material.dart';

import '../../controllers/budidaya/budidaya_controller.dart';
import '../../controllers/diagnosis/diagnosis_controller.dart';
import '../../models/budidaya/budidaya_model.dart';
import '../../models/diagnosis/diagnosis_model.dart';
import 'kesehatan_kamera_view.dart';
import 'kesehatan_hasil_deteksi_view.dart';

/// Form pemeriksaan yang mempertahankan desain dua foto daun dan batang.
///
/// Kontrak API Laravel saat ini menerima satu foto per POST /diagnosis.
/// Karena UI menyediakan dua foto, file daun dan batang dikirim sebagai dua
/// request diagnosis terpisah dengan budidaya_id yang sama.
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
  static const Color borderColor = Color(0xFFDFE5D7);

  static const String sampleImage =
      'https://images.unsplash.com/photo-1540420773420-3366772f4999'
      '?auto=format&fit=crop&w=500&q=80';

  final BudidayaController _budidayaController = BudidayaController();
  final DiagnosisController _diagnosisController = DiagnosisController();
  final TextEditingController noteController = TextEditingController();

  int? _selectedBudidayaId;
  File? daunFoto;
  File? batangFoto;
  DiagnosisModel? _daunDiagnosis;
  DiagnosisModel? _batangDiagnosis;

  bool _isOpeningCamera = false;
  bool _isSubmittingPair = false;

  bool get _isBusy => _isSubmittingPair || _diagnosisController.isSubmitting;

  @override
  void initState() {
    super.initState();
    _loadBudidayas();
  }

  @override
  void dispose() {
    noteController.dispose();
    _budidayaController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _loadBudidayas() async {
    final loaded = await _budidayaController.loadBudidayas(
      status: BudidayaModel.statusBerjalan,
      perPage: 100,
    );

    if (!mounted) return;

    if (loaded && _budidayaController.budidayas.isNotEmpty) {
      setState(() {
        _selectedBudidayaId ??= _budidayaController.budidayas.first.id;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  int get totalFoto {
    var total = 0;
    if (daunFoto != null) total++;
    if (batangFoto != null) total++;
    return total;
  }

  Future<void> _openCamera({int initialStep = 0}) async {
    if (_isOpeningCamera || _isBusy) return;

    setState(() => _isOpeningCamera = true);

    try {
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

      final nextDaun = result['daun'];
      final nextBatang = result['batang'];

      setState(() {
        if (daunFoto?.path != nextDaun?.path) {
          _daunDiagnosis = null;
        }
        if (batangFoto?.path != nextBatang?.path) {
          _batangDiagnosis = null;
        }
        daunFoto = nextDaun;
        batangFoto = nextBatang;
      });
    } finally {
      if (mounted) setState(() => _isOpeningCamera = false);
    }
  }

  Future<void> _changePhoto(String title) async {
    await _openCamera(initialStep: title == 'Foto daun' ? 0 : 1);
  }

  Future<void> _startDetection() async {
    if (_isBusy) return;

    final leafImage = daunFoto;
    final stemImage = batangFoto;
    final budidayaId = _selectedBudidayaId;

    if (leafImage == null || stemImage == null) {
      _showMessage(
        'Silakan lengkapi foto daun dan foto batang terlebih dahulu.',
      );
      return;
    }

    if (budidayaId == null) {
      _showMessage('Pilih budidaya terlebih dahulu.');
      return;
    }

    setState(() => _isSubmittingPair = true);
    try {
      // Endpoint Laravel menerima satu image per diagnosis. Simpan hasil daun
      // agar tidak terkirim ulang bila upload foto batang gagal dan dicoba lagi.
      if (_daunDiagnosis == null) {
        final result = await _diagnosisController.createDiagnosis(
          image: leafImage,
          budidayaId: budidayaId,
        );

        if (!mounted) return;
        if (result == null) {
          _showMessage(
            _diagnosisController.submitErrorMessage ??
                'Gagal mengirim foto daun untuk diagnosis.',
          );
          return;
        }

        setState(() => _daunDiagnosis = result);
      }

      if (_batangDiagnosis == null) {
        final result = await _diagnosisController.createDiagnosis(
          image: stemImage,
          budidayaId: budidayaId,
        );

        if (!mounted) return;
        if (result == null) {
          final detail = _diagnosisController.submitErrorMessage;
          _showMessage(
            detail == null || detail.isEmpty
                ? 'Foto daun sudah tersimpan, tetapi foto batang gagal diproses.'
                : 'Foto daun sudah tersimpan, tetapi foto batang gagal diproses. $detail',
          );
          return;
        }

        setState(() => _batangDiagnosis = result);
      }

      if (!mounted || _daunDiagnosis == null || _batangDiagnosis == null) {
        return;
      }

      final selectedBudidaya = _selectedBudidaya;
      final batchLabel = selectedBudidaya == null
          ? 'Budidaya #$budidayaId'
          : _budidayaLabel(selectedBudidaya);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KesehatanHasilDeteksiView(
            daunFoto: leafImage,
            batangFoto: stemImage,
            daunDiagnosis: _daunDiagnosis!,
            batangDiagnosis: _batangDiagnosis!,
            batchName: batchLabel,
            catatanGejala: noteController.text.trim(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingPair = false);
    }
  }

  BudidayaModel? get _selectedBudidaya {
    for (final item in _budidayaController.budidayas) {
      if (item.id == _selectedBudidayaId) return item;
    }
    return null;
  }

  String _budidayaLabel(BudidayaModel budidaya) {
    final mejaNumber = budidaya.meja?.nomorMeja;
    final meja = mejaNumber == null
        ? 'Meja ${budidaya.mejaId}'
        : 'Meja $mejaNumber';
    return 'Budidaya #${budidaya.id} • $meja • ${budidaya.jumlahTanaman} tanaman';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_budidayaController, _diagnosisController]),
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final isSubmitting = _isBusy;

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
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(context),
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
                          onPressed: isSubmitting || _isOpeningCamera
                              ? null
                              : () {
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
                      _buildBudidayaDropdown(),
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
                        enabled: !isSubmitting,
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
                      if (_diagnosisController.submitErrorMessage != null) ...[
                        const SizedBox(height: 12),
                        _buildErrorCard(
                          _diagnosisController.submitErrorMessage!,
                        ),
                      ],
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
              onPressed:
                  isSubmitting ||
                      _isOpeningCamera ||
                      _budidayaController.isLoading
                  ? null
                  : _startDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryColor.withValues(alpha: 0.55),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
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
        border: Border.all(color: borderColor),
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
              onPressed: _isBusy ? null : () => _changePhoto(title),
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

  Widget _buildBudidayaDropdown() {
    if (_budidayaController.isLoading) {
      return _buildLoadingField('Memuat daftar budidaya...');
    }

    if (_budidayaController.errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildErrorCard(_budidayaController.errorMessage!),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _budidayaController.isLoading ? null : _loadBudidayas,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba lagi'),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
        ],
      );
    }

    final budidayas = _budidayaController.budidayas;
    if (budidayas.isEmpty) {
      return _buildErrorCard(
        'Belum ada budidaya yang berjalan. Mulai budidaya terlebih dahulu.',
      );
    }

    final selectedExists = budidayas.any(
      (item) => item.id == _selectedBudidayaId,
    );

    return DropdownButtonFormField<int>(
      initialValue: selectedExists ? _selectedBudidayaId : null,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB7C4A5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB7C4A5)),
        ),
      ),
      items: budidayas.map((budidaya) {
        return DropdownMenuItem<int>(
          value: budidaya.id,
          child: Text(
            _budidayaLabel(budidaya),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textColor,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        );
      }).toList(),
      onChanged: _isBusy
          ? null
          : (value) {
              if (value == null || value == _selectedBudidayaId) return;
              setState(() {
                _selectedBudidayaId = value;
                _daunDiagnosis = null;
                _batangDiagnosis = null;
              });
            },
    );
  }

  Widget _buildLoadingField(String message) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(color: mutedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F2),
        border: Border.all(color: const Color(0xFFF0D4CA)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF8E4135),
          fontSize: 11,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
