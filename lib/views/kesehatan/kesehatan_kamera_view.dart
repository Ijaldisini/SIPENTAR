import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class KesehatanKameraView extends StatefulWidget {
  final File? initialDaun;
  final File? initialBatang;
  final int initialStep;

  const KesehatanKameraView({
    super.key,
    this.initialDaun,
    this.initialBatang,
    this.initialStep = 0,
  });

  @override
  State<KesehatanKameraView> createState() => _KesehatanKameraViewState();
}

class _KesehatanKameraViewState extends State<KesehatanKameraView>
    with WidgetsBindingObserver {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softGreen = Color(0xFFF1F5E9);

  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _controller;

  File? daunFoto;
  File? batangFoto;

  late int selectedStep;

  bool isInitializing = true;
  bool isTakingPicture = false;
  bool _isAppResumed = true;

  String? cameraError;

  File? get currentPhoto {
    return selectedStep == 0 ? daunFoto : batangFoto;
  }

  @override
  void initState() {
    super.initState();

    daunFoto = widget.initialDaun;
    batangFoto = widget.initialBatang;
    selectedStep = widget.initialStep;

    WidgetsBinding.instance.addObserver(this);

    unawaited(_initializeCamera());
  }

  Future<void> _initializeCamera() async {
    if (isInitializing && _controller != null) return;
    if (!_isAppResumed) return;

    setState(() {
      isInitializing = true;
      cameraError = null;
    });

    CameraController? newController;

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw CameraException(
          'NoCamera',
          'Tidak ditemukan kamera pada perangkat.',
        );
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      newController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _controller = newController;

      await newController.initialize();

      if (!mounted || !identical(_controller, newController)) {
        await newController.dispose();
        return;
      }

      setState(() {
        cameraError = null;
      });
    } on CameraException catch (error) {
      if (identical(_controller, newController)) {
        _controller = null;
      }

      await newController?.dispose();

      if (!mounted) return;

      setState(() {
        cameraError = _cameraErrorMessage(error);
      });
    } catch (error) {
      if (identical(_controller, newController)) {
        _controller = null;
      }

      await newController?.dispose();

      if (!mounted) return;

      setState(() {
        cameraError = 'Tidak dapat mengakses kamera perangkat.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isInitializing = false;
        });

        if (_isAppResumed && _controller == null && cameraError == null) {
          unawaited(_initializeCamera());
        }
      }
    }
  }

  String _cameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Izin kamera ditolak. Silakan aktifkan izin kamera di pengaturan HP.';

      case 'CameraAccessRestricted':
        return 'Akses kamera dibatasi oleh perangkat.';

      case 'NoCamera':
        return 'Kamera tidak ditemukan pada perangkat.';

      default:
        return 'Kamera gagal dibuka: ${error.description ?? error.code}';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppResumed = true;
      unawaited(_initializeCamera());
    } else {
      _isAppResumed = false;

      final oldController = _controller;
      _controller = null;

      if (oldController != null) {
        unawaited(oldController.dispose());
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _controller?.dispose();

    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      _showMessage('Kamera belum siap.');
      return;
    }

    if (isTakingPicture) return;

    setState(() {
      isTakingPicture = true;
    });

    try {
      final XFile capturedImage = await controller.takePicture();

      if (!mounted) return;

      final File photo = File(capturedImage.path);

      setState(() {
        if (selectedStep == 0) {
          daunFoto = photo;

          selectedStep = 1;
        } else {
          batangFoto = photo;
        }
      });

      _showMessage(
        selectedStep == 1
            ? 'Foto berhasil disimpan.'
            : 'Foto batang berhasil disimpan.',
      );
    } on CameraException catch (error) {
      if (!mounted) return;

      _showMessage('Gagal mengambil foto: ${error.description ?? error.code}');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Terjadi kesalahan saat mengambil foto.');
    } finally {
      if (mounted) {
        setState(() {
          isTakingPicture = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (isTakingPicture) return;

    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (selectedImage == null || !mounted) return;

      final File photo = File(selectedImage.path);

      setState(() {
        if (selectedStep == 0) {
          daunFoto = photo;
          selectedStep = 1;
        } else {
          batangFoto = photo;
        }
      });

      _showMessage('Foto berhasil dipilih dari galeri.');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Tidak dapat membuka galeri.');
    }
  }

  void _usePhotos() {
    if (daunFoto == null || batangFoto == null) {
      _showMessage('Lengkapi foto daun dan foto batang terlebih dahulu.');
      return;
    }

    Navigator.pop(context, <String, File>{
      'daun': daunFoto!,
      'batang': batangFoto!,
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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
                    'Ambil foto tanaman',
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    children: [
                      _buildStepSelector(),

                      const SizedBox(height: 14),

                      Expanded(child: _buildCameraPreview()),

                      const SizedBox(height: 12),

                      Text(
                        selectedStep == 0
                            ? 'Ambil foto daun terlebih dahulu, lalu lanjutkan foto batang dari tanaman yang sama.'
                            : 'Ambil foto batang dari tanaman yang sama. Pastikan bagian batang terlihat jelas.',
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                          height: 1.4,
                          fontFamily: 'Inter',
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (daunFoto != null && batangFoto != null) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _usePhotos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Gunakan 2 foto',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      _buildCameraControls(),
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

  Widget _buildStepSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStepButton(title: '1. Daun', step: 0)),
          Expanded(child: _buildStepButton(title: '2. Batang', step: 1)),
        ],
      ),
    );
  }

  Widget _buildStepButton({required String title, required int step}) {
    final bool isSelected = selectedStep == step;
    final bool hasPhoto = step == 0 ? daunFoto != null : batangFoto != null;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStep = step;
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          hasPhoto ? '$title ✓' : title,
          style: TextStyle(
            color: isSelected ? Colors.white : mutedColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final File? photo = currentPhoto;
    final controller = _controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            Image.file(photo, fit: BoxFit.cover)
          else if (controller != null && controller.value.isInitialized)
            Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: CameraPreview(controller),
            )
          else
            _buildCameraLoading(),

          const Positioned.fill(
            child: CustomPaint(painter: CameraFramePainter()),
          ),

          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${selectedStep + 1} dari 2',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                photo != null
                    ? 'Foto sudah diambil. Tekan shutter untuk mengambil ulang.'
                    : selectedStep == 0
                    ? 'Posisikan daun di dalam bingkai'
                    : 'Posisikan batang di dalam bingkai',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLoading() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: cameraError != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  color: Colors.white,
                  size: 44,
                ),
                const SizedBox(height: 14),
                Text(
                  cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      cameraError = null;
                    });
                    unawaited(_initializeCamera());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 14),
                Text(
                  'Menghubungkan kamera HP...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCameraControls() {
    final bool cameraReady =
        _controller != null && _controller!.value.isInitialized;

    return SizedBox(
      height: 86,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: InkWell(
                onTap: isTakingPicture ? null : _pickFromGallery,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, color: primaryColor, size: 26),
                      SizedBox(height: 5),
                      Text(
                        'Galeri',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: cameraReady && !isTakingPicture ? _capturePhoto : null,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cameraReady ? primaryColor : mutedColor,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cameraReady ? primaryColor : mutedColor,
                      shape: BoxShape.circle,
                    ),
                    child: isTakingPicture
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class CameraFramePainter extends CustomPainter {
  const CameraFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double left = size.width * 0.10;
    final double top = size.height * 0.14;
    final double right = size.width * 0.90;
    final double bottom = size.height * 0.84;

    const double length = 28;

    canvas.drawLine(Offset(left, top + length), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + length, top), paint);

    canvas.drawLine(Offset(right - length, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + length), paint);

    canvas.drawLine(Offset(left, bottom - length), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + length, bottom), paint);

    canvas.drawLine(
      Offset(right - length, bottom),
      Offset(right, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right, bottom - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CameraFramePainter oldDelegate) {
    return false;
  }
}
