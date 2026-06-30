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
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (controller.transaksiHarian.isEmpty) {
          return const Card(
            child: SizedBox(
              height: 320,
              child: Center(
                child: Text("Belum ada data transaksi"),
              ),
            ),
          );
        }

        final spots = controller.transaksiHarian
            .map(
              (e) => FlSpot(
                e.hari.toDouble(),
                e.jumlah.toDouble(),
              ),
            )
            .toList();

        final maxY = controller.transaksiHarian
                .map((e) => e.jumlah)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() *
            1.2;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final padding = width < 700
                ? 12.0
                : width < 1000
                    ? 16.0
                    : 20.0;

            final chartHeight = width < 700
                ? 220.0
                : width < 1000
                    ? 260.0
                    : 320.0;

            final titleFont = width < 700
                ? 16.0
                : width < 1000
                    ? 18.0
                    : 20.0;

            final axisFont = width < 700
                ? 9.0
                : width < 1000
                    ? 11.0
                    : 12.0;

            final barWidth = width < 700
                ? 2.0
                : width < 1000
                    ? 3.0
                    : 4.0;

            final dotRadius = width < 700
                ? 2.5
                : width < 1000
                    ? 3.5
                    : 4.5;

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
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
                    SizedBox(height: padding),
                    SizedBox(
                      height: chartHeight,
                      child: LineChart(
                        LineChartData(
                          minX: spots.first.x,
                          maxX: spots.last.x,
                          minY: 0,
                          maxY: maxY,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                          ),
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
                                reservedSize: width < 700 ? 30 : 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: axisFont,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6),
                                    child: Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: axisFont,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData:
                                LineTouchTooltipData(
                              getTooltipItems:
                                  (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    "${spot.x.toInt()}\n${spot.y.toInt()} transaksi",
                                    const TextStyle(
                                      color: Colors.white,
                                    ),
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
                                getDotPainter:
                                    (spot, percent, bar, index) {
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
                                color: Colors.orange.withOpacity(0.15),
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
      },
    );
  }
}