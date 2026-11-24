import 'package:flutter/material.dart';

import 'kesehatan_unggah_foto_view.dart';
import '../widgets/bottom_navigation.dart';
import 'kesehatan_riwayat_deteksi_view.dart';

class KesehatanView extends StatelessWidget {
  const KesehatanView({super.key});

  static const Color primaryColor = Color(0xFF6E8649);
  static const Color textColor = Color(0xFF26351F);
  static const Color mutedColor = Color(0xFF70786B);
  static const Color softGreen = Color(0xFFF1F5E9);

  static const String lettuceImage =
      'https://images.unsplash.com/photo-1540420773420-3366772f4999'
      '?auto=format&fit=crop&w=500&q=80';

  final List<Map<String, String>> history = const [
    {
      'batch': 'Batch 04 • Selada',
      'date': '05 Nov 2026, 09.41',
      'status': 'Perlu perhatian',
    },
    {
      'batch': 'Batch 03 • Selada',
      'date': '04 Nov 2026, 08.15',
      'status': 'Normal',
    },
    {
      'batch': 'Batch 05 • Selada',
      'date': '03 Nov 2026, 10.20',
      'status': 'Normal',
    },
  ];

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Halaman ini akan kita hubungkan pada langkah berikutnya.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(color: primaryColor),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(
                  height: 112,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kesehatan selada',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Kenali kondisi tanaman, tangani lebih awal.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showComingSoon(context),
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroCard(),

                          const SizedBox(height: 12),

                          _buildStartButton(context),

                          const SizedBox(height: 10),

                          _buildPhotoHint(),

                          const SizedBox(height: 14),

                          _buildSummary(),

                          const SizedBox(height: 18),

                          _buildHistoryHeader(context),

                          const SizedBox(height: 8),

                          ...history.map(
                            (item) => _buildHistoryItem(context, item),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Periksa daun,\njaga hasil panen.',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 19,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Text(
                    'Foto daun dan batang untuk pemeriksaan visual tanaman.',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      height: 1.4,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 126,
            height: double.infinity,
            child: Image.network(
              lettuceImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFDCE8CF),
                  child: const Icon(
                    Icons.eco_outlined,
                    size: 48,
                    color: primaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KesehatanUnggahFotoView(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Mulai Deteksi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoHint() {
    return const Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: primaryColor),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'Siapkan foto daun dan batang dari tanaman yang sama.',
            style: TextStyle(
              color: mutedColor,
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            value: '3',
            label: 'Pemeriksaan',
            backgroundColor: softGreen,
            valueColor: textColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            value: '2',
            label: 'Normal',
            backgroundColor: softGreen,
            valueColor: textColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            value: '1',
            label: 'Perlu perhatian',
            backgroundColor: const Color(0xFFFFF5DF),
            valueColor: const Color(0xFF8C5B16),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String value,
    required String label,
    required Color backgroundColor,
    required Color valueColor,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor == textColor ? mutedColor : valueColor,
              fontSize: 9,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Pemeriksaan terakhir',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const KesehatanRiwayatDeteksiView(),
              ),
            );
          },
          child: const Text(
            'Semua Riwayat',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, String> item) {
    final bool needsAttention = item['status'] == 'Perlu perhatian';

    return InkWell(
      onTap: () => _showComingSoon(context),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                lettuceImage,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 48,
                    height: 48,
                    color: softGreen,
                    child: const Icon(Icons.eco_outlined, color: primaryColor),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['batch']!,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['date']!,
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['status']!,
                    style: TextStyle(
                      color: needsAttention
                          ? const Color(0xFF8C5B16)
                          : primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: mutedColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
