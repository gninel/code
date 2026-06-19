import 'package:flutter/material.dart';

class PlatformIcon extends StatelessWidget {
  final String platform;
  final double size;

  const PlatformIcon({super.key, required this.platform, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          _label,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String get _label {
    switch (platform) {
      case 'douyin':
        return '抖';
      case 'tiktok':
        return 'T';
      case 'bilibili':
        return 'B';
      case 'xiaohongshu':
        return '红';
      default:
        return '?';
    }
  }

  Color get _backgroundColor {
    switch (platform) {
      case 'douyin':
        return const Color(0xFF161823);
      case 'tiktok':
        return const Color(0xFF010101);
      case 'bilibili':
        return const Color(0xFFFB7299);
      case 'xiaohongshu':
        return const Color(0xFFFF2442);
      default:
        return Colors.grey;
    }
  }
}
