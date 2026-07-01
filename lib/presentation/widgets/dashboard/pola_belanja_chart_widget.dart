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

        // Dynamically find all unique BBM names
        final Set<String> bbmNamesSet = {};
        for (var model in controller.polaBelanja) {
          bbmNamesSet.addAll(model.bbmValues.keys);
        }
        final bbmList = bbmNamesSet.toList()..sort();

        // Assign colors dynamically
        final List<Color> availableColors = [
          Colors.orange,
          Colors.blue,
          Colors.green,
          Colors.red,
          Colors.purple,
          Colors.teal,
        ];
        Color getColor(int index) => availableColors[index % availableColors.length];

        double maxY = 0;
        for (final item in controller.polaBelanja) {
          for (final val in item.bbmValues.values) {
            if (val > maxY) {
              maxY = val;
            }
          }
        }
        maxY *= 1.2;

        final List<LineChartBarData> lineBarsData = [];
        for (int i = 0; i < bbmList.length; i++) {
          final bbmName = bbmList[i];
          final color = getColor(i);

          final spots = controller.polaBelanja.asMap().entries.map((e) {
            final y = e.value.bbmValues[bbmName] ?? 0.0;
            return FlSpot(e.key.toDouble(), y);
          }).toList();

          lineBarsData.add(
            LineChartBarData(
              spots: spots,
              color: color,
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          );
        }

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
                  "Pola Belanja BBM",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: List.generate(bbmList.length, (index) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          color: getColor(index),
                        ),
                        const SizedBox(width: 6),
                        Text(bbmList[index]),
                      ],
                    );
                  }),
                ),
                
                const SizedBox(height: 20),
                
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (controller.polaBelanja.length - 1).toDouble(),
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
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= controller.polaBelanja.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  controller.polaBelanja[index].label,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final index = spot.x.toInt();
                              final label = index >= 0 && index < controller.polaBelanja.length
                                  ? controller.polaBelanja[index].label
                                  : "";

                              final bbmName = spot.barIndex >= 0 && spot.barIndex < bbmList.length 
                                  ? bbmList[spot.barIndex] 
                                  : "Unknown";
                              final prefix = spot == spots.first ? "$label\n" : "";

                              return LineTooltipItem(
                                "$prefix$bbmName: ${spot.y.toStringAsFixed(1)} L",
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: lineBarsData,
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