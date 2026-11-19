import 'package:flutter/material.dart';

class StockFormView extends StatefulWidget {
  final bool isEdit;
  final Map<String, String>? initialData;

  const StockFormView({super.key, this.isEdit = false, this.initialData});

  @override
  State<StockFormView> createState() => _StockFormViewState();
}

class _StockFormViewState extends State<StockFormView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color borderColor = Color(0xFFB7C4A5);

  final List<String> categories = ['Nutrisi', 'Media tanam', 'Benih'];

  final List<String> units = ['Liter', 'Lembar', 'Pak'];

  late TextEditingController nameController;
  late TextEditingController quantityController;
  late TextEditingController minimumController;
  late TextEditingController notesController;

  late String selectedCategory;
  late String selectedUnit;

  @override
  void initState() {
    super.initState();

    final data =
        widget.initialData ??
        (widget.isEdit
            ? {
                'name': 'Nutrisi AB Mix',
                'category': 'Nutrisi',
                'quantity': '2 Liter',
                'minimum': 'Batas min. 5 liter',
                'notes': 'Nutrisi untuk selada hidroponik.',
              }
            : {
                'name': 'Benih pakcoy',
                'category': 'Benih',
                'quantity': '20 Pak',
                'minimum': 'Batas min. 5 pak',
                'notes': 'Benih pakcoy untuk siklus tanam berikutnya.',
              });

    nameController = TextEditingController(text: data['name'] ?? '');

    quantityController = TextEditingController(
      text: _extractNumber(data['quantity'] ?? '20'),
    );

    minimumController = TextEditingController(
      text: _extractNumber(data['minimum'] ?? '5'),
    );

    notesController = TextEditingController(text: data['notes'] ?? '');

    selectedCategory = categories.contains(data['category'])
        ? data['category']!
        : categories.last;

    selectedUnit = _extractUnit(data['quantity'] ?? '');
  }

  String _extractNumber(String value) {
    final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(value);
    return match?.group(0) ?? '0';
  }

  String _extractUnit(String value) {
    final normalized = value.toLowerCase();

    if (normalized.contains('liter')) return 'Liter';
    if (normalized.contains('lembar')) return 'Lembar';
    if (normalized.contains('pak')) return 'Pak';

    return 'Pak';
  }

  double get quantityValue {
    return double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0;
  }

  double get minimumValue {
    return double.tryParse(minimumController.text.replaceAll(',', '.')) ?? 0;
  }

  bool get isBelowMinimum {
    return quantityValue <= minimumValue;
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    minimumController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Green header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: _buildHeader(context),
          ),

          // White form panel
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
              child: Column(
                children: [
                  // Scrollable form
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stock name
                          _buildTextField(
                            label: 'Nama stok',
                            controller: nameController,
                          ),

                          const SizedBox(height: 16),

                          // Category
                          _buildDropdownField(
                            label: 'Kategori',
                            value: selectedCategory,
                            items: categories,
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                selectedCategory = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Quantity and unit
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Jumlah tersedia',
                                  controller: quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Satuan',
                                  value: selectedUnit,
                                  items: units,
                                  onChanged: (value) {
                                    if (value == null) return;

                                    setState(() {
                                      selectedUnit = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Minimum stock
                          _buildTextField(
                            label: 'Batas minimum stok',
                            controller: minimumController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 16),

                          // Notes
                          _buildNotesField(),

                          const SizedBox(height: 16),

                          // Stock notification
                          _buildStockNotice(),
                        ],
                      ),
                    ),
                  ),

                  // Fixed bottom buttons
                  _buildBottomButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HEADER
  // =========================

  Widget _buildHeader(BuildContext context) {
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
            onTap: () {
              Navigator.pop(context);
            },
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

          Text(
            widget.isEdit ? 'Edit stok' : 'Tambah stok',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // TEXT FIELD
  // =========================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),

        const SizedBox(height: 8),

        SizedBox(
          height: 56,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: primaryColor,
            style: const TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: _inputDecoration(),
          ),
        ),
      ],
    );
  }

  // =========================
  // DROPDOWN FIELD
  // =========================

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),

        const SizedBox(height: 8),

        SizedBox(
          height: 56,
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: primaryColor,
              size: 23,
            ),
            decoration: _inputDecoration(),
            style: const TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // =========================
  // NOTES FIELD
  // =========================

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Catatan (opsional)'),

        const SizedBox(height: 8),

        SizedBox(
          height: 68,
          child: TextField(
            controller: notesController,
            maxLines: 2,
            textAlignVertical: TextAlignVertical.top,
            cursorColor: primaryColor,
            style: const TextStyle(color: textColor, fontSize: 14),
            decoration: _inputDecoration().copyWith(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // FIELD LABEL
  // =========================

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: textColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // =========================
  // INPUT DECORATION
  // =========================

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // =========================
  // STOCK NOTICE
  // =========================

  Widget _buildStockNotice() {
    final isLow = isBelowMinimum;
    final unit = selectedUnit.toLowerCase();

    final backgroundColor = isLow
        ? const Color(0xFFFFF5DF)
        : const Color(0xFFF1F5E9);

    final noticeColor = isLow ? const Color(0xFF8C5B16) : primaryColor;

    final title = isLow
        ? 'Stok berada di bawah batas minimum'
        : 'Notifikasi stok otomatis';

    final description = isLow
        ? 'Tersedia ${quantityController.text} $unit dari batas minimum '
              '${minimumController.text} $unit. Segera lakukan pengadaan.'
        : 'Peringatan muncul saat jumlah tersedia mencapai atau di '
              'bawah ${minimumController.text} $unit.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isLow ? Icons.info_outline_rounded : Icons.info_outline_rounded,
            color: noticeColor,
            size: 20,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isLow ? noticeColor : textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: TextStyle(
                    color: isLow ? noticeColor : const Color(0xFF70786B),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BOTTOM BUTTONS
  // =========================

  Widget _buildBottomButtons(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.isEdit
                              ? 'Fitur simpan perubahan masih dummy.'
                              : 'Fitur simpan stok masih dummy.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
