import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/kupon_provider.dart';
import '../../providers/dashboard_controller.dart';
import '../../providers/stok_opname_provider.dart';

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
    final percent = kapasitas == 0 ? 0.0 : (stok / kapasitas).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final circleSize = width * 0.38;

        final titleFont = width * 0.075;
        final stockFont = width * 0.105;
        final percentFont = width * 0.075;
        final capacityTitleFont = width * 0.055;
        final capacityFont = width * 0.07;

        return Container(
          padding: EdgeInsets.all(width * 0.08),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: circleSize,
                      height: circleSize,
                      child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 8,
                        color: color,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    Text(
                      "${(percent * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: percentFont,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: width * 0.08),

              Text(
                nama,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFont,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: width * 0.03),

              Text(
                "${stok.toStringAsFixed(0)} Liter",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: stockFont,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: width * 0.05),

              Divider(),

              SizedBox(height: width * 0.04),

              Text(
                "Stok Fisik Tangki",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: capacityTitleFont,
                ),
              ),

              SizedBox(height: width * 0.015),

              Text(
                "${kapasitas.toStringAsFixed(0)} Liter",
                style: TextStyle(
                  fontSize: capacityFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StokBBMWidget extends StatelessWidget {
  const StokBBMWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<DashboardController, KuponProvider, StokOpnameController>(
      builder: (context, controller, kuponProvider, laporanProvider, _) {
        if (controller.isLoading) {
          return const Card(
            child: SizedBox(
              height: 220,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (controller.stokBbm.isEmpty) {
          return const Card(
            child: SizedBox(
              height: 220,
              child: Center(
                child: Text("Belum ada data stok BBM"),
              ),
            ),
          );
        }

        final allKupons = kuponProvider.allKuponsForDropdown;

        debugPrint("Jumlah kupon = ${allKupons.length}");

        for (final k in allKupons) {
          debugPrint(
            "BBM=${k.jenisBbmId}, kuotaSisa=${k.kuotaSisa}, deleted=${k.isDeleted}",
          );
        }

        final stokSistemPx = allKupons
            .where((k) => k.jenisBbmId == 1 && k.isDeleted == 0)
            .fold(0.0, (sum, k) => sum + k.kuotaSisa);

        final stokSistemDex = allKupons
            .where((k) => k.jenisBbmId == 2 && k.isDeleted == 0)
            .fold(0.0, (sum, k) => sum + k.kuotaSisa);

        final lastStok = laporanProvider.lastStokOpname;
        final stokFisikPx = lastStok?.stokFisikPertamax ?? 0.0;
        final stokFisikDex = lastStok?.stokFisikDex ?? 0.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double itemWidth;

                if (constraints.maxWidth >= 1700) {
                  itemWidth = constraints.maxWidth / 5;
                } else if (constraints.maxWidth >= 1300) {
                  itemWidth = constraints.maxWidth / 4;
                } else if (constraints.maxWidth >= 900) {
                  itemWidth = constraints.maxWidth / 3;
                } else if (constraints.maxWidth >= 600) {
                  itemWidth = constraints.maxWidth / 2;
                } else {
                  itemWidth = constraints.maxWidth;
                }

                itemWidth = itemWidth.clamp(220.0, 320.0);

                return Column(
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
                        spacing: 24,
                        runSpacing: 24,                    
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: StokIndicator(
                              nama: "Pertamax",
                              stok: stokSistemPx,
                              kapasitas: stokFisikPx,
                              color: Colors.blue,
                            ),
                          ),

                          SizedBox(
                            width: itemWidth,
                            child: StokIndicator(
                              nama: "Pertamina Dex",
                              stok: stokSistemDex,
                              kapasitas: stokFisikDex,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}