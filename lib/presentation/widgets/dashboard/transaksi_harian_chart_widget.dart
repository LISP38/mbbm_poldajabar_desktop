import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_controller.dart';

class TransaksiHarianChartWidget extends StatelessWidget {
  const TransaksiHarianChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Card(
            child: SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (controller.transaksiHarian.isEmpty) {
          return const Card(
            child: SizedBox(
              height: 320,
              child: Center(child: Text("Belum ada data transaksi")),
            ),
          );
        }

        final spots = controller.transaksiHarian
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.jumlah.toDouble()))
            .toList();

        final maxY =
            controller.transaksiHarian
                .map((e) => e.jumlah)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() *
            1.2;

        final titleFont = 18.0;
        final axisFont = 11.0;
        final barWidth = 3.0;
        final dotRadius = 3.5;

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
                Text(
                  "Jumlah Transaksi Harian",
                  style: TextStyle(
                    fontSize: titleFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 42,
                ), // Matches legend height (8+14+20) from Pola Belanja
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      minX: spots.first.x,
                      maxX: spots.last.x,
                      minY: 0,
                      maxY: maxY,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: axisFont),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 ||
                                  index >= controller.transaksiHarian.length) {
                                return const SizedBox();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  controller.transaksiHarian[index].label,
                                  style: TextStyle(fontSize: axisFont),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final index = spot.x.toInt();
                              final label =
                                  index >= 0 &&
                                      index < controller.transaksiHarian.length
                                  ? controller.transaksiHarian[index].label
                                  : "";

                              return LineTooltipItem(
                                "$label\n${spot.y.toInt()} transaksi",
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: barWidth,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: dotRadius,
                                color: Colors.orange,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.orange.withAlpha(38),
                          ),
                        ),
                      ],
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
