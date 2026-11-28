import 'package:flutter/material.dart';

import '../../controllers/budidaya/budidaya_controller.dart';
import '../../controllers/panen/panen_controller.dart';
import '../../models/budidaya/budidaya_model.dart';
import '../../models/panen/panen_model.dart';

/// Form edit panen. Terima {'id': id} melalui arguments route /panen/edit.
/// Hanya field yang didukung endpoint PUT /panen/{id} yang dikirim.
class EditRotasiPanenView extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const EditRotasiPanenView({super.key, this.initialData});

  @override
  State<EditRotasiPanenView> createState() => _EditRotasiPanenViewState();
}

class _EditRotasiPanenViewState extends State<EditRotasiPanenView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFB7C4A5);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _beratController = TextEditingController();
  late final BudidayaController _budidayaController;
  late final PanenController _panenController;

  int? _panenId;
  int? _selectedBudidayaId;
  DateTime _tanggalPanen = DateTime.now();
  String _status = PanenModel.statusTerjadwal;
  bool _isLoadingInitial = true;
  bool _isLoadingOptions = false;
  String? _localErrorMessage;

  PanenModel? get _panen => _panenController.selectedPanen;

  List<BudidayaModel> get _budidayaOptions {
    final options = _budidayaController.budidayas
        .where((item) => item.status == BudidayaModel.statusBerjalan)
        .toList();
    final currentId = _selectedBudidayaId ?? _panen?.budidayaId;
    if (currentId != null && !options.any((item) => item.id == currentId)) {
      BudidayaModel? current;
      for (final item in _budidayaController.budidayas) {
        if (item.id == currentId) {
          current = item;
          break;
        }
      }
      current ??= _panen?.budidaya;
      if (current != null) {
        options.add(current);
      }
    }
    return options;
  }

  BudidayaModel? get _selectedBudidaya {
    for (final item in _budidayaOptions) {
      if (item.id == _selectedBudidayaId) {
        return item;
      }
    }
    return _panen?.budidaya;
  }

  @override
  void initState() {
    super.initState();
    _budidayaController = BudidayaController();
    _panenController = PanenController();
    _panenId = _readId(widget.initialData);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _beratController.dispose();
    _budidayaController.dispose();
    _panenController.dispose();
    super.dispose();
  }

  int? _readId(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final raw = data['id'] ?? data['panen_id'];
    if (raw is int) {
      return raw > 0 ? raw : null;
    }
    final parsed = int.tryParse(raw?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  Future<void> _loadInitialData() async {
    final id = _panenId;
    if (id == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingInitial = false;
        _localErrorMessage =
            'ID panen tidak ditemukan. Buka ulang data panen dari daftar.';
      });
      return;
    }

    final results = await Future.wait<bool>([
      _panenController.loadPanenDetail(id: id),
      _loadBudidayaOptions(),
    ]);

    if (!mounted) {
      return;
    }
    final item = _panenController.selectedPanen;
    setState(() {
      _isLoadingInitial = false;
      if (item != null) {
        _selectedBudidayaId = item.budidayaId;
        _tanggalPanen = _dateOnly(item.tanggalPanen);
        _status = item.status;
        _beratController.text = item.beratKg == null
            ? ''
            : _formatWeightForInput(item.beratKg!);
      } else {
        _localErrorMessage =
            _panenController.detailErrorMessage ??
            'Detail panen tidak dapat dimuat.';
      }
      if (!results[1] && _budidayaController.budidayas.isEmpty) {
        _localErrorMessage ??=
            _budidayaController.errorMessage ?? 'Daftar budidaya gagal dimuat.';
      }
    });
  }

  Future<bool> _loadBudidayaOptions() async {
    if (_isLoadingOptions) {
      return false;
    }
    _isLoadingOptions = true;
    if (mounted) {
      setState(() {});
    }

    var loaded = await _budidayaController.loadBudidayas(perPage: 100);
    while (loaded && _budidayaController.hasMoreBudidayas) {
      loaded = await _budidayaController.loadMoreBudidayas();
    }

    _isLoadingOptions = false;
    if (mounted) {
      setState(() {});
    }
    return loaded;
  }

  Future<void> _retryLoad() async {
    setState(() {
      _isLoadingInitial = true;
      _localErrorMessage = null;
    });
    await _loadInitialData();
  }

  Future<void> _selectBudidaya(int? value) async {
    if (value == null) {
      return;
    }
    setState(() {
      _selectedBudidayaId = value;
      _localErrorMessage = null;
      final selected = _selectedBudidaya;
      if (selected != null &&
          _dateOnly(_tanggalPanen).isBefore(_dateOnly(selected.tanggalSemai))) {
        _tanggalPanen = _dateOnly(selected.tanggalSemai);
      }
    });
  }

  Future<void> _selectTanggalPanen() async {
    final budidaya = _selectedBudidaya;
    if (budidaya == null) {
      return;
    }
    final firstDate = _dateOnly(budidaya.tanggalSemai);
    final currentDate = _dateOnly(_tanggalPanen);
    final initialDate = currentDate.isBefore(firstDate)
        ? firstDate
        : currentDate;

    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: textColor,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (result != null && mounted) {
      setState(() => _tanggalPanen = _dateOnly(result));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _localErrorMessage = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = _panen;
    final budidaya = _selectedBudidaya;
    if (item == null || _panenId == null) {
      setState(() => _localErrorMessage = 'Detail panen belum tersedia.');
      return;
    }
    if (budidaya == null || _selectedBudidayaId == null) {
      setState(
        () => _localErrorMessage = 'Pilih budidaya untuk data panen ini.',
      );
      return;
    }
    if (_dateOnly(_tanggalPanen).isBefore(_dateOnly(budidaya.tanggalSemai))) {
      setState(
        () => _localErrorMessage =
            'Tanggal panen tidak boleh sebelum tanggal semai.',
      );
      return;
    }

    final berat = _status == PanenModel.statusSelesai
        ? double.tryParse(_beratController.text.trim().replaceAll(',', '.'))
        : null;

    final success = await _panenController.updatePanen(
      id: _panenId!,
      budidayaId: _selectedBudidayaId!,
      tanggalPanen: _dateOnly(_tanggalPanen),
      status: _status,
      beratKg: berat,
    );
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: _buildHeader(),
          ),
          Positioned(
            top: 104,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: _isLoadingInitial
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : _panen == null
                  ? _buildLoadError()
                  : Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                28,
                                24,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildBudidayaField(),
                                  const SizedBox(height: 18),
                                  _buildTanggalField(),
                                  const SizedBox(height: 18),
                                  _buildStatusField(),
                                  if (_status == PanenModel.statusSelesai) ...[
                                    const SizedBox(height: 18),
                                    _buildBeratField(),
                                  ],
                                  const SizedBox(height: 16),
                                  _buildInfoCard(),
                                  if (_localErrorMessage != null ||
                                      _panenController.submitErrorMessage !=
                                          null) ...[
                                    const SizedBox(height: 14),
                                    _buildErrorCard(
                                      _localErrorMessage ??
                                          _panenController.submitErrorMessage!,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          _buildBottomButtons(),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: primaryColor,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 28,
        24,
        0,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: const Padding(
              padding: EdgeInsets.only(right: 12, top: 4, bottom: 4),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Edit data panen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    final message =
        _localErrorMessage ??
        _panenController.detailErrorMessage ??
        'Data panen tidak tersedia.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFB85B4B),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _retryLoad,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
              style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String value) => Text(
    value,
    style: const TextStyle(
      color: textColor,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _inputDecoration({String? hintText, String? suffixText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      suffixText: suffixText,
      hintStyle: const TextStyle(color: mutedColor, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildBudidayaField() {
    return AnimatedBuilder(
      animation: _budidayaController,
      builder: (context, _) {
        final options = _budidayaOptions;
        final selectedExists = options.any(
          (item) => item.id == _selectedBudidayaId,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Budidaya'),
            const SizedBox(height: 8),
            if (_isLoadingOptions ||
                _budidayaController.isLoading ||
                _budidayaController.isLoadingMore)
              _buildLoadingField('Memuat data budidaya...')
            else if (options.isEmpty)
              _buildEmptyField('Data budidaya tidak tersedia untuk dipilih.')
            else
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedExists ? _selectedBudidayaId : null,
                    isExpanded: true,
                    hint: const Text('Pilih budidaya'),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: primaryColor,
                    ),
                    items: options.map((item) {
                      final mejaNumber = item.meja?.nomorMeja;
                      final currentIsCompleted =
                          item.id == _panen?.budidayaId &&
                          item.status == BudidayaModel.statusSelesai;
                      return DropdownMenuItem<int>(
                        value: item.id,
                        child: Text(
                          'Budidaya #${item.id} • ${mejaNumber == null ? 'Meja ${item.mejaId}' : 'Meja $mejaNumber'}${currentIsCompleted ? ' • budidaya selesai' : ''}',
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _selectBudidaya,
                  ),
                ),
              ),
            if (_selectedBudidaya != null) ...[
              const SizedBox(height: 6),
              Text(
                'Tanggal semai: ${_formatDate(_selectedBudidaya!.tanggalSemai)}',
                style: const TextStyle(color: mutedColor, fontSize: 10),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTanggalField() {
    final selected = _selectedBudidaya;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tanggal panen'),
        const SizedBox(height: 8),
        InkWell(
          onTap: selected == null ? null : _selectTanggalPanen,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(_tanggalPanen),
                  style: const TextStyle(color: textColor, fontSize: 14),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 6),
          const Text(
            'Tanggal tidak boleh lebih awal dari tanggal semai.',
            style: TextStyle(color: mutedColor, fontSize: 10),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Status panen'),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _status,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: primaryColor,
              ),
              items: const [
                DropdownMenuItem(
                  value: PanenModel.statusTerjadwal,
                  child: Text('Terjadwal'),
                ),
                DropdownMenuItem(
                  value: PanenModel.statusSelesai,
                  child: Text('Selesai'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _status = value;
                  if (value == PanenModel.statusTerjadwal) {
                    _beratController.clear();
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeratField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Berat hasil panen'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _beratController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          cursorColor: primaryColor,
          style: const TextStyle(color: textColor, fontSize: 14),
          decoration: _inputDecoration(
            hintText: 'Masukkan berat panen',
            suffixText: 'kg',
          ),
          validator: (value) {
            if (_status != PanenModel.statusSelesai) {
              return null;
            }
            final berat = double.tryParse(
              (value ?? '').trim().replaceAll(',', '.'),
            );
            if (!PanenModel.isValidBeratKg(berat)) {
              return 'Berat panen harus berupa angka valid dan minimal 0,01 kg.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Form hanya mengubah budidaya, tanggal panen, status, dan berat hasil panen. Berat wajib saat status Selesai.',
              style: TextStyle(color: textColor, fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingField(String message) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildEmptyField(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        border: Border.all(color: const Color(0xFFE9D9B6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF80662D), fontSize: 11),
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
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return AnimatedBuilder(
      animation: _panenController,
      builder: (context, _) {
        final isSubmitting = _panenController.isSubmitting;
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.paddingOf(context).bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8ECE3))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mutedColor,
                    side: const BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSubmitting || _isLoadingInitial || _panen == null
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFB8C3AA),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    isSubmitting ? 'Menyimpan...' : 'Simpan perubahan',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatWeightForInput(double value) => value
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
