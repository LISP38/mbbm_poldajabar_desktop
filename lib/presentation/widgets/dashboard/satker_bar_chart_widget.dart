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
            child: Text(
              "Belum ada data",
            ),
          ),
        ),
      );

    }

    final maxY =
        data
            .map(
              (e) => e.value,
            )
            .reduce(
              (a, b) => a > b ? a : b,
            ) *
        1.2;

    return Card(

      elevation: 1,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Padding(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(

              title,

              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),

            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(

              height: 260,

              child: BarChart(

                BarChartData(

                  maxY: maxY,

                  borderData:
                      FlBorderData(
                    show: false,
                  ),

                  gridData: FlGridData(
                    drawVerticalLine:
                        false,
                  ),

                  titlesData:
                      FlTitlesData(

                    topTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            false,
                      ),
                    ),

                    rightTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            false,
                      ),
                    ),

                    leftTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            true,
                      ),
                    ),

                    bottomTitles:
                        AxisTitles(

                      sideTitles:
                          SideTitles(

                        showTitles:
                            true,

                        reservedSize:
                            42,

                        getTitlesWidget:
                            (
                          value,
                          meta,
                        ) {

                          final index =
                              value.toInt();

                          if (index >=
                              data.length) {

                            return const SizedBox();

                          }

                          return Padding(

                            padding:
                                const EdgeInsets.only(
                              top: 8,
                            ),

                            child: RotatedBox(

                              quarterTurns: 1,

                              child: Text(

                                data[index]
                                    .satker,

                                style:
                                    const TextStyle(
                                  fontSize:
                                      10,
                                ),

                              ),

                            ),

                          );

                        },

                      ),

                    ),

                  ),

                  barTouchData:

                      BarTouchData(

                    touchTooltipData:

                        BarTouchTooltipData(

                      getTooltipItem:

                          (
                        group,
                        groupIndex,
                        rod,
                        rodIndex,
                      ) {

                        return BarTooltipItem(

                          "${data[group.x].satker}\n${rod.toY.toStringAsFixed(1)}",

                          const TextStyle(
                            color:
                                Colors.white,
                          ),

                        );

                      },

                    ),

                  ),

                  barGroups:

                      List.generate(

                    data.length,

                    (index) {

                      final item =
                          data[index];

                      return BarChartGroupData(

                        x: index,

                        barRods: [

                          BarChartRodData(

                            toY:
                                item.value,

                            width: 18,

                            color: color,

                            borderRadius:
                                BorderRadius.circular(
                              4,
                            ),

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

  }

}