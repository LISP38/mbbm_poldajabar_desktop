import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_controller.dart';

class DashboardFilterWidget extends StatelessWidget {
  const DashboardFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  "Periode : "
                  "${controller.tanggalMulai.day}/${controller.tanggalMulai.month}/${controller.tanggalMulai.year}"
                  " - "
                  "${controller.tanggalAkhir.day}/${controller.tanggalAkhir.month}/${controller.tanggalAkhir.year}",
                ),

                const Spacer(),

                ElevatedButton(
                  onPressed: () async {

                    final mulai = await showDatePicker(
                      context: context,
                      initialDate: controller.tanggalMulai,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (mulai == null) return;

                    final akhir = await showDatePicker(
                      context: context,
                      initialDate: controller.tanggalAkhir,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (akhir == null) return;

                    controller.updatePeriode(
                      mulai,
                      akhir,
                    );
                  },
                  child: const Text("Ubah Periode"),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}