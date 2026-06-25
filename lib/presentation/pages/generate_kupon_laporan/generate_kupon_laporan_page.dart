import 'package:flutter/material.dart';
import 'generate_kupon/generate_kupon_page.dart';
import 'generate_laporan/generate_laporan_page.dart';

class GenerateKuponLaporanPage extends StatelessWidget {
  final int selectedSubIndex;

  const GenerateKuponLaporanPage({super.key, required this.selectedSubIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selectedSubIndex == 0
            ? const GenerateKuponPage()
            : const GenerateLaporanPage(),
      ),
    );
  }
}
