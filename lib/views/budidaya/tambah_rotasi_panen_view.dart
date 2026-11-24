import 'package:flutter/material.dart';

class TambahRotasiPanenView extends StatefulWidget {
  const TambahRotasiPanenView({super.key});

  @override
  State<TambahRotasiPanenView> createState() => _TambahRotasiPanenViewState();
}

class _TambahRotasiPanenViewState extends State<TambahRotasiPanenView> {
  static const Color primaryColor = Color(0xFF6E8649);
  static const Color softColor = Color(0xFFF1F5E9);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color borderColor = Color(0xFFB7C4A5);

  final DateTime referenceDate = DateTime(2026, 11, 5);

  final TextEditingController holesController = TextEditingController(
    text: '12',
  );

  final TextEditingController noteController = TextEditingController(
    text:
        'Rotasi berikutnya setelah Batch 05. '
        'Panen seluruh lubang pada Meja D1.',
  );

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> availableBatches = [
    {
      'id': '03',
      'name': 'Batch 03',
      'plant': 'Selada',
      'sowingDate': DateTime(2026, 10, 5),
      'location': 'Meja A1',
      'holes': 24,
    },
    {
      'id': '04',
      'name': 'Batch 04',
      'plant': 'Selada hijau',
      'sowingDate': DateTime(2026, 10, 18),
      'location': 'Meja B1',
      'holes': 12,
    },
    {
      'id': '05',
      'name': 'Batch 05',
      'plant': 'Selada',
      'sowingDate': DateTime(2026, 10, 25),
      'location': 'Meja C1',
      'holes': 12,
    },
    {
      'id': '06',
      'name': 'Batch 06',
      'plant': 'Selada',
      'sowingDate': DateTime(2026, 11, 5),
      'location': 'Meja D1',
      'holes': 12,
    },
  ];

  late Map<String, dynamic> selectedBatch;

  late DateTime selectedHarvestDate;

  @override
  void initState() {
    super.initState();

    selectedBatch = availableBatches.last;

    selectedHarvestDate = DateTime(2026, 12, 10);
  }

  int get currentHss {
    final sowingDate = selectedBatch['sowingDate'] as DateTime;

    final difference = referenceDate.difference(sowingDate).inDays;

    return difference < 0 ? 0 : difference;
  }

  int get harvestHss {
    final sowingDate = selectedBatch['sowingDate'] as DateTime;

    return selectedHarvestDate.difference(sowingDate).inDays;
  }

  int get harvestHoles {
    return int.tryParse(holesController.text) ?? 0;
  }

  @override
  void dispose() {
    holesController.dispose();
    noteController.dispose();
    super.dispose();
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
            child: _buildHeader(context),
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
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBatchDropdown(),

                            const SizedBox(height: 16),

                            _buildBatchInformation(),

                            const SizedBox(height: 16),

                            _buildHarvestDateField(),

                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildHssField()),

                                const SizedBox(width: 14),

                                Expanded(child: _buildHolesField()),
                              ],
                            ),

                            const SizedBox(height: 16),

                            _buildNoteField(),

                            const SizedBox(height: 16),

                            _buildSchedulePreview(),
                          ],
                        ),
                      ),
                    ),

                    _buildBottomButtons(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

          const Text(
            'Tambah rotasi panen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor, width: 1),
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

  Widget _buildBatchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Pilih batch budidaya'),

        const SizedBox(height: 8),

        SizedBox(
          height: 56,
          child: DropdownButtonFormField<String>(
            initialValue: selectedBatch['id'] as String,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: primaryColor,
            ),
            decoration: _inputDecoration(),
            style: const TextStyle(color: textColor, fontSize: 14),
            items: availableBatches.map((batch) {
              final value = '${batch['name']} • ${batch['plant']}';

              return DropdownMenuItem<String>(
                value: batch['id'] as String,
                child: Text(value, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedBatch = availableBatches.firstWhere(
                  (batch) => batch['id'] == value,
                );

                holesController.text = selectedBatch['holes'].toString();

                selectedHarvestDate = (selectedBatch['sowingDate'] as DateTime)
                    .add(const Duration(days: 35));
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBatchInformation() {
    final sowingDate = selectedBatch['sowingDate'] as DateTime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semai ${_formatShortDate(sowingDate)}',
            style: const TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              Expanded(
                child: Text(
                  '${selectedBatch['location']} • '
                  '${selectedBatch['holes']} lubang tanam',
                  style: const TextStyle(color: mutedColor, fontSize: 11),
                ),
              ),

              Text(
                '$currentHss HSS hari ini',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tanggal rencana panen'),

        const SizedBox(height: 8),

        InkWell(
          onTap: _selectHarvestDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 56,
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
                  _formatLongDate(selectedHarvestDate),
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
      ],
    );
  }

  Future<void> _selectHarvestDate() async {
    final sowingDate = selectedBatch['sowingDate'] as DateTime;

    final result = await showDatePicker(
      context: context,
      initialDate: selectedHarvestDate,
      firstDate: sowingDate,
      lastDate: DateTime(2035, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedHarvestDate = result;
      });
    }
  }

  Widget _buildHssField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('HSS saat panen'),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: softColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$harvestHss HSS',
            style: const TextStyle(
              color: primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHolesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Lubang akan dipanen'),

        const SizedBox(height: 8),

        SizedBox(
          height: 56,
          child: TextFormField(
            controller: holesController,
            keyboardType: TextInputType.number,
            cursorColor: primaryColor,
            style: const TextStyle(color: textColor, fontSize: 14),
            decoration: _inputDecoration(),
            validator: (value) {
              final number = int.tryParse(value ?? '');
              final available = selectedBatch['holes'] as int;

              if (number == null || number <= 0) {
                return 'Jumlah tidak valid';
              }

              if (number > available) {
                return 'Melebihi stok lubang';
              }

              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Catatan rotasi (opsional)'),

        const SizedBox(height: 8),

        TextFormField(
          controller: noteController,
          maxLines: 2,
          cursorColor: primaryColor,
          style: const TextStyle(color: textColor, fontSize: 13, height: 1.4),
          decoration: _inputDecoration().copyWith(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_rounded, color: primaryColor, size: 19),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Jadwal panen siap disimpan',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '${_formatCompactDate(selectedHarvestDate)} • '
            '$harvestHoles lubang • ${selectedBatch['name']}',
            style: const TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
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
                  onPressed: _saveRotation,
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

  void _saveRotation() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (harvestHss <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal panen harus setelah tanggal semai.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jadwal rotasi panen masih menggunakan data dummy.'),
      ),
    );
  }

  String _formatShortDate(DateTime date) {
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

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String _formatLongDate(DateTime date) {
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

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String _formatCompactDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
