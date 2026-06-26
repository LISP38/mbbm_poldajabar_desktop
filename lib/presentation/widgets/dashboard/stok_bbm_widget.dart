import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_controller.dart';

class StokIndicator extends StatelessWidget {
  final String nama;
  final double stok;
  final double kapasitas;
  final Color color;

  const StokIndicator({
    super.key,
    required this.nama,
    required this.stok,
    required this.kapasitas,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = kapasitas == 0 ? 0 : stok / kapasitas;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [

          SizedBox(
            width: 95,
            height: 95,
            child: Stack(
              alignment: Alignment.center,
              children: [

                SizedBox(
                  width: 95,
                  height: 95,
                  child: CircularProgressIndicator(
                    value: double.parse(percent.toStringAsFixed(2)),
                    strokeWidth: 8,
                    color: color,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),

                Text(
                  "${(percent * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            nama,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "${stok.toStringAsFixed(0)} Liter",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Divider(),

          const SizedBox(height: 10),

          Text(
            "Kapasitas",
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "${kapasitas.toStringAsFixed(0)} Liter",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class StokBBMWidget extends StatelessWidget {
  const StokBBMWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Card(
            child: SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (controller.stokBbm.isEmpty) {
          return const Card(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text("Belum ada data stok BBM"),
              ),
            ),
          );
        }

        double totalKeseluruhan = controller.stokBbm.fold(
          0,
          (prev, e) => prev + e.totalLiter,
        );

        return Card(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Stok BBM per Jenis",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 32,
                    runSpacing: 32,
                    children: controller.stokBbm.map((item) {

                      final kapasitas = item.totalLiter * 2;

                      return StokIndicator(
                        nama: item.namaBbm,
                        stok: item.totalLiter,
                        kapasitas: kapasitas,
                        color: item.namaBbm.toLowerCase().contains("dex")
                            ? Colors.green
                            : Colors.blue,
                      );

                    }).toList(),
                  ),
                )
              ],
            ),
          ),
        ));
      },
    );
  }
}