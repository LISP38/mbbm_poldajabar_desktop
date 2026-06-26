import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_controller.dart';

import 'satker_bar_chart_widget.dart';

class PenyerapanSatkerChartWidget
    extends StatelessWidget {

  const PenyerapanSatkerChartWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Consumer<DashboardController>(

      builder: (context, controller, _) {

        if (controller.isLoading) {

          return const Card(

            child: SizedBox(

              height: 320,

              child: Center(

                child:
                    CircularProgressIndicator(),

              ),

            ),

          );

        }

        return SatkerBarChartWidget(

          title:
              "Penyerapan BBM per Satker",

          color: Colors.orange,

          data:
              controller.penyerapanSatker,

        );

      },

    );

  }

}