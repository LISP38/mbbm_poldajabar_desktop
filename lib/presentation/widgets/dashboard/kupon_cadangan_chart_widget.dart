import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_controller.dart';
import 'satker_bar_chart_widget.dart';

class KuponCadanganChartWidget extends StatelessWidget {
  const KuponCadanganChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Card(
            child: SizedBox(
              height: 320,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return SatkerBarChartWidget(
          title: "Penggunaan Kupon Cadangan",
          color: Colors.red,
          data: controller.kuponCadangan,
        );
      },
    );
  }
}