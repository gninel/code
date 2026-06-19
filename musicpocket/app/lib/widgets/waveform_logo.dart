import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WaveformLogo extends StatelessWidget {
  final double size;

  const WaveformLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final barWidth = size * 0.12;
    final gap = size * 0.06;

    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(barWidth, size * 0.3, Colors.black),
          SizedBox(width: gap),
          _bar(barWidth, size * 0.6, Colors.black),
          SizedBox(width: gap),
          _bar(barWidth, size * 0.85, Colors.black),
          SizedBox(width: gap),
          _bar(barWidth, size * 0.18, AppColors.accent),
        ],
      ),
    );
  }

  Widget _bar(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width * 0.3),
      ),
    );
  }
}
