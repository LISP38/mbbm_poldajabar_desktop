import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_controller.dart';

class PolaBelanjaChartWidget extends StatelessWidget {
  const PolaBelanjaChartWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Card(
            child: SizedBox(
              height: 340,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (controller.polaBelanja.isEmpty) {
          return const Card(
            child: SizedBox(
              height: 340,
              child: Center(
                child: Text(
                  "Belum ada data",
                ),
              ),
            ),
          );
        }

        final pertamax = controller.polaBelanja
            .map(
              (e) => FlSpot(
                e.hari.toDouble(),
                e.pertamax,
              ),
            )
            .toList();

        final dex = controller.polaBelanja
            .map(
              (e) => FlSpot(
                e.hari.toDouble(),
                e.dex,
              ),
            )
            .toList();

        double maxY = 0;

        for (final item in controller.polaBelanja) {
          if (item.pertamax > maxY) {
            maxY = item.pertamax;
          }

          if (item.dex > maxY) {
            maxY = item.dex;
          }
        }

        maxY *= 1.2;

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
                  "Pola Belanja BBM",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [

                    Container(
                      width: 14,
                      height: 14,
                      color: Colors.orange,
                    ),

                    const SizedBox(width: 6),

                    const Text("Pertamax"),

                    const SizedBox(width: 20),

                    Container(
                      width: 14,
                      height: 14,
                      color: Colors.blue,
                    ),

                    const SizedBox(width: 6),

                    const Text("Dexlite"),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 250,
                  child: LineChart(

                    LineChartData(

                      minX: controller
                          .polaBelanja
                          .first
                          .hari
                          .toDouble(),

                      maxX: controller
                          .polaBelanja
                          .last
                          .hari
                          .toDouble(),

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
                              (spots) {

                            return spots.map(
                              (spot) {

                                return LineTooltipItem(

                                  "Hari ${spot.x.toInt()}\n${spot.y.toStringAsFixed(1)} L",

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

                          spots: pertamax,

                          color: Colors.orange,

                          isCurved: true,

                          barWidth: 3,

                          dotData: FlDotData(
                            show: true,
                          ),

                          belowBarData:
                              BarAreaData(
                            show: true,
                            color: Colors.orange
                                .withValues(
                              alpha: 0.12,
                            ),
                          ),

                        ),

                        LineChartBarData(

                          spots: dex,

                          color: Colors.blue,

                          isCurved: true,

                          barWidth: 3,

                          dotData: FlDotData(
                            show: true,
                          ),

                          belowBarData:
                              BarAreaData(
                            show: true,
                            color: Colors.blue
                                .withValues(
                              alpha: 0.12,
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