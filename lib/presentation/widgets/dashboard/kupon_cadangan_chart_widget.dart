import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_controller.dart';

class KuponCadanganChartWidget extends StatelessWidget {
  const KuponCadanganChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Card(
            child: SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final data = controller.kuponCadangan;

        if (data.isEmpty) {
          return const Card(
            child: SizedBox(
              height: 300,
              child: Center(
                child: Text("Belum ada data"),
              ),
            ),
          );
        }

        final maxValue = data
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b) *
            1.2;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Penggunaan Kupon Cadangan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      maxY: maxValue,

                      borderData: FlBorderData(show: false),

                      gridData: FlGridData(
                        drawVerticalLine: false,
                      ),

                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),

                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),

                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();

                              if (index >= data.length) {
                                return const SizedBox();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  data[index].satker,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      barGroups: List.generate(
                        data.length,
                        (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: data[index].value,
                                width: 18,
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.red,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}