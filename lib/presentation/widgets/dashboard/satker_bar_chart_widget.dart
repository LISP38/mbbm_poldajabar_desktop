import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/dashboard/satker_chart_model.dart';

class SatkerBarChartWidget extends StatelessWidget {
  final String title;
  final Color color;
  final List<SatkerChartModel> data;

  const SatkerBarChartWidget({
    super.key,
    required this.title,
    required this.color,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 320,
          child: Center(
            child: Text("Belum ada data"),
          ),
        ),
      );
    }

    final maxY =
        data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Responsive values
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

        final labelFont = width < 700
            ? 8.0
            : width < 1000
                ? 10.0
                : 12.0;

        final barWidth = width < 700
            ? 12.0
            : width < 1000
                ? 16.0
                : 20.0;

        final reservedSize = width < 700
            ? 32.0
            : width < 1000
                ? 42.0
                : 52.0;

        final padding = width < 700
            ? 12.0
            : width < 1000
                ? 16.0
                : 20.0;

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
                  title,
                  style: TextStyle(
                    fontSize: titleFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: padding),
                SizedBox(
                  height: chartHeight,
                  child: BarChart(
                    BarChartData(
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
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: labelFont),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: reservedSize,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();

                              if (index >= data.length) {
                                return const SizedBox();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: SizedBox(
                                    width: reservedSize,
                                    child: Text(
                                      data[index].satker,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: labelFont,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (
                            group,
                            groupIndex,
                            rod,
                            rodIndex,
                          ) {
                            return BarTooltipItem(
                              "${data[group.x].satker}\n${rod.toY.toStringAsFixed(1)}",
                              const TextStyle(
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: List.generate(
                        data.length,
                        (index) {
                          final item = data[index];

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: item.value,
                                width: barWidth,
                                color: color,
                                borderRadius: BorderRadius.circular(4),
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