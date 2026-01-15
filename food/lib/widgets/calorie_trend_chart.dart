import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';

/// 热量趋势折线图组件
class CalorieTrendChart extends StatelessWidget {
  final List<DailyCalorieData> data;
  final bool isWeekly;

  const CalorieTrendChart({
    Key? key,
    required this.data,
    this.isWeekly = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(AppLocalizations.of(context)!.get('no_data')),
        ),
      );
    }

    return SizedBox(
      height: 250, // 增加高度
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 10),
        child: LineChart(
          _createChartData(context),
        ),
      ),
    );
  }

  LineChartData _createChartData(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final maxY = _getMaxY();
    final yInterval = maxY / 5; 
    
    // 根据数据量计算X轴间隔
    double xInterval = 1;
    if (data.length > 14) {
      xInterval = (data.length / 5).ceilToDouble(); 
    } else if (data.length > 7) {
      xInterval = 2; 
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: xInterval,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index].label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10, 
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: yInterval,
            getTitlesWidget: (value, meta) {
              if (value == maxY) return const SizedBox.shrink(); 
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: data.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.calories.toDouble());
          }).toList(),
          isCurved: true,
          color: primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: primaryColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: primaryColor.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: primaryColor.withOpacity(0.8),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            final l10n = AppLocalizations.of(context)!;
            return touchedBarSpots.map((barSpot) {
              final index = barSpot.x.toInt();
              if (index >= 0 && index < data.length) {
                return LineTooltipItem(
                  '${data[index].label}\n${barSpot.y.toInt()} ${l10n.get('kcal')}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
    );
  }

  double _getMaxY() {
    if (data.isEmpty) return 1000;
    final maxCalories = data.map((e) => e.calories).fold<int>(0, (max, e) => e > max ? e : max);
    
    if (maxCalories == 0) return 500;
    // 减少顶部留白：只增加 10% 的缓冲，而不是之前的 20% + 取整
    // 并且向上取整到最近的 100，而不是 500，这样更紧凑
    return ((maxCalories * 1.1) / 100).ceil() * 100.0;
  }
}

/// 每日热量数据类
class DailyCalorieData {
  final String label; // 标签，如"周一"、"1日"等
  final int calories; // 热量值
  final DateTime date; // 日期

  DailyCalorieData({
    required this.label,
    required this.calories,
    required this.date,
  });
}
