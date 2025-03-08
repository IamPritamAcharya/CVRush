import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:horz/pages/jobs/jobmodel.dart';

class JobSelectionGraph extends StatelessWidget {
  final Job job;
  const JobSelectionGraph({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color borderColor = isDarkMode ? Colors.white24 : Colors.black26;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color primaryColor = isDarkMode ? Colors.white : Colors.black;
    final Color inactiveColor =
        isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;

    final int percentile = job.percentile;
    final double selectionChance = job.chance.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Selection Probability",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),
          _buildSelectionPieChart(
              selectionChance, textColor, primaryColor, inactiveColor),
          const SizedBox(height: 24),
          _buildPercentileChart(percentile, textColor, primaryColor),
        ],
      ),
    );
  }

  /// **🎯 Selection Probability Pie Chart**
  Widget _buildSelectionPieChart(double selectionChance, Color textColor,
      Color primaryColor, Color inactiveColor) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: selectionChance,
                  color: primaryColor,
                  radius: 20,
                  title: '${selectionChance.toInt()}%',
                  titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                PieChartSectionData(
                  value: 100 - selectionChance,
                  color: inactiveColor,
                  radius: 14,
                  title: '',
                ),
              ],
              sectionsSpace: 0,
              centerSpaceRadius: 38,
            ),
          ),
          Text(
            "Chance",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  /// **📌 Percentile Chart with Square Grid**
  Widget _buildPercentileChart(
      int percentile, Color textColor, Color dotColor) {
    return Column(
      children: [
        Text(
          "Your Percentile",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 100,
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.4),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.4),
                  strokeWidth: 1,
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    FlSpot(percentile.toDouble(), percentile.toDouble())
                  ], // Only percentile dot
                  isCurved: false,
                  barWidth: 0, // Hide the line
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotSquarePainter(
                      size: 8,
                      color: dotColor,
                      strokeColor: Colors.grey,
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) =>
                        _getSideTitle(value, textColor),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) =>
                        _getBottomTitle(value, textColor),
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "$percentile percentile",
          style: TextStyle(fontSize: 14, color: textColor),
        ),
      ],
    );
  }

  /// **Y-Axis Labels (Percentile)**
  Widget _getSideTitle(double value, Color textColor) {
    if (value % 20 == 0) {
      return Text("${value.toInt()}%",
          style: TextStyle(fontSize: 12, color: textColor));
    }
    return Container();
  }

  /// **X-Axis Labels (Percentile Ranges)**
  Widget _getBottomTitle(double value, Color textColor) {
    if (value == 0 || value == 50 || value == 100) {
      return Text("${value.toInt()}",
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: textColor));
    }
    return Container();
  }
}
