import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_controller.dart';

class TransaksiHarianChartWidget extends StatelessWidget {
  const TransaksiHarianChartWidget({
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
                child: Text(
                  "Belum ada data transaksi",
                ),
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

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "Jumlah Transaksi Harian",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 260,
                  child: LineChart(

                    LineChartData(

                      minX: spots.first.x,
                      maxX: spots.last.x,

                      minY: 0,
                      maxY: maxY,

                      borderData: FlBorderData(
                        show: false,
                      ),

                      gridData: FlGridData(
                        drawVerticalLine: false,
                      ),

                      titlesData: FlTitlesData(

                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),

                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),

                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),

                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,

                            interval: 1,

                            getTitlesWidget:
                                (value, meta) {

                              return Padding(
                                padding:
                                    const EdgeInsets.only(
                                  top: 8,
                                ),
                                child: Text(
                                  value
                                      .toInt()
                                      .toString(),
                                  style:
                                      const TextStyle(
                                    fontSize: 11,
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

                            return touchedSpots.map(
                              (spot) {

                                return LineTooltipItem(

                                  "${spot.x.toInt()} \n${spot.y.toInt()} transaksi",

                                  const TextStyle(
                                    color: Colors.white,
                                  ),

                                );

                              },
                            ).toList();

                          },

                        ),

                      ),

                      lineBarsData: [

                        LineChartBarData(

                          spots: spots,

                          isCurved: true,

                          color: Colors.orange,

                          barWidth: 3,

                          isStrokeCapRound: true,

                          dotData: FlDotData(
                            show: true,
                          ),

                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.orange
                                .withOpacity(
                              0.15,
                            ),
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